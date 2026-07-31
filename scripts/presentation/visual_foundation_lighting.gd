extends Node
class_name VisualFoundationLighting

const MATERIAL_PASS_SCRIPT = preload("res://scripts/presentation/visual_foundation_materials.gd")
const RIG_NAME := "VisualFoundationV01_LightingRig"
const ROUTE_MARKER := "SunkenCryptsArtPass0"
const INSTALL_INTERVAL_SECONDS := 0.40

const COLD_KEY := Color(0.43, 0.50, 0.72)
const PALE_VOID := Color(0.72, 0.70, 0.90)
const RESTRAINED_VIOLET := Color(0.43, 0.18, 0.68)
const TRACE_CORRUPTION := Color(0.24, 0.48, 0.16)
const FOG_COLOR := Color(0.075, 0.055, 0.105)
const DUST_COLOR := Color(0.22, 0.19, 0.25)

const ATMOSPHERE_ROOMS := [
	{"name": "CourtyardDust", "position": Vector3(0.0, 0.45, 8.0), "extents": Vector3(13.0, 1.2, 11.0), "amount": 24},
	{"name": "GeneratorDust", "position": Vector3(0.0, 0.45, -20.0), "extents": Vector3(13.0, 1.2, 11.0), "amount": 28},
	{"name": "CatacombsDust", "position": Vector3(0.0, 0.45, -46.0), "extents": Vector3(13.0, 1.2, 11.0), "amount": 28},
	{"name": "HungryHallDust", "position": Vector3(0.0, 0.45, -73.0), "extents": Vector3(13.0, 1.2, 10.0), "amount": 24},
	{"name": "ThroneDust", "position": Vector3(0.0, 0.55, -103.0), "extents": Vector3(14.0, 1.5, 10.0), "amount": 34}
]

var _install_timer: Timer
var _installed_scene_id := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var material_pass := MATERIAL_PASS_SCRIPT.new()
	material_pass.name = "VisualFoundationMaterials"
	add_child(material_pass)
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
	var rig := _build_visual_foundation_rig(scene)
	scene.add_child(rig)
	_installed_scene_id = scene_id


func _build_visual_foundation_rig(scene: Node3D) -> Node3D:
	var rig := Node3D.new()
	rig.name = RIG_NAME
	rig.set_meta("presentation_only", true)
	rig.set_meta("visual_foundation_version", "0.1")
	_install_authored_lighting(rig)
	_install_bounded_atmosphere(rig)
	_tune_world_environment(scene)
	return rig


func _install_authored_lighting(rig: Node3D) -> void:
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


func _tune_world_environment(scene: Node3D) -> void:
	var world_environment := _find_world_environment(scene)
	if world_environment == null or world_environment.environment == null:
		return
	var environment := world_environment.environment
	_set_if_property(environment, &"background_energy_multiplier", 0.72)
	_set_if_property(environment, &"ambient_light_color", Color(0.15, 0.11, 0.20))
	_set_if_property(environment, &"ambient_light_energy", 0.54)
	_set_if_property(environment, &"reflected_light_source", Environment.REFLECTION_SOURCE_DISABLED)
	_set_if_property(environment, &"tonemap_exposure", 1.06)
	_set_if_property(environment, &"tonemap_white", 1.22)
	_set_if_property(environment, &"glow_enabled", true)
	_set_if_property(environment, &"glow_intensity", 0.72)
	_set_if_property(environment, &"glow_strength", 0.82)
	_set_if_property(environment, &"fog_enabled", true)
	_set_if_property(environment, &"fog_light_color", FOG_COLOR)
	_set_if_property(environment, &"fog_light_energy", 0.42)
	_set_if_property(environment, &"fog_density", 0.012)
	_set_if_property(environment, &"fog_height", 0.35)
	_set_if_property(environment, &"fog_height_density", 0.20)
	_set_if_property(environment, &"fog_aerial_perspective", 0.34)
	world_environment.set_meta("visual_foundation_tuned", true)


func _find_world_environment(scene: Node) -> WorldEnvironment:
	for child in scene.get_children():
		if child is WorldEnvironment:
			return child as WorldEnvironment
	return null


func _set_if_property(object: Object, property_name: StringName, value: Variant) -> void:
	for property_data in object.get_property_list():
		if StringName(property_data.get("name", "")) == property_name:
			object.set(property_name, value)
			return


func _install_bounded_atmosphere(rig: Node3D) -> void:
	for room_data in ATMOSPHERE_ROOMS:
		var emitter := _build_dust_emitter(
			String(room_data["name"]),
			room_data["position"] as Vector3,
			room_data["extents"] as Vector3,
			int(room_data["amount"])
		)
		rig.add_child(emitter)


func _build_dust_emitter(
	emitter_name: String,
	position_value: Vector3,
	emission_extents: Vector3,
	particle_amount: int
) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = emitter_name
	particles.position = position_value
	particles.amount = particle_amount
	particles.lifetime = 8.0
	particles.preprocess = 8.0
	particles.randomness = 0.72
	particles.visibility_aabb = AABB(-emission_extents, emission_extents * 2.0)
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = emission_extents
	particles.direction = Vector3(0.18, 0.78, -0.12)
	particles.spread = 180.0
	particles.gravity = Vector3(0.0, -0.012, 0.0)
	particles.initial_velocity_min = 0.018
	particles.initial_velocity_max = 0.055
	particles.scale_amount_min = 0.45
	particles.scale_amount_max = 1.0
	particles.color = DUST_COLOR
	particles.draw_order = CPUParticles3D.DRAW_ORDER_LIFETIME
	particles.mesh = _build_dust_mesh()
	particles.set_meta("presentation_only", true)
	particles.set_meta("bounded_particle_amount", particle_amount)
	return particles


func _build_dust_mesh() -> Mesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.012
	mesh.height = 0.024
	mesh.radial_segments = 4
	mesh.rings = 2
	var material := StandardMaterial3D.new()
	material.albedo_color = DUST_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_receive_shadows = true
	mesh.material = material
	return mesh


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
