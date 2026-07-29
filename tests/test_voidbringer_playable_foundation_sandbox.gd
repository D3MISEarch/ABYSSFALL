extends SceneTree

const SANDBOX_SCENE = preload("res://scenes/voidbringer_foundation_sandbox.tscn")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sandbox = SANDBOX_SCENE.instantiate()
	root.add_child(sandbox)
	sandbox.set_process(false)

	var initial: Dictionary = sandbox.debug_snapshot()
	_expect(int(initial.get("debug_level", 0)) == 1, "The sandbox should begin at level one")
	_expect(int(initial.get("capacity", 0)) == 2, "The level-one sandbox should expose the two-anchor cap")
	_expect((initial.get("anchors", []) as Array).is_empty(), "The sandbox should begin with no transient anchors")

	_expect(sandbox.simulate_command(&"place_enemy"), "The sandbox should place an enemy anchor")
	_expect(sandbox.simulate_command(&"place_terrain"), "The sandbox should place a terrain anchor")
	var two_anchor_state: Dictionary = sandbox.debug_snapshot()
	_expect((two_anchor_state.get("anchors", []) as Array).size() == 2, "The sandbox should expose both placed anchors")
	_expect((two_anchor_state.get("fold_lines", []) as Array).size() == 1, "Two sandbox anchors should produce one visible Fold Line")

	_expect(sandbox.simulate_command(&"load_mass"), "The sandbox should load Mass into the newest anchor")
	var loaded_anchors: Array = sandbox.debug_snapshot().get("anchors", []) as Array
	_expect(float((loaded_anchors.back() as Dictionary).get("mass", 0.0)) == 25.0, "Terrain placement plus debug loading should produce twenty-five Mass")

	for _index in range(5):
		_expect(sandbox.simulate_command(&"add_instability"), "The sandbox should accept deterministic Instability commands")
	var breach_state: Dictionary = sandbox.debug_snapshot().get("instability", {}) as Dictionary
	_expect(bool(breach_state.get("in_breach", false)), "Five Instability commands should enter base Breach")
	_expect(is_equal_approx(float(breach_state.get("anchor_influence_multiplier", 1.0)), 1.30), "The sandbox should expose Breach anchor influence")

	_expect(sandbox.simulate_command(&"toggle_level"), "The sandbox should toggle to the level-five cap")
	_expect(int(sandbox.debug_snapshot().get("capacity", 0)) == 3, "Level five should expose three-anchor capacity")
	_expect(sandbox.simulate_command(&"place_corpse"), "The sandbox should place a corpse anchor")
	_expect((sandbox.debug_snapshot().get("anchors", []) as Array).size() == 3, "The level-five sandbox should retain three anchors")

	_expect(sandbox.simulate_command(&"clear"), "The sandbox should clear all transient state")
	var cleared: Dictionary = sandbox.debug_snapshot()
	_expect((cleared.get("anchors", []) as Array).is_empty(), "Sandbox clear should remove every anchor")
	_expect((cleared.get("fold_lines", []) as Array).is_empty(), "Sandbox clear should remove every Fold Line")
	_expect(not bool((cleared.get("instability", {}) as Dictionary).get("in_breach", true)), "Sandbox clear should exit Breach")

	sandbox.free()
	if failures.is_empty():
		print("PASS: Voidbringer playable foundation sandbox")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: %s" % failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("ASSERTION FAILED: %s" % message)
