extends SceneTree

const SANDBOX_SCENE = preload("res://scenes/voidbringer_foundation_sandbox.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sandbox: VoidbringerFoundationSandbox = SANDBOX_SCENE.instantiate()
	root.add_child(sandbox)
	sandbox.set_process(false)

	var initial := sandbox.debug_snapshot()
	_expect(bool(initial.get("runtime_bound", false)), "Playable skill sandbox should bind the authoritative RuntimeSession")
	_expect(int((initial.get("mass_brand_runtime", {}) as Dictionary).get("current", 0)) == 2, "Mass Brand should begin with two available charges")
	_expect(int((initial.get("enemy", {}) as Dictionary).get("health", 0)) == 100, "Sandbox enemy should begin at deterministic full health")

	_expect(sandbox.simulate_command(&"mass_brand_enemy"), "Q-path enemy Mass Brand should commit")
	var enemy_brand := sandbox.debug_snapshot()
	_expect((enemy_brand.get("anchors", []) as Array).size() == 1, "Enemy Mass Brand should create one Anchor")
	_expect(int((enemy_brand.get("enemy", {}) as Dictionary).get("health", 0)) == 92, "Enemy Mass Brand should deliver the approved eight damage")
	_expect(int((enemy_brand.get("enemy", {}) as Dictionary).get("hit_calls", 0)) == 1, "Enemy Mass Brand should call damage exactly once")
	_expect(int((enemy_brand.get("last_impact", {}) as Dictionary).get("damage", 0)) == 8, "Sandbox should expose the committed Mass Brand impact result")
	_expect(int((enemy_brand.get("mass_brand_runtime", {}) as Dictionary).get("current", 0)) == 1, "Enemy Mass Brand should consume exactly one charge")

	_expect(sandbox.simulate_command(&"clear"), "Sandbox clear should reset the skill loop")
	var reset := sandbox.debug_snapshot()
	_expect(int((reset.get("enemy", {}) as Dictionary).get("health", 0)) == 100, "Reset should restore enemy health")
	_expect(int((reset.get("mass_brand_runtime", {}) as Dictionary).get("current", 0)) == 2, "Reset should restore both Mass Brand charges")

	_expect(sandbox.simulate_command(&"mass_brand_terrain"), "W-path terrain Mass Brand should commit")
	_expect(sandbox.simulate_command(&"mass_brand_corpse"), "E-path corpse Mass Brand should commit")
	var fold_setup := sandbox.debug_snapshot()
	_expect((fold_setup.get("anchors", []) as Array).size() == 2, "Two Mass Brands should create two authoritative Anchors")
	_expect((fold_setup.get("fold_lines", []) as Array).size() == 1, "Terrain and corpse Anchors should create one Fold Line across the firing lane")
	_expect(int((fold_setup.get("enemy", {}) as Dictionary).get("health", 0)) == 100, "Terrain and corpse Mass Brand contacts must not fake enemy damage")
	_expect(int((fold_setup.get("mass_brand_runtime", {}) as Dictionary).get("current", 0)) == 0, "Two committed Brands should exhaust both charges")

	_expect(sandbox.simulate_command(&"fire_null_shard"), "Space-path Null Shard should commit")
	var launched := sandbox.debug_snapshot()
	_expect((launched.get("null_shards", []) as Array).size() == 1, "Committed Null Shard should create one authoritative moving projectile")
	_expect(int(launched.get("projectile_visual_count", 0)) == 1, "Committed Null Shard should create one bounded sandbox visual")
	_expect(is_equal_approx(float((launched.get("instability", {}) as Dictionary).get("current", 0.0)), 14.0), "Two Brands and one Shard should commit fourteen total Instability")

	sandbox.simulate_seconds(0.60, 0.02)
	var resolved := sandbox.debug_snapshot()
	var enemy_state: Dictionary = resolved.get("enemy", {})
	var impact: Dictionary = resolved.get("last_impact", {})
	_expect(int(enemy_state.get("health", 0)) == 80, "One-Fold Null Shard should deal twenty damage to the sandbox enemy")
	_expect(int(enemy_state.get("hit_calls", 0)) == 1, "Null Shard collision should call enemy damage exactly once")
	_expect(StringName(str(impact.get("ability_id", ""))) == &"vb.skill.null_shard", "Last sandbox impact should belong to Null Shard")
	_expect(int(impact.get("damage", 0)) == 20, "One Fold crossing should expose the resolved twenty-damage impact")
	_expect(int(impact.get("fold_crossing_count", 0)) == 1, "Projectile should credit exactly one Fold crossing in the combat lane")
	_expect((resolved.get("null_shards", []) as Array).is_empty(), "Resolved projectile should leave no active gameplay owner")
	_expect(int(resolved.get("projectile_visual_count", -1)) == 0, "Resolved projectile should leave no registered visual")

	var masses: Array[float] = []
	for anchor: Dictionary in resolved.get("anchors", []):
		masses.append(float(anchor.get("mass", 0.0)))
	masses.sort()
	_expect(masses == [7.0, 22.0], "Fold crossing should add exactly two Mass to each terrain/corpse endpoint")

	_expect(sandbox.simulate_command(&"clear"), "Final clear should reset gameplay and presentation state")
	var cleared := sandbox.debug_snapshot()
	_expect((cleared.get("anchors", []) as Array).is_empty(), "Final clear should remove all Anchors")
	_expect((cleared.get("fold_lines", []) as Array).is_empty(), "Final clear should remove all Fold Lines")
	_expect((cleared.get("null_shards", []) as Array).is_empty(), "Final clear should remove all projectiles")
	_expect(int((cleared.get("enemy", {}) as Dictionary).get("health", 0)) == 100, "Final clear should restore enemy health")
	_expect(not bool((cleared.get("instability", {}) as Dictionary).get("in_breach", true)), "Final clear should leave a contained class state")

	sandbox.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: Voidbringer playable skill sandbox")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
