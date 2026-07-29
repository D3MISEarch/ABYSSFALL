class_name VoidbringerFoundationSandbox
extends Node3D

const CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_controller.gd")

var controller = CONTROLLER_SCRIPT.new()
var debug_level := 1
var anchor_visual_root: Node3D
var fold_line_visual_root: Node3D
var hud_label: Label
var enemy_fixture: Node3D
var terrain_fixture: Node3D
var corpse_fixture: Node3D
var _hud_refresh_remaining := 0.0


func _ready() -> void:
	name = "VoidbringerFoundationSandbox"
	_build_world()
	controller.foundation_changed.connect(_on_foundation_changed)
	controller.configure(debug_level)
	_refresh_presentation()
	print("ABYSSFALL_SANDBOX_LAUNCHED:voidbringer_anchor")


func _process(delta: float) -> void:
	controller.tick(delta)
	_hud_refresh_remaining -= delta
	if _hud_refresh_remaining <= 0.0:
		_hud_refresh_remaining = 0.1
		_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed or (event as InputEventKey).echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_1:
			simulate_command(&"place_enemy")
		KEY_2:
			simulate_command(&"place_terrain")
		KEY_3:
			simulate_command(&"place_corpse")
		KEY_M:
			simulate_command(&"load_mass")
		KEY_I:
			simulate_command(&"add_instability")
		KEY_T:
			simulate_command(&"advance_time")
		KEY_L:
			simulate_command(&"toggle_level")
		KEY_C:
			simulate_command(&"clear")


func simulate_command(command: StringName) -> bool:
	match command:
		&"place_enemy":
			controller.place_anchor(&"enemy", enemy_fixture, enemy_fixture.global_position, 8.0)
		&"place_terrain":
			controller.place_anchor(&"terrain", terrain_fixture, terrain_fixture.global_position, 5.0)
		&"place_corpse":
			controller.place_anchor(&"corpse", corpse_fixture, corpse_fixture.global_position, 20.0)
		&"load_mass":
			var anchors: Array[Dictionary] = controller.anchors.active_anchors()
			if anchors.is_empty():
				return false
			controller.add_anchor_mass(anchors.back().get("anchor_id", &""), 20.0)
		&"add_instability":
			controller.commit_spatial_ability(20.0)
		&"advance_time":
			controller.tick(1.0)
		&"toggle_level":
			debug_level = 5 if debug_level < 5 else 1
			controller.configure(debug_level)
		&"clear":
			controller.clear()
		&"reset":
			controller.clear()
			debug_level = 1
			controller.configure(debug_level)
		_:
			return false
	_refresh_presentation()
	return true


func debug_snapshot() -> Dictionary:
	var snapshot := controller.snapshot()
	snapshot["debug_level"] = debug_level
	snapshot["capacity"] = controller.anchors.capacity()
	return snapshot


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color(0.006, 0.008, 0.018)
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color(0.16, 0.13, 0.25)
	environment_resource.ambient_light_energy = 0.55
	environment.environment = environment_resource
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	light.light_energy = 1.25
	light.light_color = Color(0.68, 0.72, 1.0)
	light.shadow_enabled = true
	add_child(light)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 10.5, 12.5)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(16.0, 0.18, 12.0)
	floor.mesh = floor_mesh
	floor.position.y = -0.12
	floor.material_override = _material(Color(0.035, 0.03, 0.065), 0.0)
	add_child(floor)

	var center_disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 3.2
	disc_mesh.bottom_radius = 3.2
	disc_mesh.height = 0.025
	center_disc.mesh = disc_mesh
	center_disc.position.y = 0.01
	center_disc.material_override = _material(Color(0.11, 0.025, 0.22), 1.2)
	add_child(center_disc)

	enemy_fixture = _build_fixture("EnemyFixture", Vector3(-4.0, 0.45, -1.5), Color(0.62, 0.08, 0.16), &"enemy")
	terrain_fixture = _build_fixture("TerrainFixture", Vector3(4.0, 0.6, -1.5), Color(0.18, 0.20, 0.28), &"terrain")
	corpse_fixture = _build_fixture("CorpseFixture", Vector3(0.0, 0.22, 3.4), Color(0.22, 0.42, 0.18), &"corpse")

	anchor_visual_root = Node3D.new()
	anchor_visual_root.name = "AnchorDebugVisuals"
	add_child(anchor_visual_root)
	fold_line_visual_root = Node3D.new()
	fold_line_visual_root.name = "FoldLineDebugVisuals"
	add_child(fold_line_visual_root)

	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud_label = Label.new()
	hud_label.position = Vector2(22.0, 18.0)
	hud_label.size = Vector2(880.0, 330.0)
	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.add_theme_color_override("font_color", Color(0.88, 0.90, 1.0))
	hud_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	hud_label.add_theme_constant_override("shadow_offset_x", 2)
	hud_label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(hud_label)


func _build_fixture(fixture_name: String, position: Vector3, color: Color, carrier_type: StringName) -> Node3D:
	var root := Node3D.new()
	root.name = fixture_name
	root.position = position
	root.set_meta("carrier_type", carrier_type)
	add_child(root)

	var mesh_instance := MeshInstance3D.new()
	if carrier_type == &"terrain":
		var box := BoxMesh.new()
		box.size = Vector3(1.8, 1.2, 1.8)
		mesh_instance.mesh = box
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.48
		capsule.height = 1.5 if carrier_type == &"enemy" else 0.55
		mesh_instance.mesh = capsule
	mesh_instance.material_override = _material(color, 0.35)
	root.add_child(mesh_instance)

	var label := Label3D.new()
	label.text = String(carrier_type).to_upper()
	label.position.y = 1.35 if carrier_type != &"corpse" else 0.65
	label.font_size = 34
	label.modulate = Color(0.92, 0.93, 1.0)
	root.add_child(label)
	return root


func _on_foundation_changed(_snapshot: Dictionary) -> void:
	_refresh_presentation()


func _refresh_presentation() -> void:
	_rebuild_anchor_visuals()
	_rebuild_fold_line_visuals()
	_refresh_hud()


func _rebuild_anchor_visuals() -> void:
	_clear_children(anchor_visual_root)
	for anchor: Dictionary in controller.anchors.active_anchors():
		var root := Node3D.new()
		root.name = String(anchor.get("anchor_id", &"anchor"))
		root.position = (anchor.get("position", Vector3.ZERO) as Vector3) + Vector3(0.0, 0.22, 0.0)
		anchor_visual_root.add_child(root)

		var stage := StringName(str(anchor.get("mass_stage", &"dormant")))
		var color := Color(0.42, 0.20, 0.78)
		var emission := 1.5
		if stage == &"dense":
			color = Color(0.62, 0.18, 0.92)
			emission = 2.8
		elif stage == &"critical":
			color = Color(0.92, 0.90, 1.0)
			emission = 5.0

		var core := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.56
		core.mesh = sphere
		core.material_override = _material(color, emission)
		root.add_child(core)

		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.42
		torus.outer_radius = 0.48
		ring.mesh = torus
		ring.rotation_degrees.x = 90.0
		ring.material_override = _material(color, emission * 0.75)
		root.add_child(ring)

		var label := Label3D.new()
		label.text = "%s  %d MASS" % [String(stage).to_upper(), int(round(float(anchor.get("mass", 0.0))))]
		label.position.y = 0.72
		label.font_size = 28
		root.add_child(label)


func _rebuild_fold_line_visuals() -> void:
	_clear_children(fold_line_visual_root)
	for line: Dictionary in controller.fold_lines.lines():
		var start: Vector3 = line.get("start", Vector3.ZERO)
		var finish: Vector3 = line.get("end", Vector3.ZERO)
		var length := start.distance_to(finish)
		if length <= 0.001:
			continue
		var visual := MeshInstance3D.new()
		visual.name = String(line.get("line_id", &"fold_line"))
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.055, 0.055, length)
		visual.mesh = mesh
		visual.position = (start + finish) * 0.5 + Vector3(0.0, 0.24, 0.0)
		visual.look_at(finish + Vector3(0.0, 0.24, 0.0), Vector3.UP)
		visual.material_override = _material(Color(0.72, 0.62, 1.0), 3.2)
		fold_line_visual_root.add_child(visual)


func _refresh_hud() -> void:
	if not is_instance_valid(hud_label):
		return
	var snapshot := controller.snapshot()
	var instability_state: Dictionary = snapshot.get("instability", {})
	var state_name := "BREACH" if bool(instability_state.get("in_breach", false)) else "CONTAINED"
	var lines := PackedStringArray([
		"VOIDBRINGER FOUNDATION SANDBOX",
		"[1] Enemy Anchor   [2] Terrain Anchor   [3] Corpse Anchor",
		"[M] +20 Mass       [I] +20 Instability   [T] Advance 1s",
		"[L] Toggle Level 1/5   [C] Clear",
		"",
		"Level %d | Anchor Capacity %d | Active %d | Fold Lines %d" % [
			debug_level,
			controller.anchors.capacity(),
			controller.anchors.active_count(),
			controller.fold_lines.line_count(),
		],
		"Instability %.1f / 100 | %s | Breach %.1fs | Anchor Influence x%.2f" % [
			float(instability_state.get("current", 0.0)),
			state_name,
			float(instability_state.get("breach_remaining", 0.0)),
			float(instability_state.get("anchor_influence_multiplier", 1.0)),
		],
	])
	for anchor: Dictionary in controller.anchors.active_anchors():
		lines.append(
			"%s | %s | %s | Mass %.0f | %.1fs" % [
				String(anchor.get("anchor_id", &"")),
				String(anchor.get("carrier_type", &"")).to_upper(),
				String(anchor.get("mass_stage", &"")).to_upper(),
				float(anchor.get("mass", 0.0)),
				float(anchor.get("remaining_seconds", 0.0)),
			]
		)
	hud_label.text = "\n".join(lines)


func _clear_children(root: Node) -> void:
	if not is_instance_valid(root):
		return
	for child: Node in root.get_children():
		child.queue_free()


func _material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.18
	material.roughness = 0.28
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
