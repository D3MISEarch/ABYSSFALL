extends Node3D
class_name SunkenCryptsArtPass0

const PALETTE = preload("res://scripts/art/abyssfall_art_palette.gd")

const COURTYARD_CENTER := Vector3(0.0, 0.0, 8.0)
const COURTYARD_MIN_X := -15.7
const COURTYARD_MAX_X := 15.7
const COURTYARD_MIN_Z := -3.8
const COURTYARD_MAX_Z := 19.0
const GENERATOR_CENTER := Vector3(0.0, 0.0, -20.0)
const CATACOMBS_CENTER := Vector3(0.0, 0.0, -46.0)
const HUNGRY_HALL_CENTER := Vector3(0.0, 0.0, -73.0)
const THRONE_CENTER := Vector3(0.0, 0.0, -103.0)

var installed := false
var host_root: Node3D


func install(host: Node3D) -> bool:
	if installed or host == null:
		return false
	installed = true
	host_root = host
	name = "SunkenCryptsArtPass0"
	_configure_world()
	_suppress_legacy_room_treatment()
	_retint_base_geometry()
	_build_courtyard_floor()
	_build_ritual_fractures()
	_build_wall_dressing()
	_build_restraint_machinery()
	_build_hanging_cages()
	_build_corruption_residue()
	_build_rubble_and_bones()
	_build_courtyard_lighting()
	_build_generator_chamber()
	_build_collapsed_catacombs()
	_build_hungry_hall()
	_build_abyssal_throne()
	_build_route_lighting()
	call_deferred("_configure_runtime_hud")
	return true


func _configure_world() -> void:
	if host_root == null:
		return
	for child: Node in host_root.get_children():
		if child is WorldEnvironment:
			var world_environment := child as WorldEnvironment
			var environment := world_environment.environment
			if environment != null:
				environment.background_color = PALETTE.ABYSS_BLACK
				environment.ambient_light_color = Color(0.16, 0.17, 0.23)
				environment.ambient_light_energy = 0.72
				environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		elif child is DirectionalLight3D:
			var moon := child as DirectionalLight3D
			moon.light_color = Color(0.47, 0.55, 0.78)
			moon.light_energy = 1.12
			moon.shadow_enabled = true


func _suppress_legacy_room_treatment() -> void:
	if host_root == null:
		return
	for child: Node in host_root.get_children():
		if child is MeshInstance3D and child.name.begins_with("RoomFoundationDisc_"):
			var legacy_disc := child as MeshInstance3D
			legacy_disc.visible = false
			legacy_disc.set_meta("art_pass0_hidden_legacy_disc", true)
		elif child is OmniLight3D:
			var legacy_light := child as OmniLight3D
			if is_equal_approx(legacy_light.omni_range, 3.8) and is_equal_approx(legacy_light.light_energy, 0.72):
				legacy_light.light_color = Color(0.47, 0.55, 0.78)
				legacy_light.light_energy = 0.16
				legacy_light.set_meta("art_pass0_retuned_legacy_room_light", true)


func _retint_base_geometry() -> void:
	if host_root == null:
		return
	var floor_body := host_root.get_node_or_null("CryptFloor") as StaticBody3D
	if floor_body != null:
		_set_first_mesh_material(floor_body, PALETTE.stone(PALETTE.DROWNED_STONE, 0.52))
	for wall_name in ["WestOuterWall", "EastOuterWall", "SouthSeal", "NorthThroneWall"]:
		var wall := host_root.get_node_or_null(wall_name) as StaticBody3D
		if wall != null:
			_set_first_mesh_material(wall, PALETTE.stone(Color(0.052, 0.050, 0.062), 0.18))
	for child: Node in host_root.get_children():
		if child is StaticBody3D and child.name.begins_with("CryptPillar_8_"):
			_set_first_mesh_material(child, PALETTE.stone(Color(0.064, 0.060, 0.073), 0.12))


func _set_first_mesh_material(root: Node, material: Material) -> void:
	for child: Node in root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = material
			return


func _build_courtyard_floor() -> void:
	var floor_root := Node3D.new()
	floor_root.name = "ArtPass0_CourtyardTiles"
	add_child(floor_root)
	var tile_size := 2.15
	var x_index := 0
	var x := COURTYARD_MIN_X + tile_size * 0.5
	while x < COURTYARD_MAX_X:
		var z_index := 0
		var z := COURTYARD_MIN_Z + tile_size * 0.5
		while z < COURTYARD_MAX_Z:
			var tile := MeshInstance3D.new()
			tile.name = "CryptTile_%02d_%02d" % [x_index, z_index]
			var mesh := BoxMesh.new()
			var inset := 0.07 + float((x_index * 7 + z_index * 3) % 3) * 0.025
			mesh.size = Vector3(tile_size - inset, 0.035, tile_size - inset)
			tile.mesh = mesh
			tile.position = Vector3(x, 0.018 + float((x_index + z_index) % 2) * 0.002, z)
			var variation := float((x_index * 11 + z_index * 5) % 5) * 0.008
			tile.material_override = PALETTE.stone(
				Color(0.072 + variation, 0.076 + variation, 0.088 + variation),
				0.24 + variation * 4.0
			)
			floor_root.add_child(tile)
			z += tile_size
			z_index += 1
		x += tile_size
		x_index += 1

	var central_slab := MeshInstance3D.new()
	central_slab.name = "CourtyardCentralSlab"
	var slab_mesh := CylinderMesh.new()
	slab_mesh.top_radius = 3.7
	slab_mesh.bottom_radius = 3.7
	slab_mesh.height = 0.055
	central_slab.mesh = slab_mesh
	central_slab.position = COURTYARD_CENTER + Vector3(0.0, 0.045, 0.0)
	central_slab.material_override = PALETTE.stone(Color(0.050, 0.052, 0.064), 0.48)
	floor_root.add_child(central_slab)


func _build_ritual_fractures() -> void:
	var fracture_root := Node3D.new()
	fracture_root.name = "ArtPass0_RitualFractures"
	add_child(fracture_root)
	var restrained_violet := PALETTE.emissive(PALETTE.VOID_VIOLET, 0.72, 0.38)
	var pale_material := PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 0.40, 0.30)

	for ring_index in range(3):
		var ring := MeshInstance3D.new()
		ring.name = "BrokenRitualRing_%d" % ring_index
		var torus := TorusMesh.new()
		var radius := 1.65 + float(ring_index) * 0.72
		torus.inner_radius = radius - 0.035
		torus.outer_radius = radius + 0.035
		torus.rings = 32
		torus.ring_segments = 6
		ring.mesh = torus
		ring.position = COURTYARD_CENTER + Vector3(0.0, 0.078 + float(ring_index) * 0.003, 0.0)
		ring.material_override = restrained_violet if ring_index != 1 else pale_material
		fracture_root.add_child(ring)

	for i in range(18):
		var fracture := MeshInstance3D.new()
		fracture.name = "RadialFracture_%02d" % i
		var fracture_mesh := BoxMesh.new()
		var length := 0.55 + float((i * 13) % 7) * 0.13
		fracture_mesh.size = Vector3(0.035, 0.018, length)
		fracture.mesh = fracture_mesh
		var angle := TAU * float(i) / 18.0 + sin(float(i) * 2.1) * 0.08
		var radius := 2.4 + float(i % 4) * 0.62
		fracture.position = COURTYARD_CENTER + Vector3(cos(angle) * radius, 0.085, sin(angle) * radius)
		fracture.rotation_degrees.y = -rad_to_deg(angle)
		fracture.material_override = restrained_violet if i % 5 != 0 else pale_material
		fracture_root.add_child(fracture)


func _build_wall_dressing() -> void:
	var wall_root := Node3D.new()
	wall_root.name = "ArtPass0_CourtyardArchitecture"
	add_child(wall_root)
	for z in [-2.0, 4.0, 10.0, 16.0]:
		_build_wall_bay(wall_root, Vector3(-16.88, 0.0, z), 90.0)
		_build_wall_bay(wall_root, Vector3(16.88, 0.0, z), -90.0)
	for x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		_build_wall_bay(wall_root, Vector3(x, 0.0, 19.88), 180.0)


func _build_wall_bay(parent: Node3D, position_value: Vector3, yaw: float) -> void:
	var bay := Node3D.new()
	bay.name = "CryptWallBay"
	bay.position = position_value
	bay.rotation_degrees.y = yaw
	parent.add_child(bay)
	var stone_material := PALETTE.stone(Color(0.082, 0.079, 0.093), 0.18)
	var inset_material := PALETTE.stone(Color(0.030, 0.029, 0.038), 0.04)
	_add_box(bay, Vector3(-1.28, 1.45, 0.0), Vector3(0.48, 3.15, 0.72), stone_material)
	_add_box(bay, Vector3(1.28, 1.45, 0.0), Vector3(0.48, 3.15, 0.72), stone_material)
	_add_box(bay, Vector3(0.0, 2.85, 0.0), Vector3(3.05, 0.42, 0.78), stone_material)
	_add_box(bay, Vector3(0.0, 1.25, -0.10), Vector3(1.80, 2.30, 0.34), inset_material)
	_add_box(bay, Vector3(0.0, 0.32, -0.34), Vector3(2.35, 0.32, 0.58), stone_material)
	var coffin := MeshInstance3D.new()
	coffin.name = "SealedCryptSlab"
	var coffin_mesh := PrismMesh.new()
	coffin_mesh.size = Vector3(0.72, 1.72, 0.26)
	coffin.mesh = coffin_mesh
	coffin.position = Vector3(0.0, 1.23, -0.34)
	coffin.material_override = PALETTE.stone(Color(0.102, 0.094, 0.108), 0.10)
	bay.add_child(coffin)


func _build_restraint_machinery() -> void:
	var machine_root := Node3D.new()
	machine_root.name = "ArtPass0_RestraintMachinery"
	add_child(machine_root)
	for placement in [
		Vector3(-11.8, 0.0, 13.8),
		Vector3(11.5, 0.0, 13.0),
		Vector3(-12.2, 0.0, 1.4),
		Vector3(12.0, 0.0, 3.0),
	]:
		_build_restraint_machine(machine_root, placement)


func _build_restraint_machine(parent: Node3D, position_value: Vector3) -> void:
	var machine := Node3D.new()
	machine.name = "RestraintMachine"
	machine.position = position_value
	parent.add_child(machine)
	var metal_material := PALETTE.metal(PALETTE.ANCIENT_METAL, 0.68)
	var void_material := PALETTE.emissive(PALETTE.VOID_VIOLET, 1.05, 0.32)
	_add_box(machine, Vector3(0.0, 0.22, 0.0), Vector3(2.2, 0.35, 1.65), metal_material)
	for x in [-0.78, 0.78]:
		_add_box(machine, Vector3(x, 1.35, 0.0), Vector3(0.28, 2.45, 0.32), metal_material)
		_add_box(machine, Vector3(x, 2.50, 0.0), Vector3(0.52, 0.24, 0.58), metal_material)
	var clamp_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.54
	torus.outer_radius = 0.69
	torus.rings = 20
	torus.ring_segments = 8
	clamp_ring.mesh = torus
	clamp_ring.rotation_degrees.x = 90.0
	clamp_ring.position = Vector3(0.0, 1.42, 0.05)
	clamp_ring.material_override = metal_material
	machine.add_child(clamp_ring)
	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.24
	core_mesh.height = 0.45
	core.mesh = core_mesh
	core.position = Vector3(0.0, 1.42, 0.05)
	core.material_override = void_material
	machine.add_child(core)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.42, 0.0)
	light.light_color = PALETTE.VOID_FRACTURE
	light.light_energy = 0.72
	light.omni_range = 3.4
	machine.add_child(light)


func _build_hanging_cages() -> void:
	var cage_root := Node3D.new()
	cage_root.name = "ArtPass0_HangingCages"
	add_child(cage_root)
	_build_cage(cage_root, Vector3(-14.1, 2.0, 7.0), 0.82)
	_build_cage(cage_root, Vector3(14.0, 2.35, 8.8), 0.70)
	_build_cage(cage_root, Vector3(-13.6, 2.55, 16.4), 0.62)


func _build_cage(parent: Node3D, position_value: Vector3, scale_value: float) -> void:
	var cage := Node3D.new()
	cage.name = "HangingRestraintCage"
	cage.position = position_value
	cage.scale = Vector3.ONE * scale_value
	parent.add_child(cage)
	var metal_material := PALETTE.metal(PALETTE.ANCIENT_METAL, 0.82)
	for y in [-0.92, 0.92]:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.78
		torus.outer_radius = 0.91
		torus.rings = 18
		torus.ring_segments = 6
		ring.mesh = torus
		ring.position.y = y
		ring.material_override = metal_material
		cage.add_child(ring)
	for i in range(9):
		var angle := TAU * float(i) / 9.0
		var bar := MeshInstance3D.new()
		var bar_mesh := CylinderMesh.new()
		bar_mesh.top_radius = 0.045
		bar_mesh.bottom_radius = 0.045
		bar_mesh.height = 1.95
		bar.mesh = bar_mesh
		bar.position = Vector3(cos(angle) * 0.84, 0.0, sin(angle) * 0.84)
		bar.rotation_degrees.z = 4.0 * sin(float(i) * 2.0)
		bar.material_override = metal_material
		cage.add_child(bar)
	_build_chain(cage, Vector3(0.0, 1.18, 0.0), 7, metal_material)


func _build_chain(parent: Node3D, start: Vector3, link_count: int, material: Material) -> void:
	for i in range(link_count):
		var link := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.10
		torus.outer_radius = 0.16
		torus.rings = 12
		torus.ring_segments = 5
		link.mesh = torus
		link.position = start + Vector3(0.0, float(i) * 0.25, 0.0)
		link.rotation_degrees = Vector3(90.0, 90.0 if i % 2 == 0 else 0.0, 0.0)
		link.material_override = material
		parent.add_child(link)


func _build_corruption_residue() -> void:
	var residue_root := Node3D.new()
	residue_root.name = "ArtPass0_CorruptionResidue"
	add_child(residue_root)
	var residue_material := PALETTE.translucent(PALETTE.CORRUPTION_GREEN, 0.34, 0.22)
	for data in [
		[Vector3(-12.4, 0.055, 17.0), 1.35, 0.72],
		[Vector3(13.0, 0.055, 5.0), 1.05, 0.62],
		[Vector3(-13.2, 0.055, 1.2), 0.82, 0.48],
	]:
		var pool := MeshInstance3D.new()
		pool.name = "CorruptionPool"
		var mesh := CylinderMesh.new()
		mesh.top_radius = float(data[1])
		mesh.bottom_radius = float(data[1]) * float(data[2])
		mesh.height = 0.018
		pool.mesh = mesh
		pool.position = data[0]
		pool.scale.z = 0.72
		pool.material_override = residue_material
		residue_root.add_child(pool)


func _build_rubble_and_bones() -> void:
	var dressing_root := Node3D.new()
	dressing_root.name = "ArtPass0_RubbleAndBones"
	add_child(dressing_root)
	var stone_material := PALETTE.stone(Color(0.048, 0.045, 0.052), 0.06)
	var bone_material := PALETTE.bone()
	for i in range(22):
		var angle := TAU * float(i) / 22.0 + float(i % 3) * 0.17
		var radius := 9.4 + float((i * 7) % 5) * 0.72
		var rubble := MeshInstance3D.new()
		var rubble_mesh := PrismMesh.new()
		rubble_mesh.size = Vector3(
			0.22 + float(i % 4) * 0.07,
			0.18 + float(i % 3) * 0.06,
			0.28 + float((i + 2) % 4) * 0.08
		)
		rubble.mesh = rubble_mesh
		rubble.position = COURTYARD_CENTER + Vector3(cos(angle) * radius, 0.10, sin(angle) * radius)
		rubble.rotation_degrees = Vector3(float((i * 17) % 30), float((i * 47) % 180), float((i * 23) % 25))
		rubble.material_override = stone_material
		dressing_root.add_child(rubble)
	for i in range(9):
		var bone := MeshInstance3D.new()
		var bone_mesh := CylinderMesh.new()
		bone_mesh.top_radius = 0.045
		bone_mesh.bottom_radius = 0.065
		bone_mesh.height = 0.55 + float(i % 3) * 0.18
		bone.mesh = bone_mesh
		var angle := TAU * float(i) / 9.0 + 0.3
		var radius := 6.2 + float(i % 4) * 1.25
		bone.position = COURTYARD_CENTER + Vector3(cos(angle) * radius, 0.08, sin(angle) * radius)
		bone.rotation_degrees = Vector3(90.0, float((i * 37) % 180), 18.0)
		bone.material_override = bone_material
		dressing_root.add_child(bone)


func _build_courtyard_lighting() -> void:
	var light_root := Node3D.new()
	light_root.name = "ArtPass0_CourtyardLighting"
	add_child(light_root)
	for data in [
		[Vector3(-5.5, 8.5, 9.0), Color(0.50, 0.58, 0.86), 3.0],
		[Vector3(6.5, 7.4, 5.0), Color(0.42, 0.50, 0.75), 2.5],
	]:
		var light := SpotLight3D.new()
		light.position = data[0]
		light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		light.light_color = data[1]
		light.light_energy = float(data[2])
		light.spot_range = 16.0
		light.spot_angle = 32.0
		light.shadow_enabled = true
		light_root.add_child(light)
	var center_light := OmniLight3D.new()
	center_light.position = COURTYARD_CENTER + Vector3(0.0, 1.2, 0.0)
	center_light.light_color = PALETTE.VOID_FRACTURE
	center_light.light_energy = 0.62
	center_light.omni_range = 7.5
	light_root.add_child(center_light)


func _configure_runtime_hud() -> void:
	if host_root == null:
		return
	var has_message_label := false
	for property_info: Dictionary in host_root.get_property_list():
		if str(property_info.get("name", "")) == "message_label":
			has_message_label = true
			break
	if not has_message_label:
		return
	var label := host_root.get("message_label") as Label
	if label == null:
		return
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.position = Vector2(-300.0, 92.0)
	label.size = Vector2(600.0, 68.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))


func _build_generator_chamber() -> void:
	var room_root := Node3D.new()
	room_root.name = "ArtPass0_GeneratorChamber"
	add_child(room_root)
	_build_room_tile_field(
		room_root,
		GENERATOR_CENTER,
		30.0,
		23.0,
		2.35,
		Color(0.060, 0.071, 0.074),
		0.42,
		19
	)
	var metal := PALETTE.metal(PALETTE.ANCIENT_METAL, 0.72)
	var dark_metal := PALETTE.metal(Color(0.052, 0.050, 0.061), 0.86)
	var green := PALETTE.emissive(PALETTE.SICKNESS_GREEN, 0.78, 0.34)
	for x in [-12.8, 12.8]:
		for z in [-27.0, -20.0, -13.0]:
			_build_generator_stack(room_root, Vector3(x, 0.0, z), metal, dark_metal, green)
	for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
		_add_box(room_root, Vector3(x, 0.085, -20.0), Vector3(2.7, 0.055, 0.22), green)
	for z in [-26.0, -14.0]:
		_add_box(room_root, Vector3(0.0, 0.075, z), Vector3(18.0, 0.045, 0.16), green)
	_build_corruption_pool(room_root, Vector3(-9.5, 0.065, -10.0), 1.55, 0.58)
	_build_corruption_pool(room_root, Vector3(10.8, 0.065, -29.0), 1.25, 0.72)


func _build_generator_stack(
	parent: Node3D,
	position_value: Vector3,
	metal: Material,
	dark_metal: Material,
	green: Material
) -> void:
	var stack := Node3D.new()
	stack.name = "GeneratorRestraintStack"
	stack.position = position_value
	parent.add_child(stack)
	_add_box(stack, Vector3(0.0, 0.18, 0.0), Vector3(2.4, 0.32, 2.1), dark_metal)
	_add_box(stack, Vector3(-0.78, 1.25, 0.0), Vector3(0.32, 2.15, 0.40), metal)
	_add_box(stack, Vector3(0.78, 1.25, 0.0), Vector3(0.32, 2.15, 0.40), metal)
	_add_box(stack, Vector3(0.0, 2.22, 0.0), Vector3(2.0, 0.26, 0.50), metal)
	var core := MeshInstance3D.new()
	core.name = "ContainedCorruptionCore"
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.46
	core_mesh.bottom_radius = 0.62
	core_mesh.height = 1.35
	core.mesh = core_mesh
	core.position = Vector3(0.0, 1.15, 0.0)
	core.material_override = green
	stack.add_child(core)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 1.35, 0.0)
	light.light_color = PALETTE.SICKNESS_GREEN
	light.light_energy = 0.82
	light.omni_range = 4.6
	stack.add_child(light)


func _build_collapsed_catacombs() -> void:
	var room_root := Node3D.new()
	room_root.name = "ArtPass0_CollapsedCatacombs"
	add_child(room_root)
	_build_room_tile_field(
		room_root,
		CATACOMBS_CENTER,
		30.0,
		23.0,
		2.05,
		Color(0.058, 0.058, 0.068),
		0.18,
		37
	)
	var tomb_stone := PALETTE.stone(Color(0.082, 0.078, 0.088), 0.12)
	var tomb_dark := PALETTE.stone(Color(0.026, 0.025, 0.032), 0.02)
	for x in [-13.2, 13.2]:
		var yaw := 90.0 if x < 0.0 else -90.0
		for z in [-56.0, -51.0, -46.0, -41.0, -36.0]:
			_build_burial_niche(room_root, Vector3(x, 0.0, z), yaw, tomb_stone, tomb_dark)
	for z in [-53.5, -46.0, -38.5]:
		_build_collapsed_arch(room_root, Vector3(0.0, 0.0, z), float(int(abs(z)) % 2) * 8.0 - 4.0)
	_build_bone_trench(room_root, -8.6, -46.0, 20.0)
	_build_bone_trench(room_root, 8.6, -46.0, 20.0)


func _build_burial_niche(
	parent: Node3D,
	position_value: Vector3,
	yaw: float,
	stone: Material,
	dark: Material
) -> void:
	var niche := Node3D.new()
	niche.name = "BurialNiche"
	niche.position = position_value
	niche.rotation_degrees.y = yaw
	parent.add_child(niche)
	_add_box(niche, Vector3(0.0, 1.35, 0.0), Vector3(2.8, 2.8, 0.55), stone)
	_add_box(niche, Vector3(0.0, 1.36, -0.31), Vector3(1.75, 1.75, 0.18), dark)
	for y in [0.72, 1.34, 1.96]:
		_add_box(niche, Vector3(0.0, y, -0.45), Vector3(1.45, 0.40, 0.30), stone)


func _build_collapsed_arch(parent: Node3D, position_value: Vector3, roll: float) -> void:
	var arch := Node3D.new()
	arch.name = "CollapsedCryptArch"
	arch.position = position_value
	arch.rotation_degrees.z = roll
	parent.add_child(arch)
	var stone := PALETTE.stone(Color(0.078, 0.074, 0.086), 0.16)
	_add_box(arch, Vector3(-5.8, 1.45, 0.0), Vector3(1.0, 3.1, 0.90), stone)
	_add_box(arch, Vector3(5.8, 1.45, 0.0), Vector3(1.0, 3.1, 0.90), stone)
	_add_box(arch, Vector3(-3.2, 2.9, 0.0), Vector3(4.0, 0.55, 0.92), stone)
	_add_box(arch, Vector3(3.2, 2.72, 0.0), Vector3(3.8, 0.55, 0.92), stone)


func _build_bone_trench(parent: Node3D, x: float, center_z: float, length: float) -> void:
	var trench := Node3D.new()
	trench.name = "BoneTrench"
	parent.add_child(trench)
	var trench_material := PALETTE.stone(Color(0.018, 0.017, 0.023), 0.0)
	_add_box(trench, Vector3(x, 0.045, center_z), Vector3(2.1, 0.04, length), trench_material)
	var bone_material := PALETTE.bone()
	for i in range(18):
		var bone := MeshInstance3D.new()
		var bone_mesh := CylinderMesh.new()
		bone_mesh.top_radius = 0.035
		bone_mesh.bottom_radius = 0.055
		bone_mesh.height = 0.38 + float(i % 4) * 0.11
		bone.mesh = bone_mesh
		bone.position = Vector3(
			x + (-0.65 + float((i * 7) % 13) / 10.0),
			0.09,
			center_z - length * 0.45 + float(i) * (length * 0.9 / 18.0)
		)
		bone.rotation_degrees = Vector3(90.0, float((i * 41) % 180), 14.0)
		bone.material_override = bone_material
		trench.add_child(bone)


func _build_hungry_hall() -> void:
	var room_root := Node3D.new()
	room_root.name = "ArtPass0_HungryHall"
	add_child(room_root)
	var walkway := PALETTE.stone(Color(0.068, 0.071, 0.081), 0.34)
	var void_material := PALETTE.stone(Color(0.010, 0.009, 0.016), 0.0)
	for z_index in range(10):
		var z := -83.0 + float(z_index) * 2.2
		var slab := _add_box(room_root, Vector3(0.0, 0.045, z), Vector3(10.4, 0.06, 2.05), walkway)
		slab.name = "HungryHallSlab_%02d" % z_index
	_add_box(room_root, Vector3(-11.5, 0.03, -73.0), Vector3(10.5, 0.03, 22.0), void_material)
	_add_box(room_root, Vector3(11.5, 0.03, -73.0), Vector3(10.5, 0.03, 22.0), void_material)
	var metal := PALETTE.metal(PALETTE.ANCIENT_METAL, 0.88)
	for z in [-82.0, -77.0, -72.0, -67.0, -62.0]:
		_build_hall_rib(room_root, Vector3(0.0, 0.0, z), metal)
	var edge_green := PALETTE.emissive(PALETTE.CORRUPTION_GREEN, 0.52, 0.42)
	_add_box(room_root, Vector3(-5.4, 0.085, -73.0), Vector3(0.12, 0.05, 21.5), edge_green)
	_add_box(room_root, Vector3(5.4, 0.085, -73.0), Vector3(0.12, 0.05, 21.5), edge_green)


func _build_hall_rib(parent: Node3D, position_value: Vector3, material: Material) -> void:
	var rib := Node3D.new()
	rib.name = "HungryHallRib"
	rib.position = position_value
	parent.add_child(rib)
	_add_box(rib, Vector3(-5.8, 1.15, 0.0), Vector3(0.38, 2.4, 0.42), material)
	_add_box(rib, Vector3(5.8, 1.15, 0.0), Vector3(0.38, 2.4, 0.42), material)
	_add_box(rib, Vector3(-3.0, 2.25, 0.0), Vector3(5.4, 0.28, 0.42), material)
	_add_box(rib, Vector3(3.0, 2.25, 0.0), Vector3(5.4, 0.28, 0.42), material)
	_build_chain(rib, Vector3(-5.8, 2.45, 0.0), 5, material)
	_build_chain(rib, Vector3(5.8, 2.45, 0.0), 5, material)


func _build_abyssal_throne() -> void:
	var room_root := Node3D.new()
	room_root.name = "ArtPass0_AbyssalThrone"
	add_child(room_root)
	_build_room_tile_field(
		room_root,
		THRONE_CENTER,
		30.0,
		22.5,
		2.5,
		Color(0.049, 0.048, 0.060),
		0.30,
		61
	)
	var obsidian := PALETTE.stone(PALETTE.OBSIDIAN, 0.22)
	var iron := PALETTE.metal(PALETTE.ANCIENT_METAL, 0.62)
	var white := PALETTE.emissive(PALETTE.GRAVITATIONAL_WHITE, 0.54, 0.24)
	var violet := PALETTE.emissive(PALETTE.VOID_FRACTURE, 0.72, 0.24)
	var dais := MeshInstance3D.new()
	dais.name = "AbyssalThroneDais"
	var dais_mesh := CylinderMesh.new()
	dais_mesh.top_radius = 5.4
	dais_mesh.bottom_radius = 6.0
	dais_mesh.height = 0.28
	dais.mesh = dais_mesh
	dais.position = THRONE_CENTER + Vector3(0.0, 0.14, -1.0)
	dais.material_override = obsidian
	room_root.add_child(dais)
	for ring_index in range(2):
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		var radius := 3.5 + float(ring_index) * 1.25
		torus.inner_radius = radius - 0.045
		torus.outer_radius = radius + 0.045
		torus.rings = 32
		torus.ring_segments = 7
		ring.mesh = torus
		ring.position = THRONE_CENTER + Vector3(0.0, 0.31, -1.0)
		ring.material_override = white if ring_index == 0 else violet
		room_root.add_child(ring)
	_build_throne_silhouette(room_root, Vector3(0.0, 0.0, -110.4), obsidian, iron)
	for x in [-13.0, -8.0, 8.0, 13.0]:
		_build_throne_buttress(room_root, Vector3(x, 0.0, -104.5), obsidian, iron)
	for i in range(10):
		var shard := MeshInstance3D.new()
		shard.name = "FloatingObsidianShard"
		var shard_mesh := PrismMesh.new()
		shard_mesh.size = Vector3(0.35 + float(i % 3) * 0.10, 1.2 + float(i % 4) * 0.34, 0.28)
		shard.mesh = shard_mesh
		var side := -1.0 if i % 2 == 0 else 1.0
		shard.position = Vector3(side * (7.2 + float(i % 5) * 1.05), 1.6 + float(i % 3) * 0.55, -108.5 + float(i % 4) * 2.3)
		shard.rotation_degrees = Vector3(float((i * 17) % 25), float((i * 43) % 180), side * 12.0)
		shard.material_override = obsidian
		room_root.add_child(shard)


func _build_throne_silhouette(
	parent: Node3D,
	position_value: Vector3,
	stone: Material,
	metal: Material
) -> void:
	var throne := Node3D.new()
	throne.name = "AbyssalThroneSilhouette"
	throne.position = position_value
	parent.add_child(throne)
	_add_box(throne, Vector3(0.0, 0.38, 0.0), Vector3(5.5, 0.75, 3.4), stone)
	_add_box(throne, Vector3(0.0, 2.15, 0.75), Vector3(3.4, 3.6, 0.75), stone)
	_add_box(throne, Vector3(-2.15, 1.35, 0.15), Vector3(0.55, 2.2, 2.2), metal)
	_add_box(throne, Vector3(2.15, 1.35, 0.15), Vector3(0.55, 2.2, 2.2), metal)
	_add_box(throne, Vector3(0.0, 4.05, 0.75), Vector3(4.8, 0.55, 0.85), metal)


func _build_throne_buttress(
	parent: Node3D,
	position_value: Vector3,
	stone: Material,
	metal: Material
) -> void:
	var buttress := Node3D.new()
	buttress.name = "ThroneButtress"
	buttress.position = position_value
	parent.add_child(buttress)
	_add_box(buttress, Vector3(0.0, 1.65, 0.0), Vector3(1.45, 3.5, 1.4), stone)
	_add_box(buttress, Vector3(0.0, 3.45, 0.0), Vector3(2.1, 0.42, 1.7), metal)
	_add_box(buttress, Vector3(0.0, 0.22, 0.0), Vector3(2.4, 0.42, 2.3), stone)


func _build_route_lighting() -> void:
	var light_root := Node3D.new()
	light_root.name = "ArtPass0_RouteLighting"
	add_child(light_root)
	_build_room_spot(light_root, Vector3(-5.0, 8.0, -20.0), Color(0.40, 0.58, 0.46), 2.8, 16.0)
	_build_room_spot(light_root, Vector3(5.5, 7.2, -46.0), Color(0.47, 0.52, 0.72), 2.4, 15.0)
	_build_room_spot(light_root, Vector3(0.0, 7.0, -73.0), Color(0.36, 0.44, 0.62), 2.0, 13.0)
	_build_room_spot(light_root, Vector3(-6.0, 9.0, -103.0), Color(0.55, 0.58, 0.82), 3.4, 18.0)
	var throne_light := OmniLight3D.new()
	throne_light.position = THRONE_CENTER + Vector3(0.0, 2.0, -1.0)
	throne_light.light_color = PALETTE.VOID_FRACTURE
	throne_light.light_energy = 1.05
	throne_light.omni_range = 9.5
	light_root.add_child(throne_light)


func _build_room_spot(
	parent: Node3D,
	position_value: Vector3,
	color: Color,
	energy: float,
	range_value: float
) -> void:
	var light := SpotLight3D.new()
	light.position = position_value
	light.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	light.light_color = color
	light.light_energy = energy
	light.spot_range = range_value
	light.spot_angle = 38.0
	light.shadow_enabled = true
	parent.add_child(light)


func _build_room_tile_field(
	parent: Node3D,
	center: Vector3,
	width: float,
	depth: float,
	tile_size: float,
	base_color: Color,
	wetness: float,
	seed: int
) -> void:
	var tiles := Node3D.new()
	tiles.name = "RoomTileField"
	parent.add_child(tiles)
	var x_count := int(floor(width / tile_size))
	var z_count := int(floor(depth / tile_size))
	for x_index in range(x_count):
		for z_index in range(z_count):
			var tile := MeshInstance3D.new()
			tile.name = "RoomTile_%02d_%02d" % [x_index, z_index]
			var mesh := BoxMesh.new()
			var variation_index := (x_index * 13 + z_index * 7 + seed) % 6
			var gap := 0.08 + float(variation_index % 3) * 0.025
			mesh.size = Vector3(tile_size - gap, 0.045, tile_size - gap)
			tile.mesh = mesh
			var x := center.x - width * 0.5 + tile_size * (float(x_index) + 0.5)
			var z := center.z - depth * 0.5 + tile_size * (float(z_index) + 0.5)
			tile.position = Vector3(x, 0.026 + float((x_index + z_index + seed) % 2) * 0.002, z)
			var variation := float(variation_index) * 0.006
			tile.material_override = PALETTE.stone(
				Color(base_color.r + variation, base_color.g + variation, base_color.b + variation),
				wetness
			)
			tiles.add_child(tile)


func _build_corruption_pool(parent: Node3D, position_value: Vector3, radius: float, stretch: float) -> void:
	var pool := MeshInstance3D.new()
	pool.name = "LocalizedCorruptionPool"
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 0.82
	mesh.height = 0.02
	pool.mesh = mesh
	pool.position = position_value
	pool.scale.z = stretch
	pool.material_override = PALETTE.translucent(PALETTE.CORRUPTION_GREEN, 0.32, 0.20)
	parent.add_child(pool)


func _add_box(parent: Node3D, position_value: Vector3, size_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	mesh_instance.mesh = mesh
	mesh_instance.position = position_value
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance
