extends SceneTree

const SANDBOX_SCENE = preload("res://scenes/voidbringer_foundation_sandbox.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	host.name = "VoidbringerPolishedImpactTestHost"
	root.add_child(host)
	await _test_authoritative_contact_and_interruption(host)
	await _test_rejected_dead_and_invalid_contacts(host)
	await _test_replay_reset_and_teardown(host)
	await _test_presentation_modes_and_no_controller(host)
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer polished impact interaction")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_authoritative_contact_and_interruption(host: Node3D) -> void:
	var sandbox := _make_sandbox(host, VoidbringerPolishedImpactPresentation.MODE_ENABLED)
	var target := sandbox.enemy_fixture
	var camera_start := sandbox.sandbox_camera.position
	var visual_start := _visual_snapshot(target.visual_root)

	_expect(sandbox.simulate_command(&"fire_null_shard"), "Accepted Null Shard should enter the polished impact loop")
	var cast_snapshot: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
	_expect(int(cast_snapshot.get("anticipation_cues", 0)) == 1, "Accepted cast should create one readable anticipation cue")
	_expect(int(cast_snapshot.get("transactions", 0)) == 0, "Cast anticipation must not fabricate an impact transaction")

	sandbox.simulate_seconds(0.40, 0.01)
	var resolved := sandbox.debug_snapshot()
	var impact: Dictionary = resolved.get("last_impact", {})
	var presentation: Dictionary = resolved.get("impact_presentation", {})
	_expect(int((resolved.get("enemy", {}) as Dictionary).get("hit_calls", 0)) == 1, "Accepted impact must call target damage exactly once")
	_expect(int((resolved.get("enemy", {}) as Dictionary).get("health", 0)) == 82, "Polished presentation must preserve the approved Null Shard damage")
	_expect(int(presentation.get("transactions", 0)) == 1, "One accepted authoritative hit should create one presentation transaction")
	_expect(bool(presentation.get("last_critical", true)) == bool(impact.get("critical", false)), "Presentation must propagate the committed critical result without rerolling")
	_expect(int(presentation.get("audio_events", 0)) == 1, "Enabled presentation should emit one presentation-only impact audio event")
	_expect(bool(presentation.get("camera_impulse_active", false)), "Enabled impact should use one bounded camera impulse")
	_expect(
		target.visual_root.position != visual_start.get("position", Vector3.ZERO)
			or target.visual_root.scale != visual_start.get("scale", Vector3.ONE),
		"Accepted impact should provide a directional decorative target response"
	)

	var health_before_duplicate := target.health
	_expect(
		not sandbox.impact_presentation.present_accepted_null_shard(sandbox.controller.last_impact_result, target),
		"The same authoritative result must not create a second presentation transaction"
	)
	_expect(target.health == health_before_duplicate, "Duplicate presentation observation must not apply damage")
	_expect(int((sandbox.debug_snapshot().get("impact_presentation", {}) as Dictionary).get("transactions", 0)) == 1, "Duplicate observation must leave transaction count at one")

	sandbox.impact_presentation.clear()
	await process_frame
	_expect(sandbox.sandbox_camera.position == camera_start, "Interrupted impact must restore the sandbox camera exactly")
	_expect(_visual_snapshot(target.visual_root) == visual_start, "Interrupted impact must restore target presentation state exactly")
	_expect(_count_named(sandbox, "NullShardContactFlash") == 0, "Interrupted impact must leave no contact flash nodes")
	_expect(_count_named(sandbox, "NullShardCastAnticipation") == 0, "Interrupted impact must leave no anticipation nodes")

	sandbox.simulate_command(&"clear")
	sandbox.combat_projection.configure({"power": 0.0, "critical_chance": 1.0})
	_expect(sandbox.simulate_command(&"fire_null_shard"), "Critical-propagation setup should commit one Null Shard")
	sandbox.simulate_seconds(0.40, 0.01)
	var critical_impact: Dictionary = sandbox.debug_snapshot().get("last_impact", {})
	var critical_presentation: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
	_expect(bool(critical_impact.get("critical", false)), "Critical setup should receive the projection's one committed critical result")
	_expect(bool(critical_presentation.get("last_critical", false)), "Presentation should display the committed critical state without a second roll")
	_expect(int((sandbox.debug_snapshot().get("enemy", {}) as Dictionary).get("hit_calls", 0)) == 1, "Critical presentation must still apply target damage exactly once")


func _test_rejected_dead_and_invalid_contacts(host: Node3D) -> void:
	var sandbox := _make_sandbox(host, VoidbringerPolishedImpactPresentation.MODE_ENABLED)
	var baseline: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
	var rejected := sandbox.controller.execute_null_shard_command(
		sandbox.null_shard_definition,
		sandbox.player_origin,
		Vector3.ZERO,
		sandbox.combat_projection,
		{},
		sandbox.equipped_ability_ids
	)
	_expect(not bool(rejected.get("success", true)), "Invalid-direction Null Shard command must reject before spawning a projectile")
	_expect(_presentation_counts(sandbox) == _presentation_counts_from_snapshot(baseline), "Rejected command must create no presentation transaction or cue")

	var zero_damage_result := VoidbringerImpactResult.new({
		"ability_id": VoidbringerAbilityCatalog.NULL_SHARD,
		"cast_id": &"vb.cast.invalid",
		"damage_applied": 0,
		"critical": true,
	})
	_expect(
		not sandbox.impact_presentation.present_accepted_null_shard(zero_damage_result, sandbox.enemy_fixture),
		"Invalid zero-damage contact must not create presentation"
	)

	sandbox.enemy_fixture.take_damage(100)
	var health_after_death := sandbox.enemy_fixture.health
	_expect(not sandbox.simulate_command(&"fire_null_shard"), "Dead target must reject the sandbox Null Shard route")
	_expect(sandbox.enemy_fixture.health == health_after_death, "Dead-contact rejection must not mutate health")
	_expect(_presentation_counts(sandbox) == _presentation_counts_from_snapshot(baseline), "Dead contact must not create a presentation transaction")


func _test_replay_reset_and_teardown(host: Node3D) -> void:
	var sandbox := _make_sandbox(host, VoidbringerPolishedImpactPresentation.MODE_ENABLED)
	_expect(sandbox.simulate_command(&"fire_null_shard"), "Replay setup should fire one Null Shard")
	sandbox.simulate_seconds(0.40, 0.01)
	_expect(sandbox.simulate_command(&"replay_impact"), "Replay command should reset then fire the same interaction")
	var replay := sandbox.debug_snapshot()
	var replay_presentation: Dictionary = replay.get("impact_presentation", {})
	_expect(int((replay.get("enemy", {}) as Dictionary).get("health", 0)) == 100, "Replay should restore target health before the new contact")
	_expect((replay.get("null_shards", []) as Array).size() == 1, "Replay should leave exactly one fresh gameplay projectile")
	_expect(int(replay_presentation.get("transactions", -1)) == 0, "Replay reset should clear completed presentation transactions")
	_expect(int(replay_presentation.get("anticipation_cues", 0)) == 1, "Replay should start one fresh cast anticipation cue")
	_expect(int(replay_presentation.get("contact_cues", 0)) == 0, "Replay should not retain the prior contact flash")
	_expect(bool(replay_presentation.get("camera_restored", false)), "Replay should restore camera before the next contact")

	sandbox.simulate_seconds(0.85, 0.01)
	await process_frame
	var settled: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
	_expect(int(settled.get("anticipation_cues", -1)) == 0 and int(settled.get("contact_cues", -1)) == 0, "Completed interaction should deterministically clean transient cues")
	_expect(not bool(settled.get("camera_impulse_active", true)), "Completed interaction should restore the bounded camera hook")
	_expect(not bool(settled.get("target_response_active", true)), "Completed interaction should restore target presentation state")
	_expect(_count_named(sandbox, "NullShardContactFlash") == 0, "Completed interaction should leave no stale contact nodes")
	_expect(_count_named(sandbox, "NullShardCastAnticipation") == 0, "Completed interaction should leave no stale cast nodes")

	var host_child_count_before_teardown := host.get_child_count()
	sandbox.queue_free()
	await process_frame
	_expect(not is_instance_valid(sandbox), "Scene teardown should release the sandbox and all presentation owners")
	_expect(host.get_child_count() == host_child_count_before_teardown - 1, "Scene teardown should leave no detached sandbox presentation nodes")


func _test_presentation_modes_and_no_controller(host: Node3D) -> void:
	var gameplay_snapshots: Array[Dictionary] = []
	for presentation_mode: StringName in [
		VoidbringerPolishedImpactPresentation.MODE_ENABLED,
		VoidbringerPolishedImpactPresentation.MODE_REDUCED,
		VoidbringerPolishedImpactPresentation.MODE_DISABLED,
	]:
		var sandbox := _make_sandbox(host, presentation_mode)
		_expect(sandbox.simulate_command(&"fire_null_shard"), "%s presentation mode should preserve a valid Null Shard cast" % presentation_mode)
		sandbox.simulate_seconds(0.40, 0.01)
		var snapshot := sandbox.debug_snapshot()
		gameplay_snapshots.append({
			"health": int((snapshot.get("enemy", {}) as Dictionary).get("health", 0)),
			"hits": int((snapshot.get("enemy", {}) as Dictionary).get("hit_calls", 0)),
			"damage": int((snapshot.get("last_impact", {}) as Dictionary).get("damage", 0)),
			"critical": bool((snapshot.get("last_impact", {}) as Dictionary).get("critical", false)),
		})
		if presentation_mode == VoidbringerPolishedImpactPresentation.MODE_DISABLED:
			_expect(int((snapshot.get("impact_presentation", {}) as Dictionary).get("transactions", 0)) == 0, "Disabled presentation should create no presentation transaction")
		else:
			_expect(int((snapshot.get("impact_presentation", {}) as Dictionary).get("transactions", 0)) == 1, "%s presentation should observe the one accepted hit" % presentation_mode)
		if Input.get_connected_joypads().is_empty() and presentation_mode == VoidbringerPolishedImpactPresentation.MODE_ENABLED:
			_expect(int((snapshot.get("impact_presentation", {}) as Dictionary).get("haptic_events", -1)) == 0, "No-controller path must safely skip haptics")

	_expect(gameplay_snapshots[0] == gameplay_snapshots[1] and gameplay_snapshots[1] == gameplay_snapshots[2], "Enabled, reduced, and disabled presentation paths must remain gameplay-equivalent")


func _make_sandbox(host: Node3D, presentation_mode: StringName) -> VoidbringerFoundationSandbox:
	var sandbox: VoidbringerFoundationSandbox = SANDBOX_SCENE.instantiate()
	host.add_child(sandbox)
	sandbox.set_process(false)
	sandbox.set_impact_presentation_mode(presentation_mode)
	return sandbox


func _presentation_counts(sandbox: VoidbringerFoundationSandbox) -> Dictionary:
	return _presentation_counts_from_snapshot(sandbox.debug_snapshot().get("impact_presentation", {}))


func _presentation_counts_from_snapshot(snapshot: Dictionary) -> Dictionary:
	return {
		"transactions": int(snapshot.get("transactions", 0)),
		"anticipation": int(snapshot.get("anticipation_cues", 0)),
		"contact": int(snapshot.get("contact_cues", 0)),
	}


func _visual_snapshot(visual_root: Node3D) -> Dictionary:
	return {
		"position": visual_root.position,
		"scale": visual_root.scale,
		"rotation": visual_root.rotation_degrees,
	}


func _count_named(node: Node, target_name: String) -> int:
	var count := 1 if node.name == target_name else 0
	for child: Node in node.get_children():
		count += _count_named(child, target_name)
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
