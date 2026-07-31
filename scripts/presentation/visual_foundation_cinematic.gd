extends Node
class_name VisualFoundationCinematic

## Presentation-only orchestration for AbyssFall Visual Foundation v0.1.
## This observer composes existing camera, encounter, boss, lighting, fog, and VFX facts.
## It never owns or delays damage, health, death, rewards, movement, collision, AI, or progression.

const ROUTE_MARKER := "SunkenCryptsArtPass0"
const LIGHTING_RIG_NAME := "VisualFoundationV01_LightingRig"
const VFX_SERVICE_PATH := "/root/VisualFoundationVFXService"
const INSTALL_INTERVAL_SECONDS := 0.35
const ENVIRONMENT_BLEND_SPEED := 2.8
const LIGHT_BLEND_SPEED := 3.4

const CAMERA_DEFAULT: StringName = &"default_gameplay"
const CAMERA_SWARM: StringName = &"swarm_combat"
const CAMERA_REVEAL: StringName = &"boss_reveal"

const GRASPING_RIFT_PATH := "res://scripts/grasping_rift.gd"
const HOLLOW_KING_NOVA_PATH := "res://scripts/hollow_king_nova_presentation.gd"
const HOLLOW_KING_DEATH_PATH := "res://scripts/hollow_king_death_presentation.gd"

const ROOM_CENTERS := {
	"courtyard": Vector3(0.0, 0.12, 8.0),
	"generator_room": Vector3(0.0, 0.12, -20.0),
	"catacombs_wave_1": Vector3(0.0, 0.12, -46.0),
	"catacombs_wave_2": Vector3(0.0, 0.12, -46.0),
	"trap_hall": Vector3(0.0, 0.12, -73.0),
	"boss": Vector3(0.0, 0.12, -103.0),
}

var _install_timer: Timer
var _host: Node3D
var _lighting_rig: Node3D
var _world_environment: WorldEnvironment
var _installed_scene_id := 0
var _base_light_energy: Dictionary = {}
var _last_game_state := ""
var _last_camera_state: StringName = &""
var _last_boss_alive := false
var _room_transition_boost := 0.0
var _reveal_boost := 0.0
var _boss_death_boost := 0.0

var _tracked_rifts: Dictionary = {}
var _tracked_nova_presenters: Dictionary = {}
var _tracked_death_presenters: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_install_timer = Timer.new()
	_install_timer.name = "VisualFoundationCinematicInstallTimer"
	_install_timer.wait_time = INSTALL_INTERVAL_SECONDS
	_install_timer.one_shot = false
	_install_timer.autostart = true
	_install_timer.timeout.connect(_try_install_into_current_scene)
	add_child(_install_timer)
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	call_deferred("_try_install_into_current_scene")


func _exit_tree() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.disconnect(_on_tree_node_added)
	_clear_scene_bindings()


func _process(delta: float) -> void:
	if not is_instance_valid(_host):
		return
	_update_event_observers()
	_update_route_presentation(maxf(delta, 0.0))


func _try_install_into_current_scene() -> void:
	var scene := get_tree().current_scene as Node3D
	if scene == null or scene.get_node_or_null(ROUTE_MARKER) == null:
		return
	var scene_id := scene.get_instance_id()
	if _installed_scene_id == scene_id and is_instance_valid(_host):
		_resolve_runtime_dependencies()
		return
	_clear_scene_bindings()
	_host = scene
	_installed_scene_id = scene_id
	_resolve_runtime_dependencies()
	_scan_existing_nodes(scene)
	_last_game_state = _read_string_property(scene, &"game_state", "")
	_last_camera_state = _read_camera_state()
	_last_boss_alive = _is_living_actor(_read_object_property(scene, &"boss"))
	scene.set_meta("visual_foundation_cinematic_version", "0.1")


func _resolve_runtime_dependencies() -> void:
	if not is_instance_valid(_host):
		return
	_lighting_rig = _host.get_node_or_null(LIGHTING_RIG_NAME) as Node3D
	_world_environment = _find_world_environment(_host)
	if is_instance_valid(_lighting_rig) and _base_light_energy.is_empty():
		_capture_light_baselines(_lighting_rig)


func _clear_scene_bindings() -> void:
	_host = null
	_lighting_rig = null
	_world_environment = null
	_installed_scene_id = 0
	_base_light_energy.clear()
	_last_game_state = ""
	_last_camera_state = &""
	_last_boss_alive = false
	_room_transition_boost = 0.0
	_reveal_boost = 0.0
	_boss_death_boost = 0.0
	_tracked_rifts.clear()
	_tracked_nova_presenters.clear()
	_tracked_death_presenters.clear()


func _on_tree_node_added(node: Node) -> void:
	if not is_instance_valid(_host):
		return
	call_deferred("_register_presentation_node", node)


func _scan_existing_nodes(root: Node) -> void:
	_register_presentation_node(root)
	for child: Node in root.get_children():
		_scan_existing_nodes(child)


func _register_presentation_node(node: Node) -> void:
	if not is_instance_valid(node) or not is_instance_valid(_host):
		return
	if node != _host and not _host.is_ancestor_of(node):
		return
	var script_path := _script_path(node)
	var instance_id := node.get_instance_id()
	if script_path == GRASPING_RIFT_PATH:
		_tracked_rifts[instance_id] = {"reference": weakref(node), "reacted": false}
	elif script_path == HOLLOW_KING_NOVA_PATH:
		_tracked_nova_presenters[instance_id] = {
			"reference": weakref(node),
			"release_count": _read_int_property(node, &"release_count", 0),
		}
	elif script_path == HOLLOW_KING_DEATH_PATH:
		_tracked_death_presenters[instance_id] = {
			"reference": weakref(node),
			"transaction_count": _read_int_property(node, &"transaction_count", 0),
		}


func _update_event_observers() -> void:
	_update_rift_observers()
	_update_nova_observers()
	_update_death_observers()


func _update_rift_observers() -> void:
	for instance_id in _tracked_rifts.keys():
		var entry: Dictionary = _tracked_rifts[instance_id]
		var node := (entry["reference"] as WeakRef).get_ref() as Node3D
		if not is_instance_valid(node):
			_tracked_rifts.erase(instance_id)
			continue
		if bool(entry["reacted"]):
			continue
		if _read_bool_property(node, &"collapsed", false):
			entry["reacted"] = true
			_tracked_rifts[instance_id] = entry
			_emit_gravity_burst(node.global_position, 1.15)


func _update_nova_observers() -> void:
	for instance_id in _tracked_nova_presenters.keys():
		var entry: Dictionary = _tracked_nova_presenters[instance_id]
		var presenter := (entry["reference"] as WeakRef).get_ref() as Node
		if not is_instance_valid(presenter):
			_tracked_nova_presenters.erase(instance_id)
			continue
		var release_count := _read_int_property(presenter, &"release_count", 0)
		var prior_count := int(entry["release_count"])
		if release_count > prior_count:
			entry["release_count"] = release_count
			_tracked_nova_presenters[instance_id] = entry
			_emit_gravity_burst(_node_world_position(presenter, Vector3(0.0, 0.1, -103.0)), 1.28)


func _update_death_observers() -> void:
	for instance_id in _tracked_death_presenters.keys():
		var entry: Dictionary = _tracked_death_presenters[instance_id]
		var presenter := (entry["reference"] as WeakRef).get_ref() as Node
		if not is_instance_valid(presenter):
			_tracked_death_presenters.erase(instance_id)
			continue
		var transaction_count := _read_int_property(presenter, &"transaction_count", 0)
		var prior_count := int(entry["transaction_count"])
		if transaction_count > prior_count:
			entry["transaction_count"] = transaction_count
			_tracked_death_presenters[instance_id] = entry
			_boss_death_boost = 1.0
			_emit_gravity_burst(_node_world_position(presenter, Vector3(0.0, 0.1, -103.0)), 1.48)


func _update_route_presentation(delta: float) -> void:
	_resolve_runtime_dependencies()
	if not is_instance_valid(_host):
		return
	var game_state := _read_string_property(_host, &"game_state", "")
	var camera_state := _read_camera_state()
	var enemies_alive := _read_int_property(_host, &"enemies_alive", 0)
	var boss := _read_object_property(_host, &"boss")
	var boss_alive := _is_living_actor(boss)

	if not _last_game_state.is_empty() and game_state != _last_game_state:
		_room_transition_boost = 1.0
		_emit_room_transition(game_state)
	if camera_state == CAMERA_REVEAL and _last_camera_state != CAMERA_REVEAL:
		_reveal_boost = 1.0
		_emit_cinematic_reveal()
	if _last_boss_alive and not boss_alive:
		_boss_death_boost = 1.0
		_emit_gravity_burst(_object_world_position(boss, Vector3(0.0, 0.1, -103.0)), 1.42)

	_room_transition_boost = maxf(_room_transition_boost - delta * 1.6, 0.0)
	_reveal_boost = maxf(_reveal_boost - delta * 0.72, 0.0)
	_boss_death_boost = maxf(_boss_death_boost - delta * 0.62, 0.0)

	var is_swarm := camera_state == CAMERA_SWARM or enemies_alive >= 5
	var is_reveal := camera_state == CAMERA_REVEAL
	var is_boss_route := game_state == "boss" or boss_alive
	_apply_environment_profile(delta, is_swarm, is_reveal, is_boss_route)
	_apply_light_profile(delta, is_swarm, is_reveal, is_boss_route)

	_last_game_state = game_state
	_last_camera_state = camera_state
	_last_boss_alive = boss_alive


func _apply_environment_profile(delta: float, is_swarm: bool, is_reveal: bool, is_boss_route: bool) -> void:
	if not is_instance_valid(_world_environment) or _world_environment.environment == null:
		return
	var environment := _world_environment.environment
	var ambient_target := 0.54
	var fog_target := 0.012
	var glow_target := 0.72
	if is_swarm:
		ambient_target = 0.50
		fog_target = 0.014
		glow_target = 0.78
	if is_boss_route:
		ambient_target = 0.46
		fog_target = 0.016
		glow_target = 0.84
	if is_reveal:
		ambient_target = 0.35
		fog_target = 0.021
		glow_target = 0.96
	ambient_target += _room_transition_boost * 0.025
	fog_target += _reveal_boost * 0.004 + _boss_death_boost * 0.005
	glow_target += _reveal_boost * 0.12 + _boss_death_boost * 0.16

	_blend_environment_float(environment, &"ambient_light_energy", ambient_target, delta)
	_blend_environment_float(environment, &"fog_density", fog_target, delta)
	_blend_environment_float(environment, &"glow_intensity", glow_target, delta)


func _apply_light_profile(delta: float, is_swarm: bool, is_reveal: bool, is_boss_route: bool) -> void:
	if not is_instance_valid(_lighting_rig):
		return
	for light in _collect_lights(_lighting_rig):
		var id := light.get_instance_id()
		if not _base_light_energy.has(id):
			_base_light_energy[id] = light.light_energy
		var multiplier := 1.0
		var lower_name := light.name.to_lower()
		var throne_light := lower_name.contains("throne")
		if is_swarm:
			multiplier *= 1.08
		if is_boss_route:
			multiplier *= 1.18 if throne_light else 0.88
		if is_reveal:
			multiplier *= 1.52 if throne_light else 0.62
		if _boss_death_boost > 0.0 and throne_light:
			multiplier *= 1.0 + _boss_death_boost * 0.45
		var target := float(_base_light_energy[id]) * multiplier
		light.light_energy = move_toward(light.light_energy, target, delta * LIGHT_BLEND_SPEED)


func _emit_room_transition(game_state: String) -> void:
	var position := ROOM_CENTERS.get(game_state, Vector3.ZERO) as Vector3
	var service := _vfx_service()
	if service != null and service.has_method("spawn_dust_burst"):
		service.call("spawn_dust_burst", position, 0.52, 12)


func _emit_cinematic_reveal() -> void:
	var service := _vfx_service()
	if service == null:
		return
	if service.has_method("spawn_void_pulse"):
		service.call("spawn_void_pulse", Vector3(0.0, 0.12, -103.0), 1.10)
	if service.has_method("spawn_debris_reaction"):
		service.call("spawn_debris_reaction", Vector3(0.0, 0.08, -103.0), 0.92, 10)


func _emit_gravity_burst(position: Vector3, strength: float) -> void:
	var service := _vfx_service()
	if service != null and service.has_method("spawn_gravity_burst"):
		service.call("spawn_gravity_burst", position, strength)


func _vfx_service() -> Node:
	return get_node_or_null(VFX_SERVICE_PATH)


func _read_camera_state() -> StringName:
	if not is_instance_valid(_host):
		return &""
	var director := _read_object_property(_host, &"camera_director")
	if director == null:
		return &""
	return StringName(_read_string_property(director, &"state", ""))


func _capture_light_baselines(root: Node) -> void:
	for light in _collect_lights(root):
		_base_light_energy[light.get_instance_id()] = light.light_energy


func _collect_lights(root: Node) -> Array[Light3D]:
	var result: Array[Light3D] = []
	_collect_lights_recursive(root, result)
	return result


func _collect_lights_recursive(root: Node, result: Array[Light3D]) -> void:
	for child: Node in root.get_children():
		if child is Light3D:
			result.append(child as Light3D)
		_collect_lights_recursive(child, result)


func _find_world_environment(scene: Node) -> WorldEnvironment:
	for child: Node in scene.get_children():
		if child is WorldEnvironment:
			return child as WorldEnvironment
	return null


func _blend_environment_float(environment: Environment, property_name: StringName, target: float, delta: float) -> void:
	if not _has_property(environment, property_name):
		return
	var current := float(environment.get(property_name))
	environment.set(property_name, move_toward(current, target, delta * ENVIRONMENT_BLEND_SPEED))


func _script_path(node: Node) -> String:
	var script := node.get_script() as Script
	return script.resource_path if script != null else ""


func _has_property(object: Object, property_name: StringName) -> bool:
	for property_data in object.get_property_list():
		if StringName(property_data.get("name", "")) == property_name:
			return true
	return false


func _read_string_property(object: Object, property_name: StringName, fallback: String) -> String:
	if object == null or not _has_property(object, property_name):
		return fallback
	return str(object.get(property_name))


func _read_int_property(object: Object, property_name: StringName, fallback: int) -> int:
	if object == null or not _has_property(object, property_name):
		return fallback
	return int(object.get(property_name))


func _read_bool_property(object: Object, property_name: StringName, fallback: bool) -> bool:
	if object == null or not _has_property(object, property_name):
		return fallback
	return bool(object.get(property_name))


func _read_object_property(object: Object, property_name: StringName) -> Object:
	if object == null or not _has_property(object, property_name):
		return null
	return object.get(property_name) as Object


func _is_living_actor(actor: Object) -> bool:
	if not is_instance_valid(actor):
		return false
	if _has_property(actor, &"alive") and not bool(actor.get("alive")):
		return false
	if _has_property(actor, &"health") and float(actor.get("health")) <= 0.0:
		return false
	return true


func _node_world_position(node: Node, fallback: Vector3) -> Vector3:
	if node is Node3D:
		return (node as Node3D).global_position
	var parent := node.get_parent()
	return (parent as Node3D).global_position if parent is Node3D else fallback


func _object_world_position(object: Object, fallback: Vector3) -> Vector3:
	return (object as Node3D).global_position if object is Node3D and is_instance_valid(object) else fallback


func snapshot() -> Dictionary:
	return {
		"installed_scene_id": _installed_scene_id,
		"route_bound": is_instance_valid(_host),
		"lighting_bound": is_instance_valid(_lighting_rig),
		"world_environment_bound": is_instance_valid(_world_environment),
		"tracked_rifts": _tracked_rifts.size(),
		"tracked_nova_presenters": _tracked_nova_presenters.size(),
		"tracked_death_presenters": _tracked_death_presenters.size(),
		"last_game_state": _last_game_state,
		"last_camera_state": _last_camera_state,
		"presentation_only": true,
	}
