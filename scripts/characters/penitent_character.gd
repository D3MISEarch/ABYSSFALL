extends "res://scripts/characters/penitent_placeholder.gd"
class_name PenitentCharacter

signal sigil_capacity_changed(active_count: int, maximum_count: int)

const FERVOR_RESOURCE_SCRIPT = preload("res://scripts/characters/penitent/fervor_resource.gd")
const RITE_MARK_SCRIPT = preload("res://scripts/characters/penitent/rite_mark_component.gd")
const RITE_MARK_MARKER_SCRIPT = preload("res://scripts/characters/penitent/rite_mark_marker.gd")
const SEAL_OF_BINDING_SCRIPT = preload("res://scripts/characters/penitent/seal_of_binding.gd")
const SIGIL_ROSTER_SCRIPT = preload("res://scripts/characters/penitent/sigil_roster.gd")
const BRAND_OF_RUIN_RULES = preload("res://scripts/characters/penitent/brand_of_ruin_rules.gd")
const RITUAL_BLADE_RULES = preload("res://scripts/characters/penitent/ritual_blade_rules.gd")

const SEAL_OF_BINDING_COST := 18.0
const SEAL_OF_BINDING_RADIUS := 3.4
const SEAL_OF_BINDING_LIFETIME := 7.0
const BRAND_OF_RUIN_COST := 12.0
const BRAND_OF_RUIN_DURATION := 10.0
const BRAND_OF_RUIN_COOLDOWN := 3.2

var fervor_component: FervorResource
var sigil_roster: SigilRoster
var ritual_blade_combo_step := 0
var ritual_blade_combo_time := 0.0
var brand_of_ruin_cooldown := 0.0
var active_brand_target: Node3D
var last_ritual_blade_result: Dictionary = {}


func _ready() -> void:
	fervor_component = FERVOR_RESOURCE_SCRIPT.new()
	fervor_component.name = "FervorResource"
	add_child(fervor_component)
	fervor_component.value_changed.connect(_on_fervor_value_changed)
	fervor_component.revelation_ready.connect(_on_revelation_ready)
	fervor_component.configure(fervor, max_fervor)

	sigil_roster = SIGIL_ROSTER_SCRIPT.new()
	sigil_roster.changed.connect(_on_sigil_roster_changed)
	sigil_roster.configure(3)

	super._ready()
	died.connect(_on_penitent_died_cleanup)


func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector3.ZERO
		return

	ritual_blade_combo_time = maxf(ritual_blade_combo_time - delta, 0.0)
	brand_of_ruin_cooldown = maxf(brand_of_ruin_cooldown - delta, 0.0)
	if ritual_blade_combo_time <= 0.0:
		ritual_blade_combo_step = 0

	attack_cooldown = maxf(attack_cooldown - delta, 0.0)
	dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
	invulnerability_time = maxf(invulnerability_time - delta, 0.0)

	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := Vector3(move_input.x, 0.0, move_input.y)
	if move_direction.length_squared() > 1.0:
		move_direction = move_direction.normalized()
	if move_direction.length_squared() > 0.01:
		facing = move_direction.normalized()
		rotation.y = atan2(-facing.x, -facing.z)

	if dodge_time > 0.0:
		dodge_time -= delta
		velocity = dodge_direction * 18.0
		move_and_slide()
		return

	if Input.is_action_just_pressed("dodge") and dodge_cooldown <= 0.0:
		dodge_direction = move_direction if move_direction.length_squared() > 0.01 else facing
		dodge_direction = dodge_direction.normalized()
		dodge_time = 0.15
		dodge_cooldown = 0.9
		invulnerability_time = 0.22
		velocity = dodge_direction * 18.0
		move_and_slide()
		return

	velocity = move_direction * move_speed
	move_and_slide()

	if Input.is_action_pressed("attack") and attack_cooldown <= 0.0:
		_perform_ritual_blade_attack()
		attack_cooldown = 0.46

	if Input.is_action_just_pressed("rift"):
		_place_seal_of_binding()


func _unhandled_input(event: InputEvent) -> void:
	if not alive or get_tree().paused:
		return
	var requested_brand := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		requested_brand = (
			key_event.pressed
			and not key_event.echo
			and (key_event.physical_keycode == KEY_F or key_event.keycode == KEY_F)
		)
	elif event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		requested_brand = button_event.pressed and button_event.button_index == JOY_BUTTON_RIGHT_STICK
	if not requested_brand:
		return
	_cast_brand_of_ruin()
	get_viewport().set_input_as_handled()


func get_health_snapshot() -> Dictionary:
	return {
		"current": health,
		"maximum": max_health,
		"alive": alive,
	}


func get_resource_snapshot() -> Dictionary:
	if is_instance_valid(fervor_component):
		return fervor_component.get_snapshot()
	return super.get_resource_snapshot()


func get_progression_snapshot() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"required_experience": experience_required,
		"pending_level_ups": pending_level_ups,
	}


func get_sigil_capacity_snapshot() -> Dictionary:
	if sigil_roster == null:
		return {"active": 0, "maximum": 3}
	return sigil_roster.get_snapshot()


func add_class_resource(amount: float) -> void:
	add_fervor(amount)


func spend_class_resource(amount: float) -> bool:
	return spend_fervor(amount)


func add_fervor(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	if is_instance_valid(fervor_component):
		fervor_component.add_fervor(amount)
	else:
		super.add_fervor(amount)


func spend_fervor(amount: float) -> bool:
	if is_instance_valid(fervor_component):
		return fervor_component.spend_fervor(amount)
	return super.spend_fervor(amount)


func set_combat_active(is_active: bool) -> void:
	if is_instance_valid(fervor_component):
		fervor_component.set_combat_active(is_active)


func quote_sacrament_cost(cost: float) -> Dictionary:
	if not is_instance_valid(fervor_component):
		return {"can_cast": false}
	return fervor_component.quote_sacrament_cost(cost, health, max_health)


func commit_sacrament_cost(cost: float) -> Dictionary:
	if not is_instance_valid(fervor_component):
		return {"can_cast": false}
	var quote := fervor_component.commit_sacrament_cost(cost, health, max_health)
	if not bool(quote.get("can_cast", false)):
		return quote
	var health_cost := int(quote.get("health_cost", 0))
	if health_cost > 0:
		health = maxi(health - health_cost, 1)
		health_changed.emit(health, max_health)
	return quote


func apply_brand_to_target(target: Node3D, duration: float = 10.0) -> Dictionary:
	var mark := get_or_create_rite_mark(target)
	if not is_instance_valid(mark):
		return {}
	mark.apply_brand(duration)
	return mark.get_snapshot()


func get_rite_mark_snapshot(target: Node3D) -> Dictionary:
	if not is_instance_valid(target):
		return {}
	var mark := target.get_node_or_null("RiteMark") as RiteMarkComponent
	return mark.get_snapshot() if is_instance_valid(mark) else {}


func get_or_create_rite_mark(target: Node3D) -> RiteMarkComponent:
	if not is_instance_valid(target):
		return null
	var existing := target.get_node_or_null("RiteMark") as RiteMarkComponent
	if is_instance_valid(existing):
		return existing

	var mark := RITE_MARK_SCRIPT.new() as RiteMarkComponent
	mark.name = "RiteMark"
	target.add_child(mark)
	var is_boss := target.has_signal("phase_changed") or target.name == "TheHollowKing"
	mark.configure(6.0, 8.0, is_boss)

	var marker := RITE_MARK_MARKER_SCRIPT.new() as RiteMarkMarker
	marker.name = "RiteMarkMarker"
	target.add_child(marker)
	marker.bind(mark, 3.4 if is_boss else 1.9)
	return mark


func _perform_ritual_blade_attack() -> void:
	ritual_blade_combo_step = ritual_blade_combo_step % 3 + 1
	ritual_blade_combo_time = 1.05
	var step_distance := _apply_ritual_blade_step_in()
	var hit_count := 0
	var completed_count := 0
	var echo_count := 0
	var damage: int = RITUAL_BLADE_RULES.get_damage(ritual_blade_combo_step)

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue
		if not RITUAL_BLADE_RULES.is_target_in_arc(
			global_position,
			facing,
			enemy.global_position
		):
			continue

		var mark_before := enemy.get_node_or_null("RiteMark") as RiteMarkComponent
		var was_branded := is_instance_valid(mark_before) and mark_before.branded
		enemy.take_damage(damage)
		hit_count += 1
		_spawn_ritual_blade_hit(enemy)
		var mark := get_or_create_rite_mark(enemy)
		if not is_instance_valid(mark):
			continue
		var became_complete := false
		if ritual_blade_combo_step == 3:
			became_complete = mark.complete_rite()
		else:
			var previous_state := mark.current_state
			mark.apply_partial(1)
			became_complete = (
				previous_state != RiteMarkComponent.STATE_COMPLETE
				and mark.current_state == RiteMarkComponent.STATE_COMPLETE
			)
		if became_complete:
			completed_count += 1
		if was_branded:
			echo_count += _echo_brand_damage(enemy, damage)

	set_combat_active(true)
	_spawn_ritual_blade_arc(hit_count)
	last_ritual_blade_result = {
		"combo_step": ritual_blade_combo_step,
		"hits": hit_count,
		"completed_rites": completed_count,
		"echoes": echo_count,
		"damage": damage,
		"step_distance": step_distance,
		"reach": RITUAL_BLADE_RULES.REACH,
	}

	if completed_count > 0:
		add_fervor(minf(float(completed_count) * 6.0, 18.0))
		ability_message.emit("RITE COMPLETE" if completed_count == 1 else "%d RITES COMPLETE" % completed_count)
	elif echo_count > 0:
		ability_message.emit("BRAND OF RUIN ECHOES THROUGH %d MARKS" % echo_count)
	elif hit_count > 0 and ritual_blade_combo_step == 3:
		ability_message.emit("RITUAL BLADE — THIRD CONFESSION")

	if is_instance_valid(visual_root):
		var tween := create_tween()
		var attack_scale := Vector3(1.24, 0.86, 1.24) if ritual_blade_combo_step == 3 else Vector3(1.14, 0.92, 1.14)
		tween.tween_property(visual_root, "scale", attack_scale, 0.055)
		tween.tween_property(visual_root, "scale", Vector3.ONE, 0.13)


func get_ritual_blade_snapshot() -> Dictionary:
	return last_ritual_blade_result.duplicate(true)


func _apply_ritual_blade_step_in() -> float:
	var target := _select_ritual_blade_step_target()
	if not is_instance_valid(target):
		return 0.0
	var step_distance: float = RITUAL_BLADE_RULES.get_step_in_distance(
		global_position,
		facing,
		target.global_position
	)
	if step_distance <= 0.0:
		return 0.0
	var flat_facing := facing
	flat_facing.y = 0.0
	if flat_facing.length_squared() <= 0.001:
		return 0.0
	flat_facing = flat_facing.normalized()
	var starting_position := global_position
	move_and_collide(flat_facing * step_distance)
	var travelled := global_position - starting_position
	travelled.y = 0.0
	return travelled.length()


func _select_ritual_blade_step_target() -> Node3D:
	var best_target: Node3D
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node3D
		if not is_instance_valid(enemy):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue
		if not RITUAL_BLADE_RULES.is_target_in_arc(
			global_position,
			facing,
			enemy.global_position,
			RITUAL_BLADE_RULES.REACH + RITUAL_BLADE_RULES.STEP_IN_DISTANCE,
			RITUAL_BLADE_RULES.HALF_ANGLE_DEGREES
		):
			continue
		var flat_offset := enemy.global_position - global_position
		flat_offset.y = 0.0
		var distance := flat_offset.length()
		if distance < best_distance:
			best_distance = distance
			best_target = enemy
	return best_target


func _spawn_ritual_blade_arc(hit_count: int) -> void:
	var scene_root := get_tree().current_scene as Node3D
	if not is_instance_valid(scene_root):
		scene_root = get_parent() as Node3D
	if not is_instance_valid(scene_root):
		return

	var arc_root := Node3D.new()
	arc_root.name = "RitualBladeArc"
	var spawn_global := global_position + Vector3(0.0, 0.16, 0.0)
	arc_root.position = scene_root.to_local(spawn_global)
	arc_root.rotation.y = atan2(-facing.x, -facing.z)
	arc_root.scale = Vector3(0.72, 0.72, 0.72)

	var color := Color(0.82, 0.025, 0.045)
	if ritual_blade_combo_step == 2:
		color = Color(0.98, 0.13, 0.035)
	elif ritual_blade_combo_step == 3:
		color = Color(0.34, 0.92, 0.055)
	if hit_count <= 0:
		color = color.darkened(0.18)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.72)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color * 3.0
	material.emission_energy_multiplier = 2.6

	var segment_count := 11
	var half_angle := deg_to_rad(RITUAL_BLADE_RULES.HALF_ANGLE_DEGREES)
	var arc_radius := 2.55 if ritual_blade_combo_step == 3 else 2.30
	for index in range(segment_count):
		var ratio := float(index) / float(segment_count - 1)
		var angle := lerpf(-half_angle, half_angle, ratio)
		var segment := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.58 if ritual_blade_combo_step == 3 else 0.48, 0.045, 0.15)
		segment.mesh = mesh
		segment.position = Vector3(sin(angle) * arc_radius, 0.0, -cos(angle) * arc_radius)
		segment.rotation.y = -angle
		segment.material_override = material
		arc_root.add_child(segment)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.55, -1.7)
	light.light_color = color
	light.light_energy = 1.25 if hit_count > 0 else 0.72
	light.omni_range = 4.2
	arc_root.add_child(light)

	# The arc has no _ready() gameplay work, but its transform is still assigned
	# before attachment to preserve the project's scene-tree ordering rule.
	scene_root.add_child(arc_root)
	var tween := arc_root.create_tween()
	tween.set_parallel(true)
	tween.tween_property(arc_root, "scale", Vector3(1.08, 1.0, 1.08), 0.16)
	tween.tween_property(arc_root, "rotation:y", arc_root.rotation.y + 0.18, 0.16)
	tween.chain().tween_callback(arc_root.queue_free)


func _spawn_ritual_blade_hit(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	var pulse := MeshInstance3D.new()
	pulse.name = "RitualBladeHit"
	var sphere := SphereMesh.new()
	sphere.radius = 0.38 if ritual_blade_combo_step < 3 else 0.52
	sphere.height = sphere.radius * 2.0
	pulse.mesh = sphere
	pulse.position = Vector3(0.0, 0.62, 0.0)
	pulse.scale = Vector3.ONE * 0.35
	var color := Color(0.90, 0.035, 0.055) if ritual_blade_combo_step < 3 else Color(0.34, 0.94, 0.055)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.62)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = color * 3.2
	material.emission_energy_multiplier = 2.8
	pulse.material_override = material
	target.add_child(pulse)
	var tween := pulse.create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3.ONE * 1.35, 0.18)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(pulse.queue_free)


func _cast_brand_of_ruin() -> void:
	if brand_of_ruin_cooldown > 0.0:
		ability_message.emit("BRAND OF RUIN REFORMS IN %.1f" % brand_of_ruin_cooldown)
		return
	var target := _select_brand_target()
	if not is_instance_valid(target):
		ability_message.emit("BRAND OF RUIN FINDS NO VESSEL")
		return
	if not spend_fervor(BRAND_OF_RUIN_COST):
		ability_message.emit("BRAND OF RUIN REQUIRES %d FERVOR" % int(BRAND_OF_RUIN_COST))
		return

	if is_instance_valid(active_brand_target) and active_brand_target != target:
		var old_mark := active_brand_target.get_node_or_null("RiteMark") as RiteMarkComponent
		if is_instance_valid(old_mark):
			old_mark.remove_brand()

	apply_brand_to_target(target, BRAND_OF_RUIN_DURATION)
	active_brand_target = target
	brand_of_ruin_cooldown = BRAND_OF_RUIN_COOLDOWN
	set_combat_active(true)
	_spawn_brand_pulse(target, Color(0.82, 0.025, 0.045), 1.65)
	ability_message.emit("BRAND OF RUIN — %s IS WRITTEN" % target.name.to_upper())


func _select_brand_target() -> Node3D:
	var best_target: Node3D
	var best_score := -1.0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node3D
		if not is_instance_valid(enemy):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue
		var score: float = BRAND_OF_RUIN_RULES.score_target(
			global_position,
			facing,
			enemy.global_position
		)
		if score < 0.0:
			continue
		var mark := enemy.get_node_or_null("RiteMark") as RiteMarkComponent
		if is_instance_valid(mark) and mark.current_state != RiteMarkComponent.STATE_NONE:
			score += 0.22
		if score > best_score:
			best_score = score
			best_target = enemy
	return best_target


func _echo_brand_damage(primary: Node3D, base_damage: int) -> int:
	if not is_instance_valid(primary):
		return 0
	var echo_damage: int = BRAND_OF_RUIN_RULES.calculate_echo_damage(base_damage)
	var echoed := 0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		var enemy := candidate as Node3D
		if enemy == primary or not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		if enemy.get("alive") != null and not bool(enemy.get("alive")):
			continue
		if not BRAND_OF_RUIN_RULES.can_echo_between(primary.global_position, enemy.global_position):
			continue
		var mark := enemy.get_node_or_null("RiteMark") as RiteMarkComponent
		if not is_instance_valid(mark) or mark.current_state == RiteMarkComponent.STATE_NONE:
			continue
		enemy.take_damage(echo_damage)
		_spawn_brand_pulse(enemy, Color(0.31, 0.88, 0.055), 0.92)
		echoed += 1
		if echoed >= BRAND_OF_RUIN_RULES.MAX_ECHO_TARGETS:
			break
	if echoed > 0:
		add_fervor(minf(float(echoed) * 1.5, 6.0))
	return echoed


func _spawn_brand_pulse(target: Node3D, color: Color, maximum_scale: float) -> void:
	if not is_instance_valid(target):
		return
	var pulse := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.34
	sphere.height = 0.68
	pulse.mesh = sphere
	pulse.position = Vector3(0.0, 0.55, 0.0)
	pulse.scale = Vector3(0.25, 0.25, 0.25)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 0.46)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color * 2.8
	material.emission_energy_multiplier = 2.5
	pulse.material_override = material
	target.add_child(pulse)
	var tween := pulse.create_tween()
	tween.set_parallel(true)
	tween.tween_property(pulse, "scale", Vector3.ONE * maximum_scale, 0.24)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(pulse.queue_free)


func _place_seal_of_binding() -> void:
	if not spend_fervor(SEAL_OF_BINDING_COST):
		ability_message.emit("SEAL OF BINDING REQUIRES %d FERVOR" % int(SEAL_OF_BINDING_COST))
		return

	var scene_root := get_tree().current_scene as Node3D
	if not is_instance_valid(scene_root):
		scene_root = get_parent() as Node3D
	if not is_instance_valid(scene_root):
		add_fervor(SEAL_OF_BINDING_COST)
		ability_message.emit("SEAL OF BINDING FINDS NO GROUND")
		return

	var seal := SEAL_OF_BINDING_SCRIPT.new() as SealOfBinding
	seal.name = "SealOfBinding"
	seal.configure(self, SEAL_OF_BINDING_RADIUS, SEAL_OF_BINDING_LIFETIME)
	seal.expired.connect(_on_seal_expired)

	# SealOfBinding performs its first pulse in _ready(). Assign its local
	# transform before add_child() so that pulse occurs at the intended point,
	# never at world origin for one frame. This is the canonical implementation
	# inherited by every playable Penitent variant.
	var spawn_global := global_position + facing * 3.0
	spawn_global.y = 0.07
	seal.position = scene_root.to_local(spawn_global)
	scene_root.add_child(seal)

	var evicted := sigil_roster.register(seal)
	if is_instance_valid(evicted) and evicted.has_method("dismiss"):
		evicted.dismiss("replaced")
	set_combat_active(true)
	ability_message.emit("SEAL OF BINDING CARVED")


func _on_seal_expired(seal: Node, _reason: String) -> void:
	if sigil_roster != null:
		sigil_roster.remove(seal)


func _on_sigil_roster_changed(active_count: int, maximum_count: int) -> void:
	sigil_capacity_changed.emit(active_count, maximum_count)


func _on_penitent_died_cleanup() -> void:
	if is_instance_valid(active_brand_target):
		var mark := active_brand_target.get_node_or_null("RiteMark") as RiteMarkComponent
		if is_instance_valid(mark):
			mark.remove_brand()
	active_brand_target = null
	if sigil_roster == null:
		return
	for sigil in sigil_roster.clear():
		if is_instance_valid(sigil) and sigil.has_method("dismiss"):
			sigil.dismiss("caster_fallen")


func _on_fervor_value_changed(current_value: float, maximum_value: float) -> void:
	fervor = current_value
	max_fervor = maximum_value
	resource_changed.emit(RESOURCE_ID, RESOURCE_DISPLAY_NAME, current_value, maximum_value)


func _on_revelation_ready() -> void:
	ability_message.emit("REVELATION READY — THE LAST RITE AWAITS")
