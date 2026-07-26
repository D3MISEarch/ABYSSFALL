extends Node3D
class_name SunkenCryptsArtPass0

const PALETTE = preload("res://scripts/art/abyssfall_art_palette.gd")

const COURTYARD_CENTER := Vector3(0.0, 0.0, 8.0)
const COURTYARD_MIN_X := -15.7
const COURTYARD_MAX_X := 15.7
const COURTYARD_MIN_Z := -3.8
const COURTYARD_MAX_Z := 19.0

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


func _add_box(parent: Node3D, position_value: Vector3, size_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	mesh_instance.mesh = mesh
	mesh_instance.position = position_value
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance
