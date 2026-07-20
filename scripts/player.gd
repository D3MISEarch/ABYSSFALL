extends CharacterBody3D

signal health_changed(current_health: int, maximum_health: int)
signal corruption_changed(current_corruption: float, maximum_corruption: float)
signal experience_changed(current_level: int, current_xp: int, required_xp: int)
signal level_up_requested
signal inventory_changed
signal skill_tree_changed
signal died
signal ability_message(message: String)
signal loot_message(message: String)

const VOID_BOLT_SCRIPT = preload("res://scripts/void_bolt.gd")
const GRASPING_RIFT_SCRIPT = preload("res://scripts/grasping_rift.gd")

const EQUIPMENT_SLOTS := ["Weapon", "Hood", "Chest", "Gloves", "Boots", "Relic"]
const MAX_BACKPACK_SIZE := 12

const SKILL_BRANCHES := {
	"Abyss":
	[
		{
			"id": "void_training",
			"name": "Void Training",
			"description": "+4 Void Bolt damage.",
			"icon": "◆"
		},
		{
			"id": "rift_expansion",
			"name": "Rift Expansion",
			"description": "+1.1m Grasping Rift radius.",
			"icon": "◉"
		},
		{
			"id": "gravitic_pull",
			"name": "Gravitic Pull",
			"description": "+22% Rift pull strength.",
			"icon": "↯"
		},
		{
			"id": "lingering_void",
			"name": "Lingering Void",
			"description": "Rifts pull for 0.65s longer.",
			"icon": "◌"
		},
		{
			"id": "unstable_break",
			"name": "Unstable Break",
			"description": "+14 Rift collapse damage.",
			"icon": "✦"
		},
		{
			"id": "abyssal_maelstrom",
			"name": "Abyssal Maelstrom",
			"description": "CAPSTONE: Grasping Rift tears open two linked voids.",
			"icon": "☯"
		}
	],
	"Corruption":
	[
		{
			"id": "corruption_affinity",
			"name": "Corruption Affinity",
			"description": "+20% Corruption gained from souls.",
			"icon": "♢"
		},
		{
			"id": "festering_veins",
			"name": "Festering Veins",
			"description": "+20 maximum Corruption.",
			"icon": "⌁"
		},
		{
			"id": "explosive_bolts",
			"name": "Explosive Bolts",
			"description": "At 65% Corruption, Void Bolts burst on impact.",
			"icon": "✹"
		},
		{
			"id": "infected_step",
			"name": "Infected Step",
			"description": "Shadow Step damages enemies at its starting point.",
			"icon": "➳"
		},
		{
			"id": "ravenous_hunger",
			"name": "Ravenous Hunger",
			"description": "Kills restore Life while Corruption is above 60%.",
			"icon": "♧"
		},
		{
			"id": "apotheosis",
			"name": "Apotheosis",
			"description": "CAPSTONE: Full Corruption greatly empowers damage and speed.",
			"icon": "♛"
		}
	],
	"Soulbinding":
	[
		{
			"id": "soul_harvest",
			"name": "Soul Harvest",
			"description": "+18% chance for enemies to drop extra loot.",
			"icon": "◇"
		},
		{
			"id": "soul_sap",
			"name": "Soul Sap",
			"description": "Collecting a soul restores 2 Life.",
			"icon": "♥"
		},
		{
			"id": "empowered_souls",
			"name": "Empowered Souls",
			"description": "Each soul grants +4 additional Corruption.",
			"icon": "✧"
		},
		{
			"id": "soul_detonation",
			"name": "Soul Detonation",
			"description": "Killed enemies damage nearby enemies.",
			"icon": "☀"
		},
		{
			"id": "grim_bargain",
			"name": "Grim Bargain",
			"description": "+24 maximum Life, but -10 maximum Corruption.",
			"icon": "⚖"
		},
		{
			"id": "legion_damned",
			"name": "Legion of the Damned",
			"description": "CAPSTONE: Kills can summon a temporary Bound Wretch.",
			"icon": "♞"
		}
	]
}

# Baseline combat values.
var max_health := 100
var health := 100
var move_speed := 7.2
var fire_interval := 0.18
var bolt_damage := 18
var bolt_speed := 22.0
var max_corruption := 100.0
var corruption := 28.0
var rift_cost := 40.0
var rift_cooldown_duration := 4.5
var rift_radius := 6.0
var rift_duration := 2.2
var rift_pull_strength := 7.4
var rift_damage := 30

# Progression.
var level := 1
var experience := 0
var experience_required := 70
var pending_level_ups := 0
var level_up_in_progress := false
var branch_progress := {"Abyss": 0, "Corruption": 0, "Soulbinding": 0}

# Skill and item-derived modifiers.
var skill_bolt_damage_bonus := 0
var skill_rift_radius_bonus := 0.0
var skill_rift_duration_bonus := 0.0
var skill_rift_pull_multiplier := 1.0
var skill_rift_damage_bonus := 0
var skill_max_corruption_bonus := 0.0
var skill_max_health_bonus := 0
var skill_corruption_gain_multiplier := 1.0
var skill_soul_bonus := 0.0
var skill_soul_heal := 0
var skill_item_drop_bonus := 0.0
var soul_detonation_damage := 0
var explosive_bolts := false
var infected_step := false
var ravenous_hunger := false
var apotheosis := false
var dual_rift := false
var summon_wretch_chance := 0.0

var corruption_gain_multiplier := 1.0
var soul_bonus := 0.0
var soul_heal := 0
var item_drop_bonus := 0.0
var equipment := {"Weapon": {}, "Hood": {}, "Chest": {}, "Gloves": {}, "Boots": {}, "Relic": {}}
var backpack: Array = []

# Runtime state.
var facing := Vector3(0.0, 0.0, -1.0)
var fire_timer := 0.0
var dodge_cooldown := 0.0
var dodge_time := 0.0
var invulnerability_time := 0.0
var rift_cooldown := 0.0
var dodge_direction := Vector3.ZERO
var alive := true
var visual_root: Node3D
var left_hand: MeshInstance3D
var right_hand: MeshInstance3D


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 5
	_build_visual()
	_recalculate_stats(false)
	corruption_changed.emit(corruption, max_corruption)
	experience_changed.emit(level, experience, experience_required)


func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector3.ZERO
		return

	fire_timer = maxf(fire_timer - delta, 0.0)
	dodge_cooldown = maxf(dodge_cooldown - delta, 0.0)
	invulnerability_time = maxf(invulnerability_time - delta, 0.0)
	rift_cooldown = maxf(rift_cooldown - delta, 0.0)

	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_direction := Vector3(move_input.x, 0.0, move_input.y)
	if move_direction.length_squared() > 1.0:
		move_direction = move_direction.normalized()

	_update_aim(move_direction)

	if dodge_time > 0.0:
		dodge_time -= delta
		velocity = dodge_direction * 19.0
		move_and_slide()
		return

	if Input.is_action_just_pressed("dodge") and dodge_cooldown <= 0.0:
		var dash_origin := global_position
		dodge_direction = move_direction if move_direction.length_squared() > 0.01 else facing
		dodge_direction = dodge_direction.normalized()
		dodge_time = 0.16
		dodge_cooldown = 0.85
		invulnerability_time = 0.24
		velocity = dodge_direction * 19.0
		if infected_step:
			_damage_enemies_around(dash_origin, 2.15, 20)
		move_and_slide()
		_pulse_shadow_step()
		return

	var current_move_speed := move_speed
	if apotheosis and corruption >= max_corruption * 0.98:
		current_move_speed *= 1.20
	velocity = move_direction * current_move_speed
	move_and_slide()

	if Input.is_action_pressed("attack") and fire_timer <= 0.0:
		_cast_void_bolt()
		fire_timer = fire_interval

	if Input.is_action_just_pressed("rift"):
		_try_cast_grasping_rift()


func _update_aim(move_direction: Vector3) -> void:
	var stick_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick_aim.length() > 0.28:
		facing = Vector3(stick_aim.x, 0.0, stick_aim.y).normalized()
	else:
		var mouse_point := _mouse_ground_point()
		if mouse_point != Vector3.INF:
			var mouse_direction := mouse_point - global_position
			mouse_direction.y = 0.0
			if mouse_direction.length_squared() > 0.04:
				facing = mouse_direction.normalized()
		elif move_direction.length_squared() > 0.01:
			facing = move_direction.normalized()
	rotation.y = atan2(-facing.x, -facing.z)


func _mouse_ground_point() -> Vector3:
	var active_camera := get_viewport().get_camera_3d()
	if not is_instance_valid(active_camera):
		return Vector3.INF
	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := active_camera.project_ray_origin(mouse_position)
	var ray_direction := active_camera.project_ray_normal(mouse_position)
	var aim_plane := Plane(Vector3.UP, global_position.y)
	var hit_position = aim_plane.intersects_ray(ray_origin, ray_direction)
	if hit_position == null:
		return Vector3.INF
	return hit_position


func _cast_void_bolt() -> void:
	var damage_value := bolt_damage
	if apotheosis and corruption >= max_corruption * 0.98:
		damage_value = int(round(float(damage_value) * 1.38))
	var splash_radius := 0.0
	var splash_damage := 0
	if explosive_bolts and corruption >= max_corruption * 0.65:
		splash_radius = 2.1
		splash_damage = int(round(float(damage_value) * 0.52))

	var bolt := VOID_BOLT_SCRIPT.new()
	get_tree().current_scene.add_child(bolt)
	bolt.global_position = global_position + facing * 1.05 + Vector3(0.0, 0.34, 0.0)
	bolt.setup(facing, bolt_speed, damage_value, self, splash_radius, splash_damage)

	if is_instance_valid(visual_root):
		var tween := create_tween()
		tween.tween_property(visual_root, "scale", Vector3(1.08, 1.08, 1.08), 0.045)
		tween.tween_property(visual_root, "scale", Vector3.ONE, 0.075)


func _try_cast_grasping_rift() -> void:
	if rift_cooldown > 0.0:
		ability_message.emit("THE RIFT IS STILL FEEDING")
		return
	if corruption < rift_cost:
		ability_message.emit("THE ABYSS HUNGERS — NEED %d CORRUPTION" % int(rift_cost))
		return

	var target_position := global_position + facing * 6.0
	var stick_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick_aim.length() <= 0.28:
		var mouse_point := _mouse_ground_point()
		if mouse_point != Vector3.INF:
			target_position = mouse_point

	var offset := target_position - global_position
	offset.y = 0.0
	if offset.length() > 8.5:
		offset = offset.normalized() * 8.5
	if offset.length() < 2.0:
		offset = facing * 2.0
	target_position = global_position + offset
	target_position.y = 0.08

	spend_corruption(rift_cost)
	rift_cooldown = rift_cooldown_duration

	if dual_rift:
		var perpendicular := Vector3(-facing.z, 0.0, facing.x).normalized()
		_spawn_rift(target_position + perpendicular * 1.9, 0.82, 0.78)
		_spawn_rift(target_position - perpendicular * 1.9, 0.82, 0.78)
	else:
		_spawn_rift(target_position, 1.0, 1.0)
	_cast_pulse()


func _spawn_rift(
	target_position: Vector3, size_multiplier: float, damage_multiplier: float
) -> void:
	var rift := GRASPING_RIFT_SCRIPT.new()
	rift.setup(
		self,
		rift_radius * size_multiplier,
		rift_duration,
		rift_pull_strength,
		int(round(float(rift_damage) * damage_multiplier)),
		size_multiplier
	)
	get_tree().current_scene.add_child(rift)
	rift.global_position = target_position


func add_corruption(amount: float) -> void:
	if not alive:
		return
	corruption = clampf(corruption + amount * corruption_gain_multiplier, 0.0, max_corruption)
	corruption_changed.emit(corruption, max_corruption)


func collect_soul(amount: float, rare: bool = false) -> void:
	add_corruption(amount + soul_bonus)
	if soul_heal > 0:
		heal(soul_heal + (1 if rare else 0))
	add_experience(8 if rare else 4)


func spend_corruption(amount: float) -> bool:
	if corruption < amount:
		return false
	corruption = maxf(corruption - amount, 0.0)
	corruption_changed.emit(corruption, max_corruption)
	return true


func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	while experience >= experience_required:
		experience -= experience_required
		level += 1
		experience_required = int(round(70.0 + pow(float(level - 1), 1.28) * 42.0))
		pending_level_ups += 1
	experience_changed.emit(level, experience, experience_required)
	if pending_level_ups > 0 and not level_up_in_progress:
		level_up_in_progress = true
		level_up_requested.emit()


func get_level_up_choices() -> Array:
	var choices: Array = []
	for branch_name in ["Abyss", "Corruption", "Soulbinding"]:
		var tier: int = int(branch_progress[branch_name])
		var branch: Array = SKILL_BRANCHES[branch_name]
		if tier < branch.size():
			var choice: Dictionary = branch[tier].duplicate(true)
			choice["branch"] = branch_name
			choice["tier"] = tier + 1
			choices.append(choice)
		else:
			choices.append(
				{
					"id": "mastery_" + branch_name.to_lower(),
					"name": branch_name + " Mastery",
					"description": "+5% damage and +5 maximum Life.",
					"icon": "✥",
					"branch": branch_name,
					"tier": tier + 1
				}
			)
	return choices


func apply_level_up_choice(choice: Dictionary) -> void:
	var branch_name: String = str(choice.get("branch", "Abyss"))
	var skill_id: String = str(choice.get("id", ""))
	if skill_id.begins_with("mastery_"):
		skill_bolt_damage_bonus += 1
		skill_rift_damage_bonus += 2
		skill_max_health_bonus += 5
	else:
		branch_progress[branch_name] = int(branch_progress[branch_name]) + 1
		_apply_skill_effect(skill_id)
	_recalculate_stats(true)
	pending_level_ups = maxi(pending_level_ups - 1, 0)
	level_up_in_progress = pending_level_ups > 0
	skill_tree_changed.emit()
	experience_changed.emit(level, experience, experience_required)
	if pending_level_ups > 0:
		level_up_requested.emit()


func _apply_skill_effect(skill_id: String) -> void:
	match skill_id:
		"void_training":
			skill_bolt_damage_bonus += 4
		"rift_expansion":
			skill_rift_radius_bonus += 1.1
		"gravitic_pull":
			skill_rift_pull_multiplier *= 1.22
		"lingering_void":
			skill_rift_duration_bonus += 0.65
		"unstable_break":
			skill_rift_damage_bonus += 14
		"abyssal_maelstrom":
			dual_rift = true
		"corruption_affinity":
			skill_corruption_gain_multiplier += 0.20
		"festering_veins":
			skill_max_corruption_bonus += 20.0
		"explosive_bolts":
			explosive_bolts = true
		"infected_step":
			infected_step = true
		"ravenous_hunger":
			ravenous_hunger = true
		"apotheosis":
			apotheosis = true
		"soul_harvest":
			skill_item_drop_bonus += 0.18
		"soul_sap":
			skill_soul_heal += 2
		"empowered_souls":
			skill_soul_bonus += 4.0
		"soul_detonation":
			soul_detonation_damage = 16
		"grim_bargain":
			skill_max_health_bonus += 24
			skill_max_corruption_bonus -= 10.0
		"legion_damned":
			summon_wretch_chance = 0.28


func get_skill_tree_snapshot() -> Dictionary:
	return {"progress": branch_progress.duplicate(true), "branches": SKILL_BRANCHES, "level": level}


func add_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	var item_copy := item.duplicate(true)
	var slot: String = str(item_copy.get("slot", "Relic"))
	if not EQUIPMENT_SLOTS.has(slot):
		slot = "Relic"
		item_copy["slot"] = slot

	if equipment[slot].is_empty():
		equipment[slot] = item_copy
		_recalculate_stats(true)
		loot_message.emit("EQUIPPED: %s" % str(item_copy.get("name", "Unknown Relic")))
	elif backpack.size() < MAX_BACKPACK_SIZE:
		backpack.append(item_copy)
		loot_message.emit("LOOT: %s — PRESS I" % str(item_copy.get("name", "Unknown Relic")))
	else:
		add_experience(24)
		loot_message.emit("BACKPACK FULL — ITEM CONSUMED FOR SOUL XP")
	inventory_changed.emit()


func equip_inventory_index(index: int) -> void:
	if index < 0 or index >= backpack.size():
		return
	var new_item: Dictionary = backpack[index]
	var slot: String = str(new_item.get("slot", "Relic"))
	var old_item: Dictionary = equipment[slot]
	equipment[slot] = new_item
	if old_item.is_empty():
		backpack.remove_at(index)
	else:
		backpack[index] = old_item
	_recalculate_stats(true)
	inventory_changed.emit()
	loot_message.emit("EQUIPPED: %s" % str(new_item.get("name", "Unknown Relic")))


func get_inventory_snapshot() -> Dictionary:
	return {
		"equipment": equipment.duplicate(true),
		"backpack": backpack.duplicate(true),
		"capacity": MAX_BACKPACK_SIZE
	}


func _recalculate_stats(preserve_current: bool) -> void:
	var old_max_health := max_health
	var old_max_corruption := max_corruption

	max_health = 100 + skill_max_health_bonus
	move_speed = 7.2
	fire_interval = 0.18
	bolt_damage = 18 + skill_bolt_damage_bonus
	bolt_speed = 22.0
	max_corruption = maxf(40.0, 100.0 + skill_max_corruption_bonus)
	rift_radius = 6.0 + skill_rift_radius_bonus
	rift_duration = 2.2 + skill_rift_duration_bonus
	rift_pull_strength = 7.4 * skill_rift_pull_multiplier
	rift_damage = 30 + skill_rift_damage_bonus
	corruption_gain_multiplier = skill_corruption_gain_multiplier
	soul_bonus = skill_soul_bonus
	soul_heal = skill_soul_heal
	item_drop_bonus = skill_item_drop_bonus

	for slot in EQUIPMENT_SLOTS:
		var item: Dictionary = equipment[slot]
		if item.is_empty():
			continue
		var stats: Dictionary = item.get("stats", {})
		max_health += int(stats.get("max_health", 0))
		max_corruption += float(stats.get("max_corruption", 0.0))
		move_speed += float(stats.get("move_speed", 0.0))
		fire_interval -= float(stats.get("fire_interval_reduction", 0.0))
		bolt_damage += int(stats.get("bolt_damage", 0))
		bolt_speed += float(stats.get("bolt_speed", 0.0))
		rift_radius += float(stats.get("rift_radius", 0.0))
		rift_damage += int(stats.get("rift_damage", 0))
		corruption_gain_multiplier += float(stats.get("corruption_gain_multiplier", 0.0))
		soul_heal += int(stats.get("soul_heal", 0))
		item_drop_bonus += float(stats.get("item_drop_bonus", 0.0))

	fire_interval = maxf(fire_interval, 0.085)
	if preserve_current:
		if max_health > old_max_health:
			health += max_health - old_max_health
		if max_corruption > old_max_corruption:
			corruption += max_corruption - old_max_corruption
	health = clampi(health, 0, max_health)
	corruption = clampf(corruption, 0.0, max_corruption)
	health_changed.emit(health, max_health)
	corruption_changed.emit(corruption, max_corruption)


func get_item_drop_bonus() -> float:
	return item_drop_bonus


func get_soul_detonation_damage() -> int:
	return soul_detonation_damage


func get_summon_wretch_chance() -> float:
	return summon_wretch_chance


func on_enemy_killed() -> void:
	if ravenous_hunger and corruption >= max_corruption * 0.60:
		heal(3)


func heal(amount: int) -> void:
	if not alive or amount <= 0:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func take_damage(amount: int) -> void:
	if not alive or invulnerability_time > 0.0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	_damage_flash()
	if health <= 0:
		alive = false
		collision_layer = 0
		collision_mask = 0
		died.emit()
		var tween := create_tween()
		tween.tween_property(visual_root, "scale", Vector3(0.05, 0.05, 0.05), 0.55).set_trans(
			Tween.TRANS_BACK
		)


func _damage_enemies_around(center: Vector3, radius: float, damage: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var offset: Vector3 = enemy.global_position - center
		offset.y = 0.0
		if offset.length() <= radius:
			enemy.take_damage(damage)


func _pulse_shadow_step() -> void:
	if not is_instance_valid(visual_root):
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(0.62, 1.35, 0.62), 0.07)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_BACK)


func _cast_pulse() -> void:
	if not is_instance_valid(visual_root):
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.22, 0.88, 1.22), 0.08)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _damage_flash() -> void:
	if not is_instance_valid(visual_root):
		return
	var tween := create_tween()
	tween.tween_property(visual_root, "scale", Vector3(1.16, 0.84, 1.16), 0.055)
	tween.tween_property(visual_root, "scale", Vector3.ONE, 0.11)


func _build_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "WarlockVisual"
	add_child(visual_root)

	var robe_material := _material(Color(0.055, 0.015, 0.095), false)
	var armor_material := _material(Color(0.105, 0.085, 0.14), false)
	var void_material := _material(Color(0.48, 0.06, 0.92), true)
	var corruption_material := _material(Color(0.30, 0.72, 0.08), true)
	var dark_material := _material(Color(0.008, 0.005, 0.014), false)

	var body_mesh := MeshInstance3D.new()
	var body_shape := CylinderMesh.new()
	body_shape.top_radius = 0.36
	body_shape.bottom_radius = 0.72
	body_shape.height = 1.38
	body_mesh.mesh = body_shape
	body_mesh.material_override = robe_material
	visual_root.add_child(body_mesh)

	var chest_plate := MeshInstance3D.new()
	var chest_shape := BoxMesh.new()
	chest_shape.size = Vector3(0.82, 0.62, 0.30)
	chest_plate.mesh = chest_shape
	chest_plate.position = Vector3(0.0, 0.18, -0.08)
	chest_plate.material_override = armor_material
	visual_root.add_child(chest_plate)

	for shoulder_x in [-0.48, 0.48]:
		var shoulder := MeshInstance3D.new()
		var shoulder_shape := SphereMesh.new()
		shoulder_shape.radius = 0.25
		shoulder_shape.height = 0.40
		shoulder.mesh = shoulder_shape
		shoulder.position = Vector3(shoulder_x, 0.39, 0.0)
		shoulder.scale = Vector3(1.25, 0.75, 1.0)
		shoulder.material_override = armor_material
		visual_root.add_child(shoulder)

	var hood_mesh := MeshInstance3D.new()
	var hood_shape := SphereMesh.new()
	hood_shape.radius = 0.48
	hood_shape.height = 0.96
	hood_mesh.mesh = hood_shape
	hood_mesh.position = Vector3(0.0, 0.75, 0.0)
	hood_mesh.scale = Vector3(1.0, 1.12, 0.96)
	hood_mesh.material_override = armor_material
	visual_root.add_child(hood_mesh)

	var face_mesh := MeshInstance3D.new()
	var face_shape := SphereMesh.new()
	face_shape.radius = 0.27
	face_shape.height = 0.54
	face_mesh.mesh = face_shape
	face_mesh.position = Vector3(0.0, 0.72, -0.31)
	face_mesh.material_override = dark_material
	visual_root.add_child(face_mesh)

	for eye_x in [-0.10, 0.10]:
		var eye := MeshInstance3D.new()
		var eye_shape := SphereMesh.new()
		eye_shape.radius = 0.038
		eye_shape.height = 0.076
		eye.mesh = eye_shape
		eye.position = Vector3(eye_x, 0.76, -0.56)
		eye.material_override = void_material
		visual_root.add_child(eye)

	left_hand = _add_magic_hand(Vector3(-0.62, 0.02, -0.16), armor_material, corruption_material)
	right_hand = _add_magic_hand(Vector3(0.62, 0.02, -0.16), armor_material, void_material)

	for i in range(3):
		var shard := MeshInstance3D.new()
		var shard_shape := PrismMesh.new()
		shard_shape.size = Vector3(0.16, 0.42, 0.12)
		shard.mesh = shard_shape
		var angle := TAU * float(i) / 3.0
		shard.position = Vector3(cos(angle) * 0.84, 0.42 + float(i) * 0.12, sin(angle) * 0.84)
		shard.rotation_degrees = Vector3(20.0, rad_to_deg(angle), 25.0)
		shard.material_override = void_material if i != 1 else corruption_material
		visual_root.add_child(shard)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 1.65
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.05, 0.0)
	add_child(collision)


func _add_magic_hand(
	position_value: Vector3, armor_material: Material, glow_material: Material
) -> MeshInstance3D:
	var forearm := MeshInstance3D.new()
	var forearm_shape := CylinderMesh.new()
	forearm_shape.top_radius = 0.10
	forearm_shape.bottom_radius = 0.15
	forearm_shape.height = 0.70
	forearm.mesh = forearm_shape
	forearm.position = position_value + Vector3(0.0, 0.28, 0.0)
	forearm.rotation_degrees.z = -28.0 if position_value.x < 0.0 else 28.0
	forearm.material_override = armor_material
	visual_root.add_child(forearm)

	var hand := MeshInstance3D.new()
	var hand_shape := SphereMesh.new()
	hand_shape.radius = 0.16
	hand_shape.height = 0.28
	hand.mesh = hand_shape
	hand.position = position_value
	hand.material_override = glow_material
	visual_root.add_child(hand)

	var hand_light := OmniLight3D.new()
	hand_light.position = position_value
	hand_light.light_color = (
		Color(0.50, 0.08, 1.0) if position_value.x > 0.0 else Color(0.35, 0.82, 0.08)
	)
	hand_light.light_energy = 1.45
	hand_light.omni_range = 2.2
	visual_root.add_child(hand_light)
	return hand


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if glowing:
		material.emission_enabled = true
		material.emission = color * 3.0
		material.emission_energy_multiplier = 2.5
	return material
