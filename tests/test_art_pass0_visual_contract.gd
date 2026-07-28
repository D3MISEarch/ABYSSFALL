extends SceneTree

const ART_PASS_SCRIPT = preload("res://scripts/art/sunken_crypts_art_pass0.gd")

var failures: Array[String] = []


func _init() -> void:
	var host := Node3D.new()
	host.name = "ArtPassHost"
	root.add_child(host)
	_install_base_visual_fixture(host)

	var art_pass := ART_PASS_SCRIPT.new() as SunkenCryptsArtPass0
	host.add_child(art_pass)
	_expect(art_pass.install(host), "Art pass should install once")
	_expect(not art_pass.install(host), "Art pass should reject duplicate installation")
	_expect(art_pass.get_node_or_null("ArtPass0_CourtyardTiles") != null, "Courtyard tiles should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_CourtyardArchitecture") != null, "Courtyard architecture should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_RestraintMachinery") != null, "Restraint machinery should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_HangingCages") != null, "Hanging cages should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_CorruptionResidue") != null, "Corruption residue should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_GeneratorChamber") != null, "Generator chamber art should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_CollapsedCatacombs") != null, "Collapsed catacombs art should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_HungryHall") != null, "Hungry hall art should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_AbyssalThrone") != null, "Abyssal throne art should exist")
	_expect(art_pass.get_node_or_null("ArtPass0_RouteLighting") != null, "Route lighting should exist")
	_expect(_count_collision_objects(art_pass) == 0, "Art pass must remain visual-only with no collision objects")
	_expect(_count_meshes(art_pass) >= 550, "Art pass should dress the complete playable route")
	_expect(_count_lights(art_pass) >= 12, "Art pass should install room-specific controlled lighting")
	for disc_name in ["RoomFoundationDisc_8", "RoomFoundationDisc_20", "RoomFoundationDisc_46", "RoomFoundationDisc_73", "RoomFoundationDisc_103"]:
		var legacy_disc := host.get_node_or_null(disc_name) as MeshInstance3D
		_expect(legacy_disc != null and not legacy_disc.visible, "%s should be hidden so new floor art can read" % disc_name)
	var legacy_light := _find_retuned_legacy_light(host)
	_expect(legacy_light != null, "Legacy room glow light should be retuned")
	if legacy_light != null:
		_expect(legacy_light.light_energy <= 0.16, "Legacy room glow should no longer dominate the courtyard")

	host.queue_free()
	if failures.is_empty():
		print("PASS: Sunken Crypts Art Pass 0 visual contract")
		quit(0)
		return
	for failure in failures:
		push_error("ASSERTION FAILED: %s" % failure)
	quit(1)


func _install_base_visual_fixture(host: Node3D) -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.environment = Environment.new()
	host.add_child(world_environment)
	var moon := DirectionalLight3D.new()
	host.add_child(moon)
	for disc_name in ["RoomFoundationDisc_8", "RoomFoundationDisc_20", "RoomFoundationDisc_46", "RoomFoundationDisc_73", "RoomFoundationDisc_103"]:
		var legacy_disc := MeshInstance3D.new()
		legacy_disc.name = disc_name
		legacy_disc.mesh = CylinderMesh.new()
		host.add_child(legacy_disc)
	var legacy_room_light := OmniLight3D.new()
	legacy_room_light.omni_range = 3.8
	legacy_room_light.light_energy = 0.72
	host.add_child(legacy_room_light)
	for body_name in ["CryptFloor", "WestOuterWall", "EastOuterWall", "SouthSeal", "NorthThroneWall", "CryptPillar_8_0"]:
		var body := StaticBody3D.new()
		body.name = body_name
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = BoxMesh.new()
		body.add_child(mesh_instance)
		host.add_child(body)


func _find_retuned_legacy_light(root_node: Node) -> OmniLight3D:
	for child: Node in root_node.get_children():
		if child is OmniLight3D and child.has_meta("art_pass0_retuned_legacy_room_light"):
			return child as OmniLight3D
	return null


func _count_collision_objects(root_node: Node) -> int:
	var count := 0
	for child: Node in root_node.get_children():
		if child is CollisionObject3D:
			count += 1
		count += _count_collision_objects(child)
	return count


func _count_meshes(root_node: Node) -> int:
	var count := 0
	for child: Node in root_node.get_children():
		if child is MeshInstance3D:
			count += 1
		count += _count_meshes(child)
	return count


func _count_lights(root_node: Node) -> int:
	var count := 0
	for child: Node in root_node.get_children():
		if child is Light3D:
			count += 1
		count += _count_lights(child)
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
