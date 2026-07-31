extends SceneTree

const SANDBOX_SCENE = preload("res://scenes/voidbringer_foundation_sandbox.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Node3D.new()
	host.name = "VoidbringerSpectacleImpactTestHost"
	root.add_child(host)
	await _test_authoritative_spectacle_and_critical_profile(host)
	await _test_rejected_dead_and_duplicate_results(host)
	await _test_reset_replay_and_teardown(host)
	await _test_presentation_modes_and_headless_safety(host)
	host.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer spectacle impact presentation")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _test_authoritative_spectacle_and_critical_profile(host: Node3D) -> void:
	var sandbox := _make_sandbox(host, VoidbringerPolishedImpactPresentation.MODE_ENABLED)
	var target := sandbox.enemy_fixture
	var camera_start := sandbox.sandbox_camera.position
	var visual_start := _visual_snapshot(target.visual_root)

	_expect(sandbox.simulate_command(&"fire_null_shard"), "Accepted Null Shard should enter the spectacle loop")
	sandbox.simulate_seconds(0.40, 0.01)
	var resolved := sandbox.debug_snapshot()
	var impact: Dictionary = resolved.get("last_impact", {})
	var presentation: Dictionary = resolved.get("impact_presentation", {})
	var normal_profile: Dictionary = presentation.get("last_profile", {})
	_expect(int((resolved.get("enemy", {}) as Dictionary).get("hit_calls", 0)) == 1, "Spectacle observation must not double-apply target damage")
	_expect(int((resolved.get("enemy", {}) as Dictionary).get("health", 0)) == 82, "Spectacle must preserve the approved Null Shard damage")
	_expect(int(presentation.get("transactions", 0)) == 1, "One accepted authoritative hit must create one spectacle transaction")
	_expect(bool(presentation.get("last_critical", true)) == bool(impact.get("critical", false)), "Spectacle must propagate the committed critical fact without rerolling")
	_expect(not bool(normal_profile.get("critical", true)), "Normal impact must select only the normal visual profile")
	_expect(int(presentation.get("shock_rings", 0)) == 1, "Accepted impact must create one violet-white singularity shock ring")
	_expect(int(presentation.get("inward_motes", 0)) == VoidbringerPolishedImpactPresentation.ENABLED_MOTE_COUNT, "Enabled impact must create the fixed deterministic mote count")
	_expect(int(presentation.get("residue_nodes", 0)) == 1, "Accepted impact must create one temporary ground residue")
	_expect(int(presentation.get("light_pulses", 0)) == 1, "Enabled impact must create one bounded light pulse")
	_expect(_counts_within_maxima(presentation), "Active spectacle objects must stay within their declared deterministic maxima")
	_expect(_count_named(sandbox, "NullShardSingularityShockRing") == 1, "The impact must read through a shock ring rather than an expanding sphere")
	_expect(_count_named(sandbox, "NullShardInwardMote_00") == 1, "The impact must include deterministic inward debris motes")
	_expect(_count_named(sandbox, "NullShardGroundResidue") == 1, "The impact must include a temporary visual ground residue")
	_expect(_count_named(sandbox, "NullShardImpactLightPulse") == 1, "The impact must include one optional visual light pulse")
	_expect(
		target.visual_root.scale.y < (visual_start.get("scale", Vector3.ONE) as Vector3).y,
		"Target presentation must compress toward the singularity without moving gameplay state"
	)
	_expect(
		target.visual_root.position != visual_start.get("position", Vector3.ZERO)
			or target.visual_root.scale != visual_start.get("scale", Vector3.ONE),
		"Accepted impact must provide a visible reversible target response"
	)
	_expect(bool(presentation.get("camera_impulse_active", false)), "Enabled impact must use one bounded camera hook")
	_expect(int(presentation.get("audio_events", 0)) == 1, "Enabled impact must emit one presentation-only audio event")

	var health_before_duplicate := target.health
	_expect(
		not sandbox.impact_presentation.present_accepted_null_shard(sandbox.controller.last_impact_result, target),
		"A duplicate committed result must not create a second spectacle transaction"
	)
	_expect(target.health == health_before_duplicate, "Duplicate spectacle observation must not mutate target health")
	_expect(int((sandbox.debug_snapshot().get("impact_presentation", {}) as Dictionary).get("transactions", 0)) == 1, "Duplicate result must leave the one transaction intact")

	sandbox.simulate_command(&"clear")
	sandbox.combat_projection.configure({"power": 0.0, "critical_chance": 1.0})
	_expect(sandbox.simulate_command(&"fire_null_shard"), "Critical setup should commit one Null Shard")
	sandbox.simulate_seconds(0.40, 0.01)
	var critical_impact: Dictionary = sandbox.debug_snapshot().get("last_impact", {})
	var critical_presentation: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
	var critical_profile: Dictionary = critical_presentation.get("last_profile", {})
	_expect(bool(critical_impact.get("critical", false)), "Critical setup must use the combat projection's committed critical result")
	_expect(bool(critical_presentation.get("last_critical", false)), "Critical spectacle must display the committed critical state without a reroll")
	_expect(bool(critical_profile.get("critical", false)), "Critical spectacle must select the stronger visual profile")
	_expect(float(critical_profile.get("ring_peak", 0.0)) > float(normal_profile.get("ring_peak", 0.0)), "Critical ring profile must be visibly stronger than normal")
	_expect(float(critical_profile.get("residue_peak", 0.0)) > float(normal_profile.get("residue_peak", 0.0)), "Critical residue profile must be visibly stronger than normal")
	_expect(float(critical_profile.get("light_energy", 0.0)) > float(normal_profile.get("light_energy", 0.0)), "Critical light profile must be visibly stronger than normal")
	_expect(int((sandbox.debug_snapshot().get("enemy", {}) as Dictionary).get("hit_calls", 0)) == 1, "Critical spectacle must still apply damage exactly once")

	sandbox.impact_presentation.clear()
	await process_frame
	_expect(sandbox.sandbox_camera.position == camera_start, "Interrupted spectacle must restore the camera exactly")
	_expect(_visual_snapshot(target.visual_root) == visual_start, "Interrupted spectacle must restore target presentation transforms exactly")
	_expect(_presentation_is_clean(sandbox), "Interrupted spectacle must leave no transient visual, audio, haptic, or target-feedback state")


func _test_rejected_dead_and_duplicate_results(host: Node3D) -> void:
	var sandbox := _make_sandbox(host, VoidbringerPolishedImpactPresentation.MODE_ENABLED)
	var baseline := _presentation_counts(sandbox)
	var resource_before := sandbox.runtime_character.class_resource.current
	var rejected := sandbox.controller.execute_null_shard_command(
		sandbox.null_shard_definition,
		sandbox.player_origin,
		Vector3.ZERO,
		sandbox.combat_projection,
		{},
		sandbox.equipped_ability_ids
	)
	_expect(not bool(rejected.get("success", true)), "Invalid-direction Null Shard command must reject before gameplay or presentation")
	_expect(sandbox.runtime_character.class_resource.current == resource_before, "Rejected command must not mutate class resources")
	_expect(_presentation_counts(sandbox) == baseline, "Rejected command must create no presentation transaction")

	var invalid_result := VoidbringerImpactResult.new({
		"ability_id": VoidbringerAbilityCatalog.NULL_SHARD,
		"cast_id": &"vb.cast.invalid",
		"damage_applied": 0,
		"critical": true,
	})
	_expect(not sandbox.impact_presentation.present_accepted_null_shard(invalid_result, sandbox.enemy_fixture), "Zero-damage result must not create a spectacle")

	sandbox.enemy_fixture.take_damage(100)
	var dead_health := sandbox.enemy_fixture.health
	_expect(not sandbox.simulate_command(&"fire_null_shard"), "Dead target must reject the Null Shard route")
	_expect(sandbox.enemy_fixture.health == dead_health, "Dead-contact rejection must not mutate target health")
	_expect(_presentation_counts(sandbox) == baseline, "Dead contact must create no presentation transaction")


func _test_reset_replay_and_teardown(host: Node3D) -> void:
	var sandbox := _make_sandbox(host, VoidbringerPolishedImpactPresentation.MODE_ENABLED)
	for replay_index in range(4):
		_expect(sandbox.simulate_command(&"replay_impact"), "Replay %d should reset then start one fresh Null Shard" % replay_index)
		var cast_presentation: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
		_expect(int(cast_presentation.get("transactions", -1)) == 0, "Replay must clear completed presentation transactions before the fresh cast")
		_expect(int(cast_presentation.get("anticipation_cues", 0)) == 1, "Replay must leave exactly one fresh anticipation cue")
		sandbox.simulate_seconds(0.40, 0.01)
		var active_presentation: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
		_expect(int(active_presentation.get("transactions", 0)) == 1, "Replay must create one accepted spectacle transaction")
		_expect(_counts_within_maxima(active_presentation), "Repeated replay must not exceed spectacle maxima")

	sandbox.simulate_seconds(0.85, 0.01)
	await process_frame
	_expect(_presentation_is_clean(sandbox), "Settled replay must leave no stale timers, nodes, effects, or presentation mutations")
	var host_child_count := host.get_child_count()
	sandbox.queue_free()
	await process_frame
	_expect(not is_instance_valid(sandbox), "Scene teardown must release the sandbox presentation owner")
	_expect(host.get_child_count() == host_child_count - 1, "Scene teardown must leave no detached presentation nodes")


func _test_presentation_modes_and_headless_safety(host: Node3D) -> void:
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
		var presentation: Dictionary = snapshot.get("impact_presentation", {})
		gameplay_snapshots.append(_gameplay_snapshot(sandbox, snapshot))
		if presentation_mode == VoidbringerPolishedImpactPresentation.MODE_DISABLED:
			_expect(int(presentation.get("transactions", 0)) == 0, "Disabled presentation must create no spectacle transaction")
		else:
			_expect(int(presentation.get("transactions", 0)) == 1, "%s presentation must observe one accepted hit" % presentation_mode)
		if presentation_mode == VoidbringerPolishedImpactPresentation.MODE_REDUCED:
			_expect(int(presentation.get("inward_motes", 0)) == VoidbringerPolishedImpactPresentation.REDUCED_MOTE_COUNT, "Reduced presentation must use the bounded reduced mote profile")
			_expect(int(presentation.get("light_pulses", 0)) == 0, "Reduced presentation must safely omit the optional light pulse")
		if Input.get_connected_joypads().is_empty() and presentation_mode == VoidbringerPolishedImpactPresentation.MODE_ENABLED:
			_expect(int(presentation.get("haptic_events", -1)) == 0, "No-controller path must safely skip haptics")
		if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
			_expect(int(presentation.get("audio_players", -1)) == 0, "Headless path must not allocate an audio player")

	_expect(gameplay_snapshots[0] == gameplay_snapshots[1] and gameplay_snapshots[1] == gameplay_snapshots[2], "Enabled, reduced, disabled, no-controller, and headless-safe paths must remain gameplay-equivalent")


func _make_sandbox(host: Node3D, presentation_mode: StringName) -> VoidbringerFoundationSandbox:
	var sandbox: VoidbringerFoundationSandbox = SANDBOX_SCENE.instantiate()
	host.add_child(sandbox)
	sandbox.set_process(false)
	sandbox.set_impact_presentation_mode(presentation_mode)
	return sandbox


func _gameplay_snapshot(sandbox: VoidbringerFoundationSandbox, snapshot: Dictionary) -> Dictionary:
	var impact: Dictionary = snapshot.get("last_impact", {})
	var enemy: Dictionary = snapshot.get("enemy", {})
	return {
		"health": int(enemy.get("health", 0)),
		"alive": bool(enemy.get("alive", false)),
		"hit_calls": int(enemy.get("hit_calls", 0)),
		"damage": int(impact.get("damage", 0)),
		"critical": bool(impact.get("critical", false)),
		"resource_current": sandbox.runtime_character.class_resource.current,
		"resource_maximum": sandbox.runtime_character.class_resource.maximum,
		"null_shard_cooldown": sandbox.runtime_session.ability_executor.cooldown_remaining(sandbox.runtime_character.build_id, sandbox.null_shard_definition.ability_id),
		"mass_brand_charges": snapshot.get("mass_brand_runtime", {}).duplicate(true),
		"instability": snapshot.get("instability", {}).duplicate(true),
		"active_projectiles": snapshot.get("null_shards", []).duplicate(true),
		"experience": sandbox.runtime_character.experience,
		"rewards": impact.get("rewards", []).duplicate(true),
	}


func _presentation_counts(sandbox: VoidbringerFoundationSandbox) -> Dictionary:
	var snapshot: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
	return {
		"transactions": int(snapshot.get("transactions", 0)),
		"anticipation": int(snapshot.get("anticipation_cues", 0)),
		"active": int(snapshot.get("active_transactions", 0)),
		"rings": int(snapshot.get("shock_rings", 0)),
		"motes": int(snapshot.get("inward_motes", 0)),
		"residue": int(snapshot.get("residue_nodes", 0)),
		"light": int(snapshot.get("light_pulses", 0)),
	}


func _counts_within_maxima(presentation: Dictionary) -> bool:
	var maxima: Dictionary = presentation.get("maxima", {})
	return (
		int(presentation.get("active_transactions", 0)) <= int(maxima.get("active_transactions", -1))
		and int(presentation.get("shock_rings", 0)) <= int(maxima.get("shock_rings", -1))
		and int(presentation.get("inward_motes", 0)) <= int(maxima.get("inward_motes", -1))
		and int(presentation.get("residue_nodes", 0)) <= int(maxima.get("residue_nodes", -1))
		and int(presentation.get("light_pulses", 0)) <= int(maxima.get("light_pulses", -1))
		and int(presentation.get("audio_players", 0)) <= int(maxima.get("audio_players", -1))
		and int(presentation.get("target_feedback_objects", 0)) <= int(maxima.get("target_feedback_objects", -1))
	)


func _presentation_is_clean(sandbox: VoidbringerFoundationSandbox) -> bool:
	var presentation: Dictionary = sandbox.debug_snapshot().get("impact_presentation", {})
	return (
		int(presentation.get("anticipation_cues", -1)) == 0
		and int(presentation.get("active_transactions", -1)) == 0
		and int(presentation.get("shock_rings", -1)) == 0
		and int(presentation.get("inward_motes", -1)) == 0
		and int(presentation.get("residue_nodes", -1)) == 0
		and int(presentation.get("light_pulses", -1)) == 0
		and int(presentation.get("target_feedback_objects", -1)) == 0
		and not bool(presentation.get("camera_impulse_active", true))
		and bool(presentation.get("camera_restored", false))
	)


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
