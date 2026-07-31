extends SceneTree

const CAMERA_DIRECTOR_SCRIPT = preload("res://scripts/integrated_camera_director.gd")

var failures: Array[String] = []


class FixtureActor extends Node3D:
	var alive := true
	var health := 250
	var damage_events := 0
	var reward_events := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var previous_scene := current_scene
	var host := Node3D.new()
	host.name = "IntegratedCameraDirectorTestHost"
	root.add_child(host)
	current_scene = host
	await process_frame
	await _test_default_and_swarm_hysteresis(host)
	await _test_one_shot_reveal_and_exact_restoration(host)
	await _test_interruption_and_replay_reset(host)
	await _test_teardown_and_gameplay_equivalence(host)
	_test_live_route_and_authority_boundaries()
	current_scene = previous_scene
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Integrated production camera director")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _test_default_and_swarm_hysteresis(host: Node3D) -> void:
	var fixture: Dictionary = await _spawn_fixture(host)
	var camera: Camera3D = fixture["camera"]
	var player: FixtureActor = fixture["player"]
	var director: IntegratedCameraDirector = fixture["director"]
	director.update(1.0, player, 0, "courtyard", null)
	_expect(director.state == IntegratedCameraDirector.STATE_DEFAULT_GAMEPLAY, "The live route must begin in the default gameplay camera state.")
	_expect(camera.global_position.is_equal_approx(Vector3(0.0, IntegratedCameraDirector.DEFAULT_CAMERA_HEIGHT, IntegratedCameraDirector.DEFAULT_CAMERA_DISTANCE)), "Default framing must settle at the documented lower and closer gameplay pose.")
	_expect(is_equal_approx(camera.fov, IntegratedCameraDirector.DEFAULT_FOV), "Default framing must retain its documented field of view.")
	director.update(0.02, player, IntegratedCameraDirector.SWARM_ENTER_ENEMY_COUNT, "courtyard", null)
	_expect(director.state == IntegratedCameraDirector.STATE_SWARM_COMBAT, "Authored encounter pressure at the enter threshold must expand into swarm combat.")
	director.update(1.0, player, IntegratedCameraDirector.SWARM_ENTER_ENEMY_COUNT, "courtyard", null)
	_expect(camera.global_position.is_equal_approx(Vector3(0.0, IntegratedCameraDirector.SWARM_CAMERA_HEIGHT, IntegratedCameraDirector.SWARM_CAMERA_DISTANCE)), "Swarm combat must smoothly settle into the documented raised, pulled-back pose.")
	_expect(is_equal_approx(camera.fov, IntegratedCameraDirector.SWARM_FOV), "Swarm combat must use its documented field of view.")
	director.update(0.60, player, IntegratedCameraDirector.SWARM_EXIT_ENEMY_COUNT, "courtyard", null)
	_expect(director.state == IntegratedCameraDirector.STATE_SWARM_COMBAT, "The exit hold must prevent a low-pressure frame from snapping the swarm camera back.")
	director.update(0.61, player, IntegratedCameraDirector.SWARM_EXIT_ENEMY_COUNT, "courtyard", null)
	_expect(director.state == IntegratedCameraDirector.STATE_DEFAULT_GAMEPLAY, "Sustained low pressure must return deterministically to default gameplay framing.")
	await _cleanup_fixture(fixture)


func _test_one_shot_reveal_and_exact_restoration(host: Node3D) -> void:
	var fixture: Dictionary = await _spawn_fixture(host)
	var camera: Camera3D = fixture["camera"]
	var player: FixtureActor = fixture["player"]
	var boss: FixtureActor = fixture["boss"]
	var director: IntegratedCameraDirector = fixture["director"]
	director.update(1.0, player, 0, "boss", null)
	var pre_reveal_transform := camera.global_transform
	var pre_reveal_fov := camera.fov
	_expect(director.request_hollow_king_reveal(player, boss), "The authored Hollow King route must accept its first valid reveal request.")
	_expect(not director.request_hollow_king_reveal(player, boss), "A duplicate Hollow King introduction request must be rejected.")
	director.update(0.24, player, 0, "boss", boss)
	_expect(director.state == IntegratedCameraDirector.STATE_BOSS_REVEAL, "The accepted request must temporarily enter Boss Reveal.")
	_expect(not camera.global_transform.is_equal_approx(pre_reveal_transform) and camera.fov < pre_reveal_fov, "Boss Reveal must visibly own only the temporary camera composition.")
	var reveal_forward := -camera.global_transform.basis.z
	_expect(reveal_forward.dot(player.global_position - camera.global_position) > 0.0 and reveal_forward.dot(boss.global_position - camera.global_position) > 0.0, "Boss Reveal must frame both the live player and Hollow King in front of the camera.")
	director.update(2.0, player, 0, "boss", boss)
	_expect(director.state == IntegratedCameraDirector.STATE_DEFAULT_GAMEPLAY, "A completed reveal must return to the captured gameplay camera state.")
	_expect(camera.global_transform.is_equal_approx(pre_reveal_transform) and is_equal_approx(camera.fov, pre_reveal_fov), "Boss Reveal completion must restore the exact captured transform and field of view without drift.")
	await _cleanup_fixture(fixture)


func _test_interruption_and_replay_reset(host: Node3D) -> void:
	var boss_fixture: Dictionary = await _spawn_fixture(host)
	var boss_camera: Camera3D = boss_fixture["camera"]
	var boss_player: FixtureActor = boss_fixture["player"]
	var boss: FixtureActor = boss_fixture["boss"]
	var boss_director: IntegratedCameraDirector = boss_fixture["director"]
	boss_director.update(1.0, boss_player, 0, "boss", null)
	var boss_pre_reveal := boss_camera.global_transform
	_expect(boss_director.request_hollow_king_reveal(boss_player, boss), "A fresh fixture must accept the Hollow King reveal.")
	boss_director.update(0.18, boss_player, 0, "boss", boss)
	boss.alive = false
	boss_director.update(0.02, boss_player, 0, "boss", boss)
	_expect(boss_camera.global_transform.is_equal_approx(boss_pre_reveal), "Boss death during reveal must restore the captured gameplay camera immediately.")
	await _cleanup_fixture(boss_fixture)

	var player_fixture: Dictionary = await _spawn_fixture(host)
	var player_camera: Camera3D = player_fixture["camera"]
	var player: FixtureActor = player_fixture["player"]
	var player_boss: FixtureActor = player_fixture["boss"]
	var player_director: IntegratedCameraDirector = player_fixture["director"]
	player_director.update(1.0, player, 0, "boss", null)
	var player_pre_reveal := player_camera.global_transform
	_expect(player_director.request_hollow_king_reveal(player, player_boss), "The player-death fixture must accept its first reveal.")
	player_director.update(0.18, player, 0, "boss", player_boss)
	player.alive = false
	player_director.update(0.02, player, 0, "boss", player_boss)
	_expect(player_camera.global_transform.is_equal_approx(player_pre_reveal), "Player death during reveal must restore the captured gameplay camera immediately.")
	player.alive = true
	player_director.reset_for_replay()
	_expect(player_director.state == IntegratedCameraDirector.STATE_DEFAULT_GAMEPLAY and not bool(player_director.snapshot()["reveal_consumed"]), "Replay/reset must leave a clean default state that can accept the next authored reveal.")
	_expect(player_director.request_hollow_king_reveal(player, player_boss), "Replay/reset must deterministically re-arm exactly one future reveal.")
	player_director.restore_immediately()
	await _cleanup_fixture(player_fixture)


func _test_teardown_and_gameplay_equivalence(host: Node3D) -> void:
	var fixture: Dictionary = await _spawn_fixture(host)
	var world: Node3D = fixture["world"]
	var camera: Camera3D = fixture["camera"]
	var player: FixtureActor = fixture["player"]
	var boss: FixtureActor = fixture["boss"]
	var director: IntegratedCameraDirector = fixture["director"]
	var gameplay_before := _gameplay_snapshot(player, boss)
	director.update(1.0, player, IntegratedCameraDirector.SWARM_ENTER_ENEMY_COUNT, "courtyard", null)
	var pre_reveal := camera.global_transform
	director.request_hollow_king_reveal(player, boss)
	director.update(0.20, player, 0, "boss", boss)
	_expect(_gameplay_snapshot(player, boss) == gameplay_before, "All camera states, including headless/no-controller use, must be gameplay-equivalent and only mutate presentation transforms.")
	director.queue_free()
	await process_frame
	_expect(camera.global_transform.is_equal_approx(pre_reveal), "Director teardown during an active reveal must restore its captured camera state before freeing.")
	_expect(world.get_node_or_null("IntegratedCameraDirector") == null, "Scene teardown must leave no stale camera presentation helper node.")
	await _cleanup_fixture(fixture)


func _test_live_route_and_authority_boundaries() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var multiclass_source := FileAccess.get_file_as_string("res://scripts/multiclass_main.gd")
	var gameplay_scene := FileAccess.get_file_as_string("res://gameplay.tscn")
	var full_stack_source := FileAccess.get_file_as_string("res://scripts/full_stack_controller_main.gd")
	var director_source := FileAccess.get_file_as_string("res://scripts/integrated_camera_director.gd")
	_expect(main_source.contains("_install_camera_director()") and main_source.contains("camera_director.update(delta, player, enemies_alive, game_state, boss)"), "The director must run from the real main gameplay route using stable encounter facts.")
	_expect(main_source.contains("camera_director.request_hollow_king_reveal(player, boss)") and main_source.contains("func _on_boss_died") and main_source.contains("_restore_camera_presentation()"), "The real Hollow King spawn, death, reset, and teardown paths must restore the camera presentation deterministically.")
	_expect(multiclass_source.contains("func _on_player_died()") and multiclass_source.contains("_restore_camera_presentation()"), "The active multiclass player-death override must restore the camera presentation.")
	_expect(gameplay_scene.contains("full_stack_controller_main.gd") and full_stack_source.contains("extends \"res://scripts/multiclass_main.gd\""), "The tested integration must remain on the real full-stack playable route rather than a camera-only sandbox.")
	_expect(not director_source.contains("Input.") and not director_source.contains("take_damage(") and not director_source.contains("add_experience(") and not director_source.contains("_spawn_item_drop") and not director_source.contains("Persistence") and not director_source.contains("move_and_slide("), "The camera director must not own input, damage, rewards, persistence, or movement.")
	_expect(not director_source.contains("CollisionObject3D") and not director_source.contains("CollisionShape3D"), "The camera director must not introduce gameplay collision descendants.")
	_expect(director_source.contains("SWARM_ENTER_ENEMY_COUNT") and director_source.contains("SWARM_EXIT_ENEMY_COUNT") and director_source.contains("SWARM_EXIT_HOLD_SECONDS"), "Swarm combat must retain explicit authored pressure thresholds and hysteresis tuning values.")


func _spawn_fixture(host: Node3D) -> Dictionary:
	var world := Node3D.new()
	world.name = "IntegratedCameraDirectorFixtureWorld"
	host.add_child(world)
	var player := FixtureActor.new()
	player.name = "VoidbringerFixture"
	world.add_child(player)
	var boss := FixtureActor.new()
	boss.name = "HollowKingFixture"
	world.add_child(boss)
	boss.global_position = Vector3(0.0, 0.0, -20.0)
	var camera := Camera3D.new()
	camera.name = "ProductionCameraFixture"
	world.add_child(camera)
	camera.global_position = Vector3(-2.0, 17.8, 16.2)
	camera.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)
	camera.fov = 50.0
	var director: IntegratedCameraDirector = CAMERA_DIRECTOR_SCRIPT.new()
	director.name = "IntegratedCameraDirector"
	world.add_child(director)
	director.configure(camera)
	await process_frame
	return {"world": world, "camera": camera, "player": player, "boss": boss, "director": director}


func _cleanup_fixture(fixture: Dictionary) -> void:
	var world: Node = fixture.get("world") as Node
	if is_instance_valid(world):
		world.queue_free()
	await process_frame


func _gameplay_snapshot(player: FixtureActor, boss: FixtureActor) -> Dictionary:
	return {
		"player_position": player.global_position,
		"player_alive": player.alive,
		"player_health": player.health,
		"player_damage_events": player.damage_events,
		"player_reward_events": player.reward_events,
		"boss_position": boss.global_position,
		"boss_alive": boss.alive,
		"boss_health": boss.health,
		"boss_damage_events": boss.damage_events,
		"boss_reward_events": boss.reward_events,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
