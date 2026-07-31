extends Node
class_name VisualFoundationLighting

const RIG_NAME := "VisualFoundationV01_LightingRig"
const ROUTE_MARKER := "SunkenCryptsArtPass0"
const INSTALL_INTERVAL_SECONDS := 0.40

const COLD_KEY := Color(0.43, 0.50, 0.72)
const PALE_VOID := Color(0.72, 0.70, 0.90)
const RESTRAINED_VIOLET := Color(0.43, 0.18, 0.68)
const TRACE_CORRUPTION := Color(0.24, 0.48, 0.16)

var _install_timer: Timer
var _installed_scene_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_install_timer = Timer.new()
	_install_timer.name = "VisualFoundationLightingInstallTimer"
	_install_timer.wait_time = INSTALL_INTERVAL_SECONDS
	_install_timer.one_shot = false
	_install_timer.autostart = true
	_install_timer.timeout.connect(_try_install_into_current_scene)
	add_child(_install_timer)
	call_deferred("_try_install_into_current_scene")


func _try_install_into_current_scene() -> void:
	var scene := get_tree().current_scene as Node3D
	if scene == null:
		return
	var scene_id := scene.get_instance_id()
	if _installed_scene_id == scene_id and scene.has_node(RIG_NAME):
		return
	if scene.get_node_or_null(ROUTE_MARKER) == null:
		return
	var existing := scene.get_node_or_null(RIG_NAME)
	if existing != null:
		_installed_scene_id = scene_id
		return
	var rig := _build_lighting_rig()
	scene.add_child(rig)
	_installed_scene_id = scene_id


func _build_lighting_rig() -> Node3D:
	var rig := Node3D.new()
	rig.name = RIG_NAME
	rig.set_meta("presentation_only", true)
	rig.set_meta("visual_foundation_version", "0.1")

	_add_authored_spot(rig, "GeneratorColdKey", Vector3(-5.4, 8.4, -20.0), COLD_KEY, 1.35, 15.5, 35.0)
	_add_authored_spot(rig, "CatacombsReadabilityKey", Vector3(5.8, 7.6, -46.0), COLD_KEY, 1.22, 14.5, 34.0)
	_add_authored_spot(rig, "HungryHallPaleKey", Vector3(-3.4, 7.0, -73.0), PALE_VOID, 1.06, 13.0, 32.0)
	_add_authored_spot(rig, "ThroneBossSilhouette", Vector3(-7.5, 9.2, -104.5), PALE_VOID, 1.58, 19.0, 31.0)
	_add_authored_spot(rig, "ThroneVoidRim", Vector3(7.0, 6.8, -101.0), RESTRAINED_VIOLET, 0.78, 13.5, 29.0)

	var throne_fill := OmniLight3D.new()
	throne_fill.name = "ThroneRestrainedFill"
	throne_fill.position = Vector3(0.0, 1.25, -103.0)
	throne_fill.light_color = RESTRAINED_VIOLET
	throne_fill.light_energy = 0.34
	throne_fill.omni_range = 7.8
	throne_fill.shadow_enabled = false
	throne_fill.set_meta("presentation_only", true)
	rig.add_child(throne_fill)

	var generator_trace := OmniLight3D.new()
	generator_trace.name = "GeneratorTraceCorruption"
	generator_trace.position = Vector3(0.0, 0.8, -20.0)
	generator_trace.light_color = TRACE_CORRUPTION
	generator_trace.light_energy = 0.18
	generator_trace.omni_range = 4.8
	generator_trace.shadow_enabled = false
	generator_trace.set_meta("presentation_only", true)
	rig.add_child(generator_trace)
	return rig


func _add_authored_spot(
	parent: Node3D,
	light_name: String,
	position_value: Vector3,
	color: Color,
	energy: float,
	range_value: float,
	angle: float
) -> void:
	var light := SpotLight3D.new()
	light.name = light_name
	light.position = position_value
	light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	light.light_color = color
	light.light_energy = energy
	light.spot_range = range_value
	light.spot_angle = angle
	light.shadow_enabled = true
	light.shadow_bias = 0.08
	light.set_meta("presentation_only", true)
	parent.add_child(light)
