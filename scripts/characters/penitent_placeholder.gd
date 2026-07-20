extends CharacterBody3D
class_name PenitentPlaceholderCharacter

signal health_changed(current_health: int, maximum_health: int)
signal resource_changed(
	resource_id: String,
	display_name: String,
	current_value: float,
	maximum_value: float
)
signal experience_changed(current_level: int, current_xp: int, required_xp: int)
signal level_up_requested
signal inventory_changed
signal skill_tree_changed
signal died
signal ability_message(message: String)
signal loot_message(message: String)

const CLASS_ID := "penitent_placeholder"
const CLASS_DISPLAY_NAME := "The Penitent"
const RESOURCE_ID := "fervor"
const RESOURCE_DISPLAY_NAME := "Fervor"
const EQUIPMENT_SLOTS := ["Weapon", "Hood", "Chest", "Gloves", "Boots", "Relic"]
const MAX_BACKPACK_SIZE := 12

const PLACEHOLDER_BRANCHES := {
	"Brands": [
		{
			"id": "blood_scripture",
			"name": "Blood Scripture",
			"description": "Placeholder: Rite Marks remain active longer.",
			"icon": "⌁",
		}
	],
	"Circles": [
		{
			"id": "consecrated_ground",
			"name": "Consecrated Ground",
			"description": "Placeholder: gain power while standing inside a sigil.",
			"icon": "◉",
		}
	],
	"Sacrifice": [
		{
			"id": "willing_wound",
			"name": "Willing Wound",
			"description": "Placeholder: health-paid rites grant bonus Fervor.",
			"icon": "†",
		}
	],
}

var max_health := 110
var health := 110
var max_fervor := 100.0
var fervor := 25.0
var move_speed := 6.8
var alive := true

var level := 1
var experience := 0
var experience_required := 70
var pending_level_ups := 0
var level_up_in_progress := false
var branch_progress := {"Brands": 0, "Circles": 0, "Sacrifice": 0}

var equipment := {
	"Weapon": {},
	"Hood": {},
	"Chest": {},
	"Gloves": {},
	"Boots": {},
	"Relic": {},
}
var backpack: Array = []

var facing := Vector3(0.0, 0.0, -1.0)
var attack_cooldown := 0.0
var dodge_cooldown := 0.0
var dodge_time := 0.0
var invulnerability_time := 0.0
var dodge_direction := Vector3.ZERO
var visual_root: Node3D


func _ready() -> void:
	add_to_group("player")
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 5
	_build_placeholder_visual()
	health_changed.emit(health, max_health)
	resource_changed.emit(RESOURCE_ID, RESOURCE_DISPLAY_NAME, fervor, max_fervor)
	experience_changed.emit(level, experience, experience_required)


func _physics_process(delta: float) -> void:
	if not alive:
		velocity = Vector3.ZERO
		return

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
		_debug_ritual_blade()
		attack_cooldown = 0.46

	if Input.is_action_just_pressed("rift"):
		ability_message.emit("SEAL OF BINDING — GAMEPLAY AGENT PENDING")


func get_class_id() -> String:
	return CLASS_ID


func get_class_display_name() -> String:
	return CLASS_DISPLAY_NAME


func get_class_definition() -> Dictionary:
	return {
		"id": CLASS_ID,
		"display_name": CLASS_DISPLAY_NAME,
		"title": "Saint of the Last Rite",
		"resource_id": RESOURCE_ID,
		"resource_name": RESOURCE_DISPLAY_NAME,
		"tags": ["Hybrid", "Setup", "Area Control", "Risk/Reward"],
		"difficulty": "High",
		"skill_branches": ["Brands", "Circles", "Sacrifice"],
		"placeholder": true,
	}


func get_resource_snapshot() -> Dictionary:
	return {
		"id": RESOURCE_ID,
		"display_name": RESOURCE_DISPLAY_NAME,
		"current": fervor,
		"maximum": max_fervor,
		"normalized": fervor / maxf(max_fervor, 1.0),
	}


func add_class_resource(amount: float) -> void:
	add_fervor(amount)


func spend_class_resource(amount: float) -> bool:
	return spend_fervor(amount)


func add_fervor(amount: float) -> void:
	if not alive or amount <= 0.0:
		return
	fervor = clampf(fervor + amount, 0.0, max_fervor)
	resource_changed.emit(RESOURCE_ID, RESOURCE_DISPLAY_NAME, fervor, max_fervor)


func spend_fervor(amount: float) -> bool:
	if amount < 0.0 or fervor < amount:
		return false
	fervor = maxf(fervor - amount, 0.0)
	resource_changed.emit(RESOURCE_ID, RESOURCE_DISPLAY_NAME, fervor, max_fervor)
	return true


func collect_soul(amount: float, rare: bool = false) -> void:
	add_fervor(amount * (0.42 if rare else 0.30))
	add_experience(8 if rare else 4)


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
	for branch_name in ["Brands", "Circles", "Sacrifice"]:
		var skills: Array = PLACEHOLDER_BRANCHES[branch_name]
		var tier: int = int(branch_progress[branch_name])
		var choice: Dictionary
		if tier < skills.size():
			choice = skills[tier].duplicate(true)
		else:
			choice = {
				"id": "mastery_" + branch_name.to_lower(),
				"name": branch_name + " Mastery",
				"description": "Placeholder mastery node.",
				"icon": "✥",
			}
		choice["branch"] = branch_name
		choice["tier"] = tier + 1
		choices.append(choice)
	return choices


func apply_level_up_choice(choice: Dictionary) -> void:
	var branch_name: String = str(choice.get("branch", "Brands"))
	branch_progress[branch_name] = int(branch_progress.get(branch_name, 0)) + 1
	pending_level_ups = maxi(pending_level_ups - 1, 0)
	level_up_in_progress = pending_level_ups > 0
	skill_tree_changed.emit()
	experience_changed.emit(level, experience, experience_required)
	if pending_level_ups > 0:
		level_up_requested.emit()


func get_skill_tree_snapshot() -> Dictionary:
	return {
		"progress": branch_progress.duplicate(true),
		"branches": PLACEHOLDER_BRANCHES,
		"branch_order": ["Brands", "Circles", "Sacrifice"],
		"level": level,
	}


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
		loot_message.emit("EQUIPPED PLACEHOLDER: %s" % str(item_copy.get("name", "Unknown Relic")))
	elif backpack.size() < MAX_BACKPACK_SIZE:
		backpack.append(item_copy)
		loot_message.emit("LOOT STORED: %s" % str(item_copy.get("name", "Unknown Relic")))
	else:
		add_experience(24)
		loot_message.emit("BACKPACK FULL — ITEM CONSUMED FOR XP")
	inventory_changed.emit()


func equip_inventory_index(index: int) -> void:
	if index < 0 or index >= backpack.size():
		return
	var new_item: Dictionary = backpack[index]
	var slot: String = str(new_item.get("slot", "Relic"))
	var old_item: Dictionary = equipment.get(slot, {})
	equipment[slot] = new_item
	if old_item.is_empty():
		backpack.remove_at(index)
	else:
		backpack[index] = old_item
	inventory_changed.emit()


func get_inventory_snapshot() -> Dictionary:
	return {
		"equipment": equipment.duplicate(true),
		"backpack": backpack.duplicate(true),
		"capacity": MAX_BACKPACK_SIZE,
	}


func get_item_drop_bonus() -> float:
	return 0.0


func get_soul_detonation_damage() -> int:
	return 0


func get_summon_wretch_chance() -> float:
	return 0.0


func on_enemy_killed() -> void:
	pass


func heal(amount: int) -> void:
	if not alive or amount <= 0:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)


func take_damage(amount: int) -> void:
	if not alive or invulnerability_time > 0.0 or amount <= 0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		alive = false
		collision_layer = 0
		collision_mask = 0
		died.emit()


func _debug_ritual_blade() -> void:
	var hit_count := 0
	var strike_center := global_position + facing * 1.25
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
			continue
		var offset: Vector3 = enemy.global_position - strike_center
		offset.y = 0.0
		if offset.length() <= 1.55:
			enemy.take_damage(14)
			hit_count += 1
	if hit_count > 0:
		add_fervor(minf(6.0 + float(hit_count - 1) * 2.0, 12.0))
	if is_instance_valid(visual_root):
		var tween := create_tween()
		tween.tween_property(visual_root, "scale", Vector3(1.18, 0.90, 1.18), 0.06)
		tween.tween_property(visual_root, "scale", Vector3.ONE, 0.12)


func _build_placeholder_visual() -> void:
	visual_root = Node3D.new()
	visual_root.name = "PenitentPlaceholderVisual"
	add_child(visual_root)

	var black_material := _material(Color(0.025, 0.018, 0.022), false)
	var red_material := _material(Color(0.72, 0.025, 0.035), true)
	var green_material := _material(Color(0.30, 0.86, 0.06), true)
	var bone_material := _material(Color(0.70, 0.66, 0.52), false)

	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.34
	body_mesh.bottom_radius = 0.64
	body_mesh.height = 1.45
	body.mesh = body_mesh
	body.material_override = black_material
	visual_root.add_child(body)

	var mask := MeshInstance3D.new()
	var mask_mesh := SphereMesh.new()
	mask_mesh.radius = 0.31
	mask_mesh.height = 0.56
	mask.mesh = mask_mesh
	mask.position = Vector3(0.0, 0.78, -0.08)
	mask.scale = Vector3(0.82, 1.05, 0.62)
	mask.material_override = bone_material
	visual_root.add_child(mask)

	var halo := MeshInstance3D.new()
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 0.50
	halo_mesh.outer_radius = 0.57
	halo.mesh = halo_mesh
	halo.position = Vector3(0.0, 0.80, 0.16)
	halo.rotation_degrees.x = 90.0
	halo.material_override = red_material
	visual_root.add_child(halo)

	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.16, 1.25, 0.12)
	blade.mesh = blade_mesh
	blade.position = Vector3(0.56, 0.02, -0.10)
	blade.rotation_degrees.z = 26.0
	blade.material_override = green_material
	visual_root.add_child(blade)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.50
	capsule.height = 1.70
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.05, 0.0)
	add_child(collision)


func _material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.74
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.8
		material.emission_energy_multiplier = 2.3
	return material
