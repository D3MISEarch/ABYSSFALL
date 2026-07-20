extends Node3D
class_name RiteMarkMarker

var component: RiteMarkComponent
var glyph_label: Label3D
var brand_label: Label3D
var expiry_label: Label3D
var pulse_time := 0.0


func bind(mark_component: RiteMarkComponent, marker_height: float = 1.8) -> void:
	component = mark_component
	position = Vector3(0.0, marker_height, 0.0)
	_build_labels()
	component.state_changed.connect(_on_state_changed)
	component.brand_changed.connect(_on_brand_changed)
	component.duration_changed.connect(_on_duration_changed)
	_update_visuals()


func _process(delta: float) -> void:
	if not is_instance_valid(component):
		queue_free()
		return
	pulse_time += delta
	if is_instance_valid(glyph_label):
		var pulse := (sin(pulse_time * 5.0) + 1.0) * 0.5
		glyph_label.modulate.a = 0.84 + pulse * 0.16 if component.is_complete() else 0.92
	if is_instance_valid(brand_label) and brand_label.visible:
		brand_label.rotation.z += delta * 0.85


func _build_labels() -> void:
	glyph_label = _new_label(48, 9)
	glyph_label.name = "RiteGlyph"
	add_child(glyph_label)

	brand_label = _new_label(54, 8)
	brand_label.name = "BrandRing"
	brand_label.text = "◌"
	brand_label.modulate = Color(0.92, 0.04, 0.065, 0.92)
	brand_label.position = Vector3(0.0, 0.0, -0.005)
	add_child(brand_label)

	expiry_label = _new_label(28, 5)
	expiry_label.name = "ExpiryCrack"
	expiry_label.position = Vector3(0.0, -0.26, 0.0)
	expiry_label.modulate = Color(0.52, 0.48, 0.40, 0.78)
	add_child(expiry_label)


func _new_label(font_size: int, outline_size: int) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0024
	label.font_size = font_size
	label.outline_size = outline_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.render_priority = 6
	return label


func _update_visuals() -> void:
	if not is_instance_valid(component) or not is_instance_valid(glyph_label):
		return
	var snapshot := component.get_snapshot()
	var state := int(snapshot.get("state", 0))
	match state:
		RiteMarkComponent.STATE_PARTIAL_ONE:
			glyph_label.text = "╱"
			glyph_label.modulate = Color(0.88, 0.055, 0.07, 0.94)
		RiteMarkComponent.STATE_PARTIAL_TWO:
			glyph_label.text = "⌁"
			glyph_label.modulate = Color(0.95, 0.075, 0.075, 0.96)
		RiteMarkComponent.STATE_COMPLETE:
			glyph_label.text = "✥"
			glyph_label.modulate = Color(0.97, 0.10, 0.10, 1.0)
		_:
			glyph_label.text = ""
	brand_label.visible = bool(snapshot.get("branded", false))
	_update_expiry(float(snapshot.get("normalized_duration", 0.0)))
	visible = state != RiteMarkComponent.STATE_NONE or brand_label.visible


func _update_expiry(normalized_duration: float) -> void:
	if not is_instance_valid(expiry_label):
		return
	if normalized_duration <= 0.0 or normalized_duration > 0.34:
		expiry_label.text = ""
		return
	if normalized_duration > 0.20:
		expiry_label.text = "⌇"
	elif normalized_duration > 0.08:
		expiry_label.text = "⌇⌇"
	else:
		expiry_label.text = "×"


func _on_state_changed(_previous_state: int, _current_state: int) -> void:
	_update_visuals()


func _on_brand_changed(_active: bool) -> void:
	_update_visuals()


func _on_duration_changed(_remaining_seconds: float, total_seconds: float) -> void:
	if total_seconds <= 0.0:
		_update_expiry(0.0)
		return
	_update_expiry(_remaining_seconds / total_seconds)
