extends Node3D
class_name MartyrsChainVisual

var source: Node3D
var target: Node3D
var links: Array[MeshInstance3D] = []
var active := true
var pulse_time := 0.0


func bind(new_source: Node3D, new_target: Node3D, complete_rite: bool = false) -> void:
	source = new_source
	target = new_target
	top_level = true
	_build_links(complete_rite)


func _process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(source) or not is_instance_valid(target):
		dismiss()
		return
	pulse_time += delta
	_update_links()


func dismiss() -> void:
	if not active:
		return
	active = false
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.10)
	tween.tween_callback(queue_free)


func _build_links(complete_rite: bool) -> void:
	var chain_color := Color(0.72, 0.018, 0.028) if not complete_rite else Color(0.34, 0.88, 0.055)
	var material := StandardMaterial3D.new()
	material.albedo_color = chain_color
	material.metallic = 0.72
	material.roughness = 0.34
	material.emission_enabled = true
	material.emission = chain_color * 2.4
	material.emission_energy_multiplier = 2.0

	for index in range(13):
		var link := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.12, 0.08, 0.26)
		link.mesh = mesh
		link.material_override = material
		add_child(link)
		links.append(link)
	_update_links()


func _update_links() -> void:
	if links.is_empty():
		return
	var start := source.global_position + Vector3(0.0, 0.75, 0.0)
	var finish := target.global_position + Vector3(0.0, 0.72, 0.0)
	var direction := finish - start
	var length := direction.length()
	if length <= 0.01:
		return
	var yaw := atan2(-direction.x, -direction.z)
	var pitch := asin(clampf(direction.y / length, -1.0, 1.0))
	for index in range(links.size()):
		var t := (float(index) + 0.5) / float(links.size())
		var sag := sin(t * PI) * minf(length * 0.08, 0.42)
		var link := links[index]
		link.global_position = start.lerp(finish, t) + Vector3(0.0, -sag, 0.0)
		link.global_rotation = Vector3(pitch, yaw, sin(pulse_time * 8.0 + float(index)) * 0.18)
		var pulse := 1.0 + sin(pulse_time * 10.0 + float(index) * 0.65) * 0.12
		link.scale = Vector3.ONE * pulse
