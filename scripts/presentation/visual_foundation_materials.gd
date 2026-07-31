extends Node
class_name VisualFoundationMaterials

const ROUTE_MARKER := "SunkenCryptsArtPass0"
const INSTALL_INTERVAL_SECONDS := 0.55
const MATERIAL_PASS_VERSION := "0.1"

const OBSIDIAN_BLACK := Color(0.018, 0.016, 0.026, 1.0)
const CHARCOAL_STONE := Color(0.046, 0.048, 0.058, 1.0)
const WET_STONE := Color(0.066, 0.072, 0.086, 1.0)
const BLACKENED_IRON := Color(0.055, 0.050, 0.064, 1.0)
const RUST_TRACE := Color(0.115, 0.064, 0.045, 1.0)
const VOID_VIOLET := Color(0.38, 0.055, 0.68, 1.0)
const GRAVITATIONAL_WHITE := Color(0.76, 0.80, 0.96, 1.0)
const CORRUPTION_GREEN := Color(0.18, 0.39, 0.055, 1.0)

var _install_timer: Timer
var _installed_scene_id := 0
var _materials: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_shared_materials()
	_install_timer = Timer.new()
	_install_timer.name = "VisualFoundationMaterialsInstallTimer"
	_install_timer.wait_time = INSTALL_INTERVAL_SECONDS
	_install_timer.one_shot = false
	_install_timer.autostart = true
	_install_timer.timeout.connect(_try_apply_to_current_scene)
	add_child(_install_timer)
	call_deferred("_try_apply_to_current_scene")


func _try_apply_to_current_scene() -> void:
	var scene := get_tree().current_scene as Node3D
	if scene == null:
		return
	var scene_id := scene.get_instance_id()
	if _installed_scene_id == scene_id:
		return
	var route_root := scene.get_node_or_null(ROUTE_MARKER)
	if route_root == null:
		return
	_apply_materials_recursive(route_root)
	_apply_base_route_surfaces(scene)
	route_root.set_meta("visual_foundation_material_pass", MATERIAL_PASS_VERSION)
	_installed_scene_id = scene_id


func _build_shared_materials() -> void:
	_materials["stone"] = _make_surface(CHARCOAL_STONE, 0.86, 0.02)
	_materials["wet_stone"] = _make_surface(WET_STONE, 0.42, 0.04)
	_materials["obsidian"] = _make_surface(OBSIDIAN_BLACK, 0.34, 0.16)
	_materials["iron"] = _make_surface(BLACKENED_IRON, 0.58, 0.72)
	_materials["rusted_iron"] = _make_surface(BLACKENED_IRON.lerp(RUST_TRACE, 0.30), 0.76, 0.48)
	_materials["violet_emissive"] = _make_emissive(VOID_VIOLET, 1.10, 0.30)
	_materials["pale_emissive"] = _make_emissive(GRAVITATIONAL_WHITE, 0.72, 0.26)
	_materials["corruption_trace"] = _make_emissive(CORRUPTION_GREEN, 0.38, 0.48)


func _make_surface(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_emissive(color: Color, energy: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _apply_materials_recursive(root: Node) -> void:
	for child in root.get_children():
		if child is MeshInstance3D:
			_apply_named_material(child as MeshInstance3D)
		_apply_materials_recursive(child)


func _apply_named_material(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.get_meta("visual_foundation_material_applied", false):
		return
	var lower_name := mesh_instance.name.to_lower()
	var material_key := ""
	if _contains_any(lower_name, ["fracture", "void", "rift", "ritualring", "ritual_ring"]):
		material_key = "violet_emissive"
	elif _contains_any(lower_name, ["pale", "gravity", "gravitational", "core"]):
		material_key = "pale_emissive"
	elif _contains_any(lower_name, ["corruption", "residue", "sickness"]):
		material_key = "corruption_trace"
	elif _contains_any(lower_name, ["cage", "chain", "clamp", "machine", "iron", "anchor", "restraint"]):
		material_key = "rusted_iron"
	elif _contains_any(lower_name, ["wet", "puddle", "channel", "drain"]):
		material_key = "wet_stone"
	elif _contains_any(lower_name, ["slab", "throne", "altar", "coffin"]):
		material_key = "obsidian"
	elif _contains_any(lower_name, ["tile", "wall", "pillar", "arch", "floor", "stone", "rubble"]):
		material_key = "stone"
	if material_key.is_empty():
		return
	mesh_instance.material_override = _materials[material_key]
	mesh_instance.set_meta("visual_foundation_material_applied", true)
	mesh_instance.set_meta("visual_foundation_material_key", material_key)


func _apply_base_route_surfaces(scene: Node3D) -> void:
	for node_name in ["CryptFloor", "WestOuterWall", "EastOuterWall", "SouthSeal", "NorthThroneWall"]:
		var root := scene.get_node_or_null(node_name)
		if root == null:
			continue
		for child in root.get_children():
			if child is MeshInstance3D:
				var mesh_instance := child as MeshInstance3D
				mesh_instance.material_override = _materials["wet_stone"] if node_name == "CryptFloor" else _materials["stone"]
				mesh_instance.set_meta("visual_foundation_material_applied", true)
				mesh_instance.set_meta("visual_foundation_material_key", "wet_stone" if node_name == "CryptFloor" else "stone")
				break


func _contains_any(value: String, needles: Array[String]) -> bool:
	for needle in needles:
		if value.contains(needle):
			return true
	return false
