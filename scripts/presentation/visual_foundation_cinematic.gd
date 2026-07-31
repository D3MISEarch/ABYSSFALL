extends Node
class_name VisualFoundationCinematic

## Presentation-only orchestration for AbyssFall Visual Foundation v0.1.
## It observes the live route's known presentation facts and only composes environment/VFX responses.

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
var _camera_director: Node
var _boss: Node3D
var _lighting_rig: Node3D
var _world_environment: WorldEnvironment
var _vfx_service: Node
var _installed_scene_id := 0
var _authored_lights: Array[Light3D] = []
var _base_light_energy: Dictionary = {}
var _last_game_state := ""
var _last_camera_state: StringName = &""
var _last_boss_alive := false
var _room_transition_boost := 0.0
var _reveal_boost := 0.0
var _boss_death_boost := 0.0
var _boss_death_reaction_emitted := false
var _boss_death_reaction_count := 0
var _dependency_resolution_count := 0
var _room_transition_emissions: Array[Vector3] = []

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
	_install_timer.timeout.connect(_try_bind_route)
	add_child(_install_timer)
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	call_deferred("_try_bind_route")


func _exit_tree() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.disconnect(_on_tree_node_added)
	_clear_scene_bindings(false)


func _process(delta: float) -> void:
	if not is_instance_valid(_host) or not _host.is_inside_tree():
		_clear_scene_bindings()
		return
	_update_event_observers()
	_update_route_presentation(maxf(delta, 0.0))


func _try_bind_route() -> void:
	if is_instance_valid(_host) and _host.is_inside_tree():
		return
	_clear_scene_bindings(false)
	var route_host := get_tree().get_first_node_in_group("visual_foundation_route_host") as Node3D
	if route_host == null:
		_start_discovery()
		return
	_host = route_host
	_installed_scene_id = route_host.get_instance_id()
	set_process(true)
	_watch_route_host(route_host)
	_resolve_runtime_dependencies()
	_scan_existing_nodes(route_host)
	var facts := _read_route_facts()
	_last_game_state = str(facts["game_state"])
	_last_camera_state = facts["camera_state"] as StringName
	_last_boss_alive = bool(facts["boss_alive"])
	route_host.set_meta("visual_foundation_cinematic_version", "0.1")
	_stop_discovery()


func _on_route_host_tree_exited() -> void:
	_clear_scene_bindings()


func _watch_route_host(route_host: Node3D) -> void:
	if not route_host.tree_exited.is_connected(_on_route_host_tree_exited):
		route_host.tree_exited.connect(_on_route_host_tree_exited, CONNECT_ONE_SHOT)


func _start_discovery() -> void:
	if not is_inside_tree() or not is_instance_valid(_install_timer) or not _install_timer.is_inside_tree():
		return
	if _install_timer.is_stopped():
		_install_timer.start()


func _stop_discovery() -> void:
	if is_instance_valid(_install_timer):
		_install_timer.stop()


func _resolve_runtime_dependencies() -> void:
	if not is_instance_valid(_host):
		return
	_dependency_resolution_count += 1
	_lighting_rig = _host.get_node_or_null(LIGHTING_RIG_NAME) as Node3D
	_world_environment = _find_world_environment(_host)
	_camera_director = _host.get("camera_director") as Node
	var resolved_boss := _host.get("boss") as Node3D
	if resolved_boss != _boss:
		_boss = resolved_boss
		_boss_death_reaction_emitted = false
		_boss_death_reaction_count = 0
	_vfx_service = get_node_or_null(VFX_SERVICE_PATH)
	_cache_authored_lights()


func _clear_scene_bindings(restart_discovery: bool = true) -> void:
	_host = null
	_camera_director = null
	_boss = null
	_lighting_rig = null
	_world_environment = null
	_vfx_service = null
	_installed_scene_id = 0
	_authored_lights.clear()
	_base_light_energy.clear()
	_last_game_state = ""
	_last_camera_state = &""
	_last_boss_alive = false
	_room_transition_boost = 0.0
	_reveal_boost = 0.0
	_boss_death_boost = 0.0
	_boss_death_reaction_emitted = false
	_boss_death_reaction_count = 0
	_dependency_resolution_count = 0
	_room_transition_emissions.clear()
	_tracked_rifts.clear()
	_tracked_nova_presenters.clear()
	_tracked_death_presenters.clear()
	set_process(false)
	if restart_discovery:
		_start_discovery()


func _on_tree_node_added(node: Node) -> void:
	if not is_instance_valid(_host) or (node != _host and not _host.is_ancestor_of(node)):
		return
	if (
		node is WorldEnvironment
		or node.name == LIGHTING_RIG_NAME
		or node.name == "IntegratedCameraDirector"
		or node.name == "TheHollowKing"
	):
		call_deferred("_resolve_runtime_dependencies")
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
			"release_count": int(node.get("release_count")),
		}
	elif script_path == HOLLOW_KING_DEATH_PATH:
		_tracked_death_presenters[instance_id] = {
			"reference": weakref(node),
			"transaction_count": int(node.get("transaction_count")),
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
		if bool(node.get("collapsed")):
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
		var release_count := int(presenter.get("release_count"))
		if release_count > int(entry["release_count"]):
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
		var transaction_count := int(presenter.get("transaction_count"))
		if transaction_count > int(entry["transaction_count"]):
			entry["transaction_count"] = transaction_count
			_tracked_death_presenters[instance_id] = entry
			_react_to_confirmed_boss_death(_node_world_position(presenter, Vector3(0.0, 0.1, -103.0)), 1.48)


func _update_route_presentation(delta: float) -> void:
	var facts := _read_route_facts()
	var game_state := str(facts["game_state"])
	var camera_state := facts["camera_state"] as StringName
	var enemies_alive := int(facts["enemies_alive"])
	var boss_alive := bool(facts["boss_alive"])

	if not _last_game_state.is_empty() and game_state != _last_game_state:
		_room_transition_boost = 1.0
		_emit_room_transition(game_state)
	if camera_state == CAMERA_REVEAL and _last_camera_state != CAMERA_REVEAL:
		_reveal_boost = 1.0
		_emit_cinematic_reveal()
	if _last_boss_alive and not boss_alive:
		_react_to_confirmed_boss_death(_object_world_position(_boss, Vector3(0.0, 0.1, -103.0)), 1.42)

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


func _read_route_facts() -> Dictionary:
	if not is_instance_valid(_host):
		return {"game_state": "", "camera_state": &"", "enemies_alive": 0, "boss_alive": false}
	var camera_state: StringName = _camera_director.get("state") if is_instance_valid(_camera_director) else &""
	return {
		"game_state": str(_host.get("game_state")),
		"camera_state": camera_state,
		"enemies_alive": int(_host.get("enemies_alive")),
		"boss_alive": _is_living_actor(_boss),
	}


func _react_to_confirmed_boss_death(position: Vector3, strength: float) -> void:
	if _boss_death_reaction_emitted:
		return
	_boss_death_reaction_emitted = true
	_boss_death_reaction_count += 1
	_boss_death_boost = 1.0
	_emit_gravity_burst(position, strength)


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

	environment.ambient_light_energy = move_toward(environment.ambient_light_energy, ambient_target, delta * ENVIRONMENT_BLEND_SPEED)
	environment.fog_density = move_toward(environment.fog_density, fog_target, delta * ENVIRONMENT_BLEND_SPEED)
	environment.glow_intensity = move_toward(environment.glow_intensity, glow_target, delta * ENVIRONMENT_BLEND_SPEED)


func _apply_light_profile(delta: float, is_swarm: bool, is_reveal: bool, is_boss_route: bool) -> void:
	for index in range(_authored_lights.size() - 1, -1, -1):
		var light := _authored_lights[index]
		if not is_instance_valid(light):
			_authored_lights.remove_at(index)
			continue
		var id := light.get_instance_id()
		var multiplier := 1.0
		var throne_light := light.name.to_lower().contains("throne")
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
	if not ROOM_CENTERS.has(game_state):
		return
	var position := ROOM_CENTERS[game_state] as Vector3
	_room_transition_emissions.append(position)
	if _room_transition_emissions.size() > ROOM_CENTERS.size():
		_room_transition_emissions.pop_front()
	if is_instance_valid(_vfx_service):
		_vfx_service.call("spawn_dust_burst", position, 0.52, 12)


func _emit_cinematic_reveal() -> void:
	if not is_instance_valid(_vfx_service):
		return
	_vfx_service.call("spawn_void_pulse", Vector3(0.0, 0.12, -103.0), 1.10)
	_vfx_service.call("spawn_debris_reaction", Vector3(0.0, 0.08, -103.0), 0.92, 10)


func _emit_gravity_burst(position: Vector3, strength: float) -> void:
	if is_instance_valid(_vfx_service):
		_vfx_service.call("spawn_gravity_burst", position, strength)


func _cache_authored_lights() -> void:
	_authored_lights.clear()
	if not is_instance_valid(_lighting_rig):
		_base_light_energy.clear()
		return
	_collect_lights_recursive(_lighting_rig, _authored_lights)
	var live_ids := {}
	for light in _authored_lights:
		if not is_instance_valid(light):
			continue
		var id := light.get_instance_id()
		live_ids[id] = true
		if not _base_light_energy.has(id):
			_base_light_energy[id] = light.light_energy
	for id in _base_light_energy.keys():
		if not live_ids.has(id):
			_base_light_energy.erase(id)


func _collect_lights_recursive(root: Node, result: Array[Light3D]) -> void:
	for child: Node in root.get_children():
		if child is Light3D:
			result.append(child as Light3D)
		_collect_lights_recursive(child, result)


func _find_world_environment(scene: Node) -> WorldEnvironment:
	for child in scene.get_children():
		if child is WorldEnvironment:
			return child as WorldEnvironment
	return null


func _script_path(node: Node) -> String:
	var script := node.get_script() as Script
	return script.resource_path if script != null else ""


func _is_living_actor(actor: Node3D) -> bool:
	return is_instance_valid(actor) and bool(actor.get("alive")) and float(actor.get("health")) > 0.0


func _node_world_position(node: Node, fallback: Vector3) -> Vector3:
	if node is Node3D:
		return (node as Node3D).global_position
	var parent := node.get_parent()
	return (parent as Node3D).global_position if parent is Node3D else fallback


func _object_world_position(object: Node3D, fallback: Vector3) -> Vector3:
	return object.global_position if is_instance_valid(object) else fallback


func snapshot() -> Dictionary:
	return {
		"installed_scene_id": _installed_scene_id,
		"route_bound": is_instance_valid(_host),
		"lighting_bound": is_instance_valid(_lighting_rig),
		"world_environment_bound": is_instance_valid(_world_environment),
		"cached_authored_lights": _authored_lights.size(),
		"dependency_resolution_count": _dependency_resolution_count,
		"room_transition_emissions": _room_transition_emissions.duplicate(),
		"boss_death_reaction_emitted": _boss_death_reaction_emitted,
		"boss_death_reaction_count": _boss_death_reaction_count,
		"tracked_rifts": _tracked_rifts.size(),
		"tracked_nova_presenters": _tracked_nova_presenters.size(),
		"tracked_death_presenters": _tracked_death_presenters.size(),
		"last_game_state": _last_game_state,
		"last_camera_state": _last_camera_state,
		"presentation_only": true,
	}
