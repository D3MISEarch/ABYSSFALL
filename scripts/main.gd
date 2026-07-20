extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const SKELETON_SCRIPT = preload("res://scripts/skeleton.gd")
const BONE_ARCHER_SCRIPT = preload("res://scripts/bone_archer.gd")
const CRYPT_BRUTE_SCRIPT = preload("res://scripts/crypt_brute.gd")
const HOLLOW_KING_SCRIPT = preload("res://scripts/hollow_king.gd")
const VOID_TRAP_SCRIPT = preload("res://scripts/void_trap.gd")
const GENERATOR_SCRIPT = preload("res://scripts/abyss_generator.gd")
const SOUL_PICKUP_SCRIPT = preload("res://scripts/soul_pickup.gd")
const ITEM_PICKUP_SCRIPT = preload("res://scripts/item_pickup.gd")
const BOUND_WRETCH_SCRIPT = preload("res://scripts/bound_wretch.gd")
const CORRUPTION_METER_SCRIPT = preload("res://scripts/corruption_meter.gd")

const EQUIPMENT_SLOTS := ["Weapon", "Hood", "Chest", "Gloves", "Boots", "Relic"]

const ITEM_POOL := [
	{
		"id": "void_scepter",
		"name": "Void-Touched Scepter",
		"slot": "Weapon",
		"rarity": "Magic",
		"description": "A fractured focus that sharpens every bolt.",
		"stats": {"bolt_damage": 4, "bolt_speed": 1.5},
		"weight": 15.0
	},
	{
		"id": "cryptfang_wand",
		"name": "Cryptfang Wand",
		"slot": "Weapon",
		"rarity": "Rare",
		"description": "Carved from a predator that hunted beneath the tombs.",
		"stats": {"bolt_damage": 5, "fire_interval_reduction": 0.018},
		"weight": 11.0
	},
	{
		"id": "bonebound_grimoire",
		"name": "Bonebound Grimoire",
		"slot": "Weapon",
		"rarity": "Epic",
		"description": "Its pages are stitched from those who refused to speak.",
		"stats": {"bolt_damage": 7, "item_drop_bonus": 0.08},
		"weight": 6.0
	},
	{
		"id": "whisper_cowl",
		"name": "Cowl of Whispered Veins",
		"slot": "Hood",
		"rarity": "Rare",
		"description": "Wet voices coil around the wearer's thoughts.",
		"stats": {"max_corruption": 18.0, "corruption_gain_multiplier": 0.08},
		"weight": 11.0
	},
	{
		"id": "graven_crown",
		"name": "Graven Crown",
		"slot": "Hood",
		"rarity": "Epic",
		"description": "A dead monarch's thoughts still twitch inside the metal.",
		"stats": {"max_corruption": 22.0, "rift_damage": 7},
		"weight": 6.0
	},
	{
		"id": "hunger_carapace",
		"name": "Carapace of Hunger",
		"slot": "Chest",
		"rarity": "Rare",
		"description": "A living shell that drinks pain before blood.",
		"stats": {"max_health": 22},
		"weight": 11.0
	},
	{
		"id": "ossuary_mantle",
		"name": "Ossuary Mantle",
		"slot": "Chest",
		"rarity": "Epic",
		"description": "Layered grave-plates tighten when enemies draw near.",
		"stats": {"max_health": 28, "max_corruption": 8.0},
		"weight": 6.0
	},
	{
		"id": "gravegrip_wraps",
		"name": "Gravegrip Wraps",
		"slot": "Gloves",
		"rarity": "Magic",
		"description": "Finger-bones twitch with impatient spellcraft.",
		"stats": {"fire_interval_reduction": 0.026, "bolt_damage": 1},
		"weight": 14.0
	},
	{
		"id": "tendonweave_grips",
		"name": "Tendonweave Grips",
		"slot": "Gloves",
		"rarity": "Rare",
		"description": "Warm tendons pull the fingers into faster sigils.",
		"stats": {"fire_interval_reduction": 0.032, "corruption_gain_multiplier": 0.06},
		"weight": 9.0
	},
	{
		"id": "riftwalker_greaves",
		"name": "Riftwalker Greaves",
		"slot": "Boots",
		"rarity": "Magic",
		"description": "Every step briefly forgets the laws of distance.",
		"stats": {"move_speed": 0.75, "max_health": 6},
		"weight": 14.0
	},
	{
		"id": "gravewind_treads",
		"name": "Gravewind Treads",
		"slot": "Boots",
		"rarity": "Epic",
		"description": "Cold air screams through their hollow soles.",
		"stats": {"move_speed": 1.05, "max_corruption": 12.0},
		"weight": 6.0
	},
	{
		"id": "maw_starved",
		"name": "Maw of the Starved",
		"slot": "Relic",
		"rarity": "Legendary",
		"description": "It hungers beside you. Feed it, and the Rift bites harder.",
		"stats": {"corruption_gain_multiplier": 0.24, "rift_damage": 10},
		"weight": 3.0
	},
	{
		"id": "voidheart",
		"name": "Voidheart Amulet",
		"slot": "Relic",
		"rarity": "Epic",
		"description": "A cold pulse answers every stolen soul.",
		"stats": {"rift_radius": 0.85, "soul_heal": 1, "max_corruption": 10.0},
		"weight": 6.0
	},
	{
		"id": "wretch_bell",
		"name": "Wretch Bell",
		"slot": "Relic",
		"rarity": "Epic",
		"description": "It rings without moving whenever a soul is torn loose.",
		"stats": {"item_drop_bonus": 0.10, "corruption_gain_multiplier": 0.10},
		"weight": 5.0
	}
]

const HIDDEN_RELIC_ITEM := {
	"id": "reliquary_sunken_teeth",
	"name": "Reliquary of Sunken Teeth",
	"slot": "Relic",
	"rarity": "Epic",
	"description": "The crypt chews every soul before surrendering it.",
	"stats": {"soul_heal": 2, "max_health": 14, "max_corruption": 10.0},
	"weight": 0.0
}

const HOLLOW_KING_REWARD := {
	"id": "crown_hollow_king",
	"name": "Crown of the Hollow King",
	"slot": "Hood",
	"rarity": "Legendary",
	"description": "The throne is empty. Its appetite is not.",
	"stats": {"max_corruption": 25.0, "corruption_gain_multiplier": 0.15, "rift_damage": 12},
	"weight": 0.0
}

var player
var camera: Camera3D
var health_bar: ProgressBar
var health_label: Label
var xp_bar: ProgressBar
var xp_label: Label
var objective_label: Label
var generator_label: Label
var kill_label: Label
var message_label: Label
var corruption_label: Label
var corruption_meter
var equipment_summary_label: Label
var boss_health_bar: ProgressBar
var boss_health_label: Label
var interaction_label: Label

var inventory_panel: Control
var inventory_equipment_box: VBoxContainer
var inventory_backpack_box: VBoxContainer
var skill_panel: Control
var skill_columns: HBoxContainer
var level_up_panel: Control
var level_choice_buttons: Array[Button] = []
var current_level_choices: Array = []
var menu_hint_label: Label

var generators_remaining := 3
var current_room_generators := 0
var enemies_alive := 0
var total_kills := 0
var elite_kills := 0
var game_state := "courtyard"
var game_finished := false
var message_token := 0
var catacomb_wave := 0
var gates: Dictionary = {}
var boss
var hidden_relic_claimed := false
var relic_altar: Node3D

const MAX_ACTIVE_ENEMIES := 32
const COURTYARD_GENERATORS := [Vector3(-6.5, 0.0, 10.0), Vector3(6.5, 0.0, 7.0)]
const GENERATOR_CHAMBER_POSITION := Vector3(0.0, 0.0, -20.0)
const RELIC_ALTAR_POSITION := Vector3(12.0, 0.0, -72.0)
const BOSS_POSITION := Vector3(0.0, 0.0, -103.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	_install_input_map()
	_build_environment()
	_build_arena()
	_build_hud()
	_spawn_player()
	_start_courtyard()
	_show_message("THE SUNKEN CRYPTS\nBreak the courtyard seals", 2.6)
	await get_tree().create_timer(0.65).timeout
	if is_instance_valid(player):
		_spawn_item_drop(player.global_position + Vector3(2.3, 0.0, 1.0), ITEM_POOL[0])


func _process(delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(camera):
		var target_position: Vector3 = player.global_position + Vector3(0.0, 17.8, 16.2)
		camera.global_position = camera.global_position.lerp(
			target_position, clampf(delta * 5.0, 0.0, 1.0)
		)
		camera.look_at(player.global_position + Vector3(0.0, 0.45, 0.0), Vector3.UP)

	if Input.is_action_just_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()
		return

	if level_up_panel != null and level_up_panel.visible:
		if Input.is_action_just_pressed("choose_1"):
			_choose_level_card(0)
		elif Input.is_action_just_pressed("choose_2"):
			_choose_level_card(1)
		elif Input.is_action_just_pressed("choose_3"):
			_choose_level_card(2)
		return

	if not get_tree().paused:
		_update_level_flow()
		_update_relic_interaction()

	if Input.is_action_just_pressed("inventory"):
		_toggle_inventory()
	elif Input.is_action_just_pressed("skill_tree"):
		_toggle_skill_tree()
	elif Input.is_action_just_pressed("menu_close"):
		_close_side_menus()


func _install_input_map() -> void:
	var actions := [
		"move_left",
		"move_right",
		"move_forward",
		"move_back",
		"aim_left",
		"aim_right",
		"aim_up",
		"aim_down",
		"attack",
		"dodge",
		"rift",
		"restart",
		"inventory",
		"skill_tree",
		"choose_1",
		"choose_2",
		"choose_3",
		"menu_close",
		"interact"
	]
	for action_name in actions:
		_ensure_action(action_name)
		InputMap.action_erase_events(action_name)

	_bind_key("move_left", KEY_A)
	_bind_key("move_right", KEY_D)
	_bind_key("move_forward", KEY_W)
	_bind_key("move_back", KEY_S)
	_bind_key("dodge", KEY_SPACE)
	_bind_key("dodge", KEY_SHIFT)
	_bind_key("rift", KEY_Q)
	_bind_key("restart", KEY_R)
	_bind_key("inventory", KEY_I)
	_bind_key("skill_tree", KEY_T)
	_bind_key("choose_1", KEY_1)
	_bind_key("choose_2", KEY_2)
	_bind_key("choose_3", KEY_3)
	_bind_key("menu_close", KEY_ESCAPE)
	_bind_key("interact", KEY_E)
	_bind_mouse_button("attack", MOUSE_BUTTON_LEFT)
	_bind_mouse_button("rift", MOUSE_BUTTON_RIGHT)

	_bind_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_joy_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_bind_joy_axis("move_back", JOY_AXIS_LEFT_Y, 1.0)
	_bind_joy_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_bind_joy_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_bind_joy_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_bind_joy_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	_bind_joy_button("attack", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_joy_button("rift", JOY_BUTTON_LEFT_SHOULDER)
	_bind_joy_button("dodge", JOY_BUTTON_A)
	_bind_joy_button("inventory", JOY_BUTTON_Y)
	_bind_joy_button("skill_tree", JOY_BUTTON_X)
	_bind_joy_button("interact", JOY_BUTTON_B)


func _ensure_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)


func _bind_key(action_name: StringName, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func _bind_mouse_button(action_name: StringName, button_index: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)


func _bind_joy_button(action_name: StringName, button_index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)


func _bind_joy_axis(action_name: StringName, axis_index: JoyAxis, axis_value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis_index
	event.axis_value = axis_value
	InputMap.action_add_event(action_name, event)


func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.004, 0.012)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.24, 0.13, 0.31)
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_environment.environment = environment
	add_child(world_environment)

	var moon_light := DirectionalLight3D.new()
	moon_light.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	moon_light.light_color = Color(0.48, 0.52, 0.90)
	moon_light.light_energy = 1.28
	moon_light.shadow_enabled = true
	add_child(moon_light)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 50.0
	camera.position = Vector3(0.0, 16.8, 15.2)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.45, 0.0), Vector3.UP)


func _build_arena() -> void:
	_create_static_box(
		"CryptFloor",
		Vector3(0.0, -0.42, -46.0),
		Vector3(34.0, 0.84, 132.0),
		Color(0.035, 0.028, 0.048)
	)
	_create_static_box(
		"WestOuterWall",
		Vector3(-17.5, 1.1, -46.0),
		Vector3(1.0, 3.2, 133.0),
		Color(0.072, 0.054, 0.088)
	)
	_create_static_box(
		"EastOuterWall",
		Vector3(17.5, 1.1, -46.0),
		Vector3(1.0, 3.2, 133.0),
		Color(0.072, 0.054, 0.088)
	)
	_create_static_box(
		"SouthSeal", Vector3(0.0, 1.1, 20.5), Vector3(35.0, 3.2, 1.0), Color(0.072, 0.054, 0.088)
	)
	_create_static_box(
		"NorthThroneWall",
		Vector3(0.0, 1.1, -112.5),
		Vector3(35.0, 3.2, 1.0),
		Color(0.072, 0.054, 0.088)
	)

	for partition_z in [-5.0, -32.0, -60.0, -86.0]:
		_create_static_box(
			"PartitionLeft_%d" % int(abs(partition_z)),
			Vector3(-11.0, 1.1, partition_z),
			Vector3(12.0, 3.2, 0.9),
			Color(0.083, 0.061, 0.10)
		)
		_create_static_box(
			"PartitionRight_%d" % int(abs(partition_z)),
			Vector3(11.0, 1.1, partition_z),
			Vector3(12.0, 3.2, 0.9),
			Color(0.083, 0.061, 0.10)
		)

	gates["courtyard"] = _create_gate("CourtyardGate", Vector3(0.0, 1.1, -5.0))
	gates["generator"] = _create_gate("GeneratorGate", Vector3(0.0, 1.1, -32.0))
	gates["catacombs"] = _create_gate("CatacombGate", Vector3(0.0, 1.1, -60.0))
	gates["boss"] = _create_gate("BossGate", Vector3(0.0, 1.1, -86.0))

	_decorate_room(Vector3(0.0, 0.0, 8.0), 8.2, Color(0.42, 0.035, 0.82), 10)
	_decorate_room(Vector3(0.0, 0.0, -20.0), 8.4, Color(0.28, 0.68, 0.055), 12)
	_decorate_room(Vector3(0.0, 0.0, -46.0), 7.2, Color(0.42, 0.035, 0.82), 9)
	_decorate_room(Vector3(0.0, 0.0, -73.0), 6.0, Color(0.28, 0.68, 0.055), 8)
	_decorate_room(BOSS_POSITION, 10.2, Color(0.52, 0.025, 0.92), 14)

	for i in range(5):
		var trap := VOID_TRAP_SCRIPT.new()
		trap.setup(float(i) * 0.52, 14 + i)
		add_child(trap)
		trap.global_position = Vector3(-6.0 + float(i % 3) * 6.0, 0.02, -66.0 - float(i) * 3.2)

	_build_relic_alcove()


func _create_gate(gate_name: String, position_value: Vector3) -> StaticBody3D:
	var gate := StaticBody3D.new()
	gate.name = gate_name
	gate.position = position_value
	gate.collision_layer = 1
	gate.collision_mask = 0
	for i in range(7):
		var bar := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.28, 3.0, 0.42)
		bar.mesh = mesh
		bar.position = Vector3(-4.2 + float(i) * 1.4, 0.0, 0.0)
		bar.material_override = _make_material(
			Color(0.43, 0.035, 0.88) if i % 2 == 0 else Color(0.25, 0.70, 0.05), true
		)
		gate.add_child(bar)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(10.0, 3.2, 0.75)
	collision.shape = shape
	gate.add_child(collision)
	add_child(gate)
	return gate


func _open_gate(gate_id: String) -> void:
	var gate = gates.get(gate_id)
	if not is_instance_valid(gate):
		return
	gates.erase(gate_id)
	var tween := create_tween()
	tween.tween_property(gate, "position:y", 5.5, 0.48).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(gate.queue_free)


func _decorate_room(center: Vector3, radius: float, glow_color: Color, pillar_count: int) -> void:
	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = radius
	disc_mesh.bottom_radius = radius
	disc_mesh.height = 0.035
	disc.mesh = disc_mesh
	disc.position = center + Vector3(0.0, 0.04, 0.0)
	disc.material_override = _make_material(
		Color(glow_color.r * 0.18, glow_color.g * 0.18, glow_color.b * 0.18), true
	)
	add_child(disc)
	for i in range(pillar_count):
		var angle := TAU * float(i) / float(pillar_count)
		var pillar_position := (
			center + Vector3(cos(angle) * (radius + 2.2), 1.20, sin(angle) * (radius + 2.2))
		)
		_create_static_box(
			"CryptPillar_%d_%d" % [int(abs(center.z)), i],
			pillar_position,
			Vector3(0.72, 2.7, 0.72),
			Color(0.082, 0.060, 0.10)
		)
		var light := OmniLight3D.new()
		light.position = pillar_position + Vector3(0.0, 1.45, 0.0)
		light.light_color = glow_color
		light.light_energy = 1.35
		light.omni_range = 3.8
		add_child(light)


func _build_relic_alcove() -> void:
	_create_static_box(
		"RelicAlcoveFloor",
		Vector3(12.0, -0.38, -72.0),
		Vector3(8.0, 0.76, 13.0),
		Color(0.052, 0.034, 0.064)
	)
	_create_static_box(
		"RelicAlcoveWestNorth",
		Vector3(8.1, 1.1, -77.0),
		Vector3(0.6, 3.0, 3.0),
		Color(0.085, 0.060, 0.105)
	)
	_create_static_box(
		"RelicAlcoveWestSouth",
		Vector3(8.1, 1.1, -67.0),
		Vector3(0.6, 3.0, 3.0),
		Color(0.085, 0.060, 0.105)
	)
	relic_altar = Node3D.new()
	relic_altar.name = "HiddenRelicAltar"
	add_child(relic_altar)
	relic_altar.global_position = RELIC_ALTAR_POSITION
	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 1.0
	pedestal_mesh.bottom_radius = 1.35
	pedestal_mesh.height = 1.0
	pedestal.mesh = pedestal_mesh
	pedestal.position.y = 0.45
	pedestal.material_override = _make_material(Color(0.085, 0.055, 0.10), false)
	relic_altar.add_child(pedestal)
	var relic := MeshInstance3D.new()
	var relic_mesh := PrismMesh.new()
	relic_mesh.size = Vector3(0.45, 1.0, 0.32)
	relic.mesh = relic_mesh
	relic.position.y = 1.45
	relic.material_override = _make_material(Color(0.30, 0.78, 0.05), true)
	relic_altar.add_child(relic)
	var light := OmniLight3D.new()
	light.position.y = 1.4
	light.light_color = Color(0.30, 0.82, 0.05)
	light.light_energy = 2.4
	light.omni_range = 5.0
	relic_altar.add_child(light)


func _create_static_box(
	node_name: String, position_value: Vector3, size_value: Vector3, color: Color
) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	body.collision_layer = 1
	body.collision_mask = 0

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size_value
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = _make_material(color, false)
	body.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size_value
	collision_shape.shape = box_shape
	body.add_child(collision_shape)
	add_child(body)


func _make_material(color: Color, glowing: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if glowing:
		material.emission_enabled = true
		material.emission = color * 2.8
		material.emission_energy_multiplier = 2.2
	return material


func _spawn_player() -> void:
	player = PLAYER_SCRIPT.new()
	player.name = "VoidWarlock"
	add_child(player)
	player.global_position = Vector3(0.0, 0.9, 14.0)
	player.health_changed.connect(_on_player_health_changed)
	player.corruption_changed.connect(_on_player_corruption_changed)
	player.experience_changed.connect(_on_player_experience_changed)
	player.level_up_requested.connect(_on_level_up_requested)
	player.inventory_changed.connect(_refresh_inventory)
	player.skill_tree_changed.connect(_refresh_skill_tree)
	player.ability_message.connect(_on_ability_message)
	player.loot_message.connect(_on_loot_message)
	player.died.connect(_on_player_died)
	_on_player_health_changed(player.health, player.max_health)
	_on_player_corruption_changed(player.corruption, player.max_corruption)
	_on_player_experience_changed(player.level, player.experience, player.experience_required)
	_refresh_inventory()
	_refresh_skill_tree()


func _spawn_generators() -> void:
	for position_value in COURTYARD_GENERATORS:
		_spawn_generator(position_value, "courtyard")


func _on_generator_spawn_requested(generator: Node) -> void:
	if game_finished or game_state not in ["courtyard", "generator_room"]:
		return
	if enemies_alive >= MAX_ACTIVE_ENEMIES:
		return
	if not is_instance_valid(generator) or not is_instance_valid(player) or not player.alive:
		return
	var room_id := str(generator.get_meta("room_id", "courtyard"))
	var spawn_count := 2 if randf() < 0.22 and enemies_alive < MAX_ACTIVE_ENEMIES - 1 else 1
	for i in range(spawn_count):
		var angle := randf_range(0.0, TAU)
		var position_value: Vector3 = (
			generator.global_position + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(1.8, 2.8)
		)
		var enemy_type := "reaver"
		if room_id == "generator_room":
			var roll := randf()
			enemy_type = "archer" if roll < 0.30 else ("brute" if roll < 0.38 else "reaver")
		_spawn_enemy(enemy_type, position_value, 0.0, false)


func _spawn_generator(position_value: Vector3, room_id: String) -> void:
	var generator := GENERATOR_SCRIPT.new()
	generator.name = "AbyssGenerator_%s_%d" % [room_id, generators_remaining]
	generator.set_meta("room_id", room_id)
	generator.spawn_requested.connect(_on_generator_spawn_requested)
	generator.destroyed.connect(_on_generator_destroyed)
	add_child(generator)
	generator.global_position = position_value
	current_room_generators += 1


func _spawn_enemy(
	enemy_type: String, position_value: Vector3, bonus_speed: float = 0.0, force_elite: bool = false
) -> void:
	if not is_instance_valid(player) or enemies_alive >= MAX_ACTIVE_ENEMIES:
		return
	var enemy
	match enemy_type:
		"archer":
			enemy = BONE_ARCHER_SCRIPT.new()
		"brute":
			enemy = CRYPT_BRUTE_SCRIPT.new()
		_:
			enemy = SKELETON_SCRIPT.new()
	enemy.name = "%s_%d" % [enemy_type.capitalize(), total_kills + enemies_alive + 1]
	enemy.target = player
	enemy.move_speed += randf_range(-0.12, 0.28) + bonus_speed
	enemy.max_health += randi_range(-3, 8)
	enemy.health = enemy.max_health
	var elite_chance: float = 0.05 + minf(float(total_kills) * 0.0025, 0.09)
	var make_elite: bool = force_elite or (total_kills >= 5 and randf() < elite_chance)
	enemy.setup_elite(make_elite)
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)
	enemy.global_position = position_value + Vector3(0.0, 0.86, 0.0)
	enemies_alive += 1
	_update_enemy_label()


func _spawn_skeleton(position_value: Vector3, bonus_speed: float, force_elite: bool) -> void:
	_spawn_enemy("reaver", position_value, bonus_speed, force_elite)


func _on_enemy_died(enemy) -> void:
	var death_position := Vector3.ZERO
	var was_elite := false
	var xp_reward := 22
	var guaranteed_item := false
	if is_instance_valid(enemy):
		death_position = enemy.global_position
		was_elite = bool(enemy.get("elite"))
		xp_reward = int(enemy.get("xp_reward"))
		guaranteed_item = bool(enemy.get("guaranteed_item_drop"))

	enemies_alive = maxi(enemies_alive - 1, 0)
	total_kills += 1
	if was_elite:
		elite_kills += 1
	_update_enemy_label()

	if is_instance_valid(player):
		player.add_experience(xp_reward)
		player.on_enemy_killed()

	_spawn_soul_pickup(death_position, was_elite)
	_trigger_soul_detonation(death_position, enemy)

	var item_chance := 0.045
	if is_instance_valid(player):
		item_chance += player.get_item_drop_bonus()
	if guaranteed_item or randf() < item_chance:
		_spawn_item_drop(
			death_position + Vector3(randf_range(-0.5, 0.5), 0.0, randf_range(-0.5, 0.5))
		)

	if is_instance_valid(player) and randf() < player.get_summon_wretch_chance():
		_spawn_bound_wretch(death_position)

	_check_room_clear()


func _trigger_soul_detonation(center: Vector3, dead_enemy: Node) -> void:
	if not is_instance_valid(player):
		return
	var damage: int = int(player.get_soul_detonation_damage())
	if damage <= 0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if (
			enemy == dead_enemy
			or not is_instance_valid(enemy)
			or not enemy.has_method("take_damage")
		):
			continue
		var offset: Vector3 = enemy.global_position - center
		offset.y = 0.0
		if offset.length() <= 2.7:
			enemy.take_damage(damage)


func _spawn_soul_pickup(position_value: Vector3, from_elite: bool) -> void:
	if not is_instance_valid(player):
		return
	var is_rare := from_elite or randf() < 0.16
	var amount := 28.0 if is_rare else 13.0
	var pickup := SOUL_PICKUP_SCRIPT.new()
	pickup.setup(player, amount, is_rare)
	add_child(pickup)
	pickup.global_position = position_value + Vector3(0.0, 0.55, 0.0)


func _spawn_item_drop(position_value: Vector3, specific_item: Dictionary = {}) -> void:
	if not is_instance_valid(player):
		return
	var item := specific_item.duplicate(true) if not specific_item.is_empty() else _roll_item()
	var pickup := ITEM_PICKUP_SCRIPT.new()
	pickup.setup(player, item)
	add_child(pickup)
	pickup.global_position = position_value + Vector3(0.0, 0.70, 0.0)


func _roll_item() -> Dictionary:
	var total_weight := 0.0
	for item in ITEM_POOL:
		total_weight += float(item.get("weight", 1.0))
	var roll := randf() * total_weight
	var cursor := 0.0
	for item in ITEM_POOL:
		cursor += float(item.get("weight", 1.0))
		if roll <= cursor:
			return item.duplicate(true)
	return ITEM_POOL[0].duplicate(true)


func _spawn_bound_wretch(position_value: Vector3) -> void:
	if not is_instance_valid(player):
		return
	var wretch := BOUND_WRETCH_SCRIPT.new()
	wretch.setup(player)
	add_child(wretch)
	wretch.global_position = position_value + Vector3(0.0, 0.65, 0.0)
	_show_message("A SOUL ANSWERS YOUR CALL", 0.85)


func _on_generator_destroyed(generator: Node) -> void:
	var drop_position := Vector3.ZERO
	if is_instance_valid(generator):
		drop_position = generator.global_position
	generators_remaining = maxi(generators_remaining - 1, 0)
	current_room_generators = maxi(current_room_generators - 1, 0)
	generator_label.text = "CRYPT SEALS: %d / 3 REMAIN" % generators_remaining
	if is_instance_valid(player):
		player.add_experience(65)
	_spawn_item_drop(drop_position)
	_show_message("ABYSS GENERATOR SHATTERED", 1.0)
	_check_room_clear()


func _spawn_final_horde() -> void:
	# Retained as a compatibility hook from v0.3; The Sunken Crypts now uses room waves.
	_check_room_clear()


func _complete_prototype() -> void:
	_complete_level()


func _start_courtyard() -> void:
	game_state = "courtyard"
	current_room_generators = 0
	objective_label.text = "BREAK THE COURTYARD SEALS"
	generator_label.text = "ROOM I — RITUAL COURTYARD"
	_spawn_generators()
	for position_value in [
		Vector3(-8.0, 0.0, 13.0),
		Vector3(8.0, 0.0, 12.0),
		Vector3(-3.0, 0.0, 4.0),
		Vector3(4.0, 0.0, 3.0)
	]:
		_spawn_enemy("reaver", position_value)


func _start_generator_room() -> void:
	game_state = "generator_room"
	current_room_generators = 0
	objective_label.text = "SILENCE THE DEEP GENERATOR"
	generator_label.text = "ROOM II — GENERATOR CHAMBER"
	_spawn_generator(GENERATOR_CHAMBER_POSITION, "generator_room")
	_spawn_enemy("archer", Vector3(-7.0, 0.0, -23.0))
	_spawn_enemy("archer", Vector3(7.0, 0.0, -23.0))
	_spawn_enemy("brute", Vector3(0.0, 0.0, -15.0), 0.0, true)
	_show_message("THE CHAMBER DEFENDS ITS HEART", 1.45)


func _start_catacombs() -> void:
	game_state = "catacombs_wave_1"
	catacomb_wave = 1
	objective_label.text = "SURVIVE THE COLLAPSED CATACOMBS"
	generator_label.text = "ROOM III — COLLAPSED CATACOMBS"
	for position_value in [
		Vector3(-8.0, 0.0, -43.0),
		Vector3(8.0, 0.0, -43.0),
		Vector3(-5.0, 0.0, -51.0),
		Vector3(5.0, 0.0, -51.0)
	]:
		_spawn_enemy("reaver", position_value, 0.18)
	_spawn_enemy("archer", Vector3(0.0, 0.0, -53.0))
	_show_message("BONES MOVE BENEATH THE RUBBLE", 1.35)


func _spawn_catacomb_second_wave() -> void:
	if game_finished or game_state != "catacombs_transition":
		return
	game_state = "catacombs_wave_2"
	catacomb_wave = 2
	_spawn_enemy("brute", Vector3(0.0, 0.0, -48.0), 0.15, true)
	_spawn_enemy("archer", Vector3(-8.0, 0.0, -50.0))
	_spawn_enemy("archer", Vector3(8.0, 0.0, -50.0))
	for x in [-5.0, 0.0, 5.0]:
		_spawn_enemy("reaver", Vector3(x, 0.0, -40.0), 0.28)
	_show_message("THE OSSUARY OPENS", 1.15)


func _start_trap_hall() -> void:
	game_state = "trap_hall"
	objective_label.text = "CROSS THE HUNGRY HALL"
	generator_label.text = "ROOM IV — TRAP HALLWAY"
	_spawn_enemy("archer", Vector3(-7.0, 0.0, -75.0))
	_spawn_enemy("archer", Vector3(7.0, 0.0, -75.0), 0.0, true)
	_spawn_enemy("reaver", Vector3(-4.0, 0.0, -68.0), 0.30)
	_spawn_enemy("reaver", Vector3(4.0, 0.0, -81.0), 0.30)
	_show_message("THE FLOOR IS STILL ALIVE", 1.25)


func _start_boss_encounter() -> void:
	game_state = "boss"
	objective_label.text = "SLAY THE HOLLOW KING"
	generator_label.text = "ROOM VI — ABYSSAL THRONE"
	boss = HOLLOW_KING_SCRIPT.new()
	boss.name = "TheHollowKing"
	boss.target = player
	boss.health_changed.connect(_on_boss_health_changed)
	boss.phase_changed.connect(_on_boss_phase_changed)
	boss.summon_requested.connect(_on_boss_summon_requested)
	boss.died.connect(_on_boss_died)
	add_child(boss)
	boss.global_position = BOSS_POSITION + Vector3(0.0, 1.55, 0.0)
	gates["boss_lock"] = _create_gate("ThroneCombatSeal", Vector3(0.0, 1.1, -86.0))
	boss_health_bar.visible = true
	boss_health_label.visible = true
	_show_message("THE HOLLOW KING\nFIRST VESSEL OF THE ABYSS", 2.2)


func _update_level_flow() -> void:
	if game_finished or not is_instance_valid(player):
		return
	var z: float = float(player.global_position.z)
	if game_state == "courtyard_clear" and z < -8.0:
		_start_generator_room()
	elif game_state == "generator_room_clear" and z < -36.0:
		_start_catacombs()
	elif game_state == "catacombs_clear" and z < -64.0:
		_start_trap_hall()
	elif game_state == "trap_clear" and z < -91.0:
		_start_boss_encounter()


func _check_room_clear() -> void:
	if game_finished:
		return
	if game_state == "courtyard" and current_room_generators == 0 and enemies_alive == 0:
		game_state = "courtyard_clear"
		_open_gate("courtyard")
		objective_label.text = "DESCEND TO THE GENERATOR CHAMBER"
		generator_label.text = "COURTYARD PURGED"
		_show_message("THE FIRST SEAL IS BROKEN", 1.4)
	elif game_state == "generator_room" and current_room_generators == 0 and enemies_alive == 0:
		game_state = "generator_room_clear"
		_open_gate("generator")
		objective_label.text = "ENTER THE COLLAPSED CATACOMBS"
		generator_label.text = "DEEP GENERATOR SILENCED"
		_show_message("A PATH SINKS DEEPER", 1.4)
	elif game_state == "catacombs_wave_1" and enemies_alive == 0:
		game_state = "catacombs_transition"
		_show_message("THE RUBBLE BREATHES AGAIN", 1.0)
		await get_tree().create_timer(1.0, false).timeout
		_spawn_catacomb_second_wave()
	elif game_state == "catacombs_wave_2" and enemies_alive == 0:
		game_state = "catacombs_clear"
		_open_gate("catacombs")
		objective_label.text = "CROSS THE TRAP HALLWAY"
		generator_label.text = "CATACOMBS PURGED"
		_show_message("THE DEAD HAVE GONE QUIET", 1.25)
	elif game_state == "trap_hall" and enemies_alive == 0:
		game_state = "trap_clear"
		_open_gate("boss")
		objective_label.text = "ENTER THE ABYSSAL THRONE"
		generator_label.text = "THE THRONE DOOR OPENS"
		_show_message("SOMETHING WAITS BELOW", 1.45)


func _update_relic_interaction() -> void:
	if hidden_relic_claimed or not is_instance_valid(player) or not is_instance_valid(relic_altar):
		if is_instance_valid(interaction_label):
			interaction_label.text = ""
		return
	var distance: float = player.global_position.distance_to(
		RELIC_ALTAR_POSITION + Vector3(0.0, 0.8, 0.0)
	)
	if distance <= 2.5:
		interaction_label.text = "E / B — FEED THE HIDDEN RELIQUARY"
		if Input.is_action_just_pressed("interact"):
			_claim_hidden_relic()
	else:
		interaction_label.text = ""


func _claim_hidden_relic() -> void:
	hidden_relic_claimed = true
	interaction_label.text = ""
	if is_instance_valid(player):
		player.add_item(HIDDEN_RELIC_ITEM)
		player.add_experience(90)
	if is_instance_valid(relic_altar):
		var tween := create_tween()
		tween.tween_property(relic_altar, "scale", Vector3(0.12, 0.12, 0.12), 0.32)
	_show_message("HIDDEN RELIC CLAIMED\nRELIQUARY OF SUNKEN TEETH", 1.8)


func _on_boss_health_changed(current_health: int, maximum_health: int, current_phase: int) -> void:
	boss_health_bar.max_value = maximum_health
	boss_health_bar.value = current_health
	boss_health_label.text = (
		"THE HOLLOW KING — PHASE %d     %d / %d" % [current_phase, current_health, maximum_health]
	)


func _on_boss_phase_changed(current_phase: int) -> void:
	var phase_name := (
		"THE PREACHER"
		if current_phase == 1
		else ("THE CORRUPTOR" if current_phase == 2 else "THE HOLLOW KING")
	)
	_show_message("PHASE %d — %s" % [current_phase, phase_name], 1.45)


func _on_boss_summon_requested(position_value: Vector3, enemy_type: String) -> void:
	if enemies_alive < MAX_ACTIVE_ENEMIES - 2:
		_spawn_enemy(enemy_type, position_value, 0.18, false)


func _on_boss_died(dead_boss) -> void:
	var drop_position := BOSS_POSITION
	if is_instance_valid(dead_boss):
		drop_position = dead_boss.global_position
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != dead_boss and is_instance_valid(enemy):
			enemy.queue_free()
	enemies_alive = 0
	if is_instance_valid(player):
		player.add_experience(350)
	_spawn_item_drop(drop_position, HOLLOW_KING_REWARD)
	_open_gate("boss_lock")
	_complete_level()


func _complete_level() -> void:
	game_finished = true
	game_state = "victory"
	boss_health_bar.visible = false
	boss_health_label.visible = false
	objective_label.text = "THE SUNKEN CRYPTS CONQUERED"
	generator_label.text = "LEGENDARY REWARD: CROWN OF THE HOLLOW KING"
	_show_message("v0.4 COMPLETE\nTHE HOLLOW KING HAS FALLEN\nPress R to restart", 999.0)


func _on_player_health_changed(current_health: int, maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health
	health_label.text = "LIFE  %d / %d" % [current_health, maximum_health]


func _on_player_corruption_changed(current_corruption: float, maximum_corruption: float) -> void:
	if is_instance_valid(corruption_meter):
		corruption_meter.set_corruption(current_corruption, maximum_corruption)
	if is_instance_valid(corruption_label):
		corruption_label.text = (
			"CORRUPTION  %d / %d" % [int(current_corruption), int(maximum_corruption)]
		)


func _on_player_experience_changed(current_level: int, current_xp: int, required_xp: int) -> void:
	if is_instance_valid(xp_bar):
		xp_bar.max_value = required_xp
		xp_bar.value = current_xp
	if is_instance_valid(xp_label):
		xp_label.text = "LEVEL %d     SOUL XP %d / %d" % [current_level, current_xp, required_xp]


func _on_ability_message(text: String) -> void:
	_show_message(text, 1.05)


func _on_loot_message(text: String) -> void:
	_show_message(text, 1.25)


func _on_player_died() -> void:
	game_finished = true
	game_state = "defeat"
	objective_label.text = "THE CRYPTS CLAIMED YOU"
	_show_message("THE WARLOCK HAS FALLEN\nPress R to restart", 999.0)


func _show_message(text: String, duration: float) -> void:
	message_token += 1
	var token := message_token
	message_label.text = text
	if duration >= 900.0:
		return
	await get_tree().create_timer(duration, true).timeout
	if token == message_token and is_instance_valid(message_label):
		message_label.text = ""


func _update_enemy_label() -> void:
	kill_label.text = (
		"SOULS CLAIMED: %d     ELITES: %d     ENEMIES: %d"
		% [total_kills, elite_kills, enemies_alive]
	)


func _on_level_up_requested() -> void:
	if not is_instance_valid(player):
		return
	_close_side_menus()
	current_level_choices = player.get_level_up_choices()
	for i in range(level_choice_buttons.size()):
		var button: Button = level_choice_buttons[i]
		if i < current_level_choices.size():
			var choice: Dictionary = current_level_choices[i]
			button.text = (
				"%d\n%s — TIER %d\n\n%s\n\n[%s]"
				% [
					i + 1,
					str(choice.get("branch", "Abyss")).to_upper(),
					int(choice.get("tier", 1)),
					str(choice.get("name", "Forbidden Power")),
					str(choice.get("description", "The Abyss changes you."))
				]
			)
			button.disabled = false
		else:
			button.text = "THE ABYSS IS SILENT"
			button.disabled = true
	level_up_panel.visible = true
	_update_pause_state()


func _choose_level_card(index: int) -> void:
	if not is_instance_valid(player) or index < 0 or index >= current_level_choices.size():
		return
	var choice: Dictionary = current_level_choices[index]
	level_up_panel.visible = false
	player.apply_level_up_choice(choice)
	_show_message("POWER AWAKENED: %s" % str(choice.get("name", "Unknown Power")), 1.15)
	_update_pause_state()


func _toggle_inventory() -> void:
	if level_up_panel.visible:
		return
	skill_panel.visible = false
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		_refresh_inventory()
	_update_pause_state()


func _toggle_skill_tree() -> void:
	if level_up_panel.visible:
		return
	inventory_panel.visible = false
	skill_panel.visible = not skill_panel.visible
	if skill_panel.visible:
		_refresh_skill_tree()
	_update_pause_state()


func _close_side_menus() -> void:
	if inventory_panel != null:
		inventory_panel.visible = false
	if skill_panel != null:
		skill_panel.visible = false
	_update_pause_state()


func _update_pause_state() -> void:
	var should_pause := false
	if inventory_panel != null and inventory_panel.visible:
		should_pause = true
	if skill_panel != null and skill_panel.visible:
		should_pause = true
	if level_up_panel != null and level_up_panel.visible:
		should_pause = true
	get_tree().paused = should_pause


func _refresh_inventory() -> void:
	if (
		not is_instance_valid(player)
		or inventory_equipment_box == null
		or inventory_backpack_box == null
	):
		return
	_clear_container(inventory_equipment_box)
	_clear_container(inventory_backpack_box)
	var snapshot: Dictionary = player.get_inventory_snapshot()
	var equipped: Dictionary = snapshot.get("equipment", {})
	var backpack: Array = snapshot.get("backpack", [])

	var title := Label.new()
	title.text = "EQUIPPED RELICS"
	title.add_theme_font_size_override("font_size", 22)
	inventory_equipment_box.add_child(title)

	var summary_lines: Array[String] = []
	for slot in EQUIPMENT_SLOTS:
		var item: Dictionary = equipped.get(slot, {})
		var slot_label := Label.new()
		slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot_label.custom_minimum_size = Vector2(360.0, 54.0)
		if item.is_empty():
			slot_label.text = "%s\n  — Empty —" % slot
			slot_label.modulate = Color(0.62, 0.60, 0.68)
			summary_lines.append("%s: Empty" % slot)
		else:
			var rarity: String = str(item.get("rarity", "Common"))
			slot_label.custom_minimum_size = Vector2(360.0, 72.0)
			slot_label.text = (
				"%s  •  %s\n%s\n%s"
				% [
					slot,
					rarity,
					str(item.get("name", "Unknown Item")),
					_format_item_stats(item),
				]
			)
			slot_label.modulate = _rarity_color(rarity)
			summary_lines.append("%s: %s" % [slot, str(item.get("name", "Unknown"))])
		inventory_equipment_box.add_child(slot_label)

	equipment_summary_label.text = "  |  ".join(PackedStringArray(summary_lines))

	var pack_title := Label.new()
	pack_title.text = (
		"BACKPACK  %d / %d   — CLICK AN ITEM TO EQUIP"
		% [backpack.size(), int(snapshot.get("capacity", 12))]
	)
	pack_title.add_theme_font_size_override("font_size", 22)
	inventory_backpack_box.add_child(pack_title)

	if backpack.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No unequipped items. Elite Reavers and shattered generators can drop gear."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.custom_minimum_size = Vector2(500.0, 70.0)
		empty_label.modulate = Color(0.70, 0.67, 0.76)
		inventory_backpack_box.add_child(empty_label)
	else:
		for i in range(backpack.size()):
			var item: Dictionary = backpack[i]
			var button := Button.new()
			button.custom_minimum_size = Vector2(510.0, 92.0)
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.text = (
				"%s  •  %s  •  %s\n%s\n%s"
				% [
					str(item.get("rarity", "Common")),
					str(item.get("slot", "Relic")),
					str(item.get("name", "Unknown Item")),
					str(item.get("description", "")),
					_format_item_stats(item),
				]
			)
			button.modulate = _rarity_color(str(item.get("rarity", "Common")))
			button.pressed.connect(_on_inventory_item_pressed.bind(i))
			inventory_backpack_box.add_child(button)


func _on_inventory_item_pressed(index: int) -> void:
	if is_instance_valid(player):
		player.equip_inventory_index(index)


func _refresh_skill_tree() -> void:
	if not is_instance_valid(player) or skill_columns == null:
		return
	_clear_container(skill_columns)
	var snapshot: Dictionary = player.get_skill_tree_snapshot()
	var progress: Dictionary = snapshot.get("progress", {})
	var branches: Dictionary = snapshot.get("branches", {})

	for branch_name in ["Abyss", "Corruption", "Soulbinding"]:
		var branch_box := VBoxContainer.new()
		branch_box.custom_minimum_size = Vector2(285.0, 450.0)
		skill_columns.add_child(branch_box)

		var branch_title := Label.new()
		branch_title.text = branch_name.to_upper()
		branch_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_title.add_theme_font_size_override("font_size", 26)
		branch_title.modulate = (
			Color(0.63, 0.25, 1.0) if branch_name != "Corruption" else Color(0.48, 0.88, 0.08)
		)
		branch_box.add_child(branch_title)

		var current_tier := int(progress.get(branch_name, 0))
		var skills: Array = branches.get(branch_name, [])
		for i in range(skills.size()):
			var skill: Dictionary = skills[i]
			var node_label := Label.new()
			node_label.custom_minimum_size = Vector2(275.0, 62.0)
			node_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var prefix := "✓" if i < current_tier else ("▶" if i == current_tier else "◇")
			node_label.text = (
				"%s  T%d  %s\n%s"
				% [
					prefix,
					i + 1,
					str(skill.get("name", "Unknown")),
					str(skill.get("description", ""))
				]
			)
			if i < current_tier:
				node_label.modulate = (
					Color(0.82, 0.52, 1.0)
					if branch_name != "Corruption"
					else Color(0.61, 0.94, 0.16)
				)
			elif i == current_tier:
				node_label.modulate = Color(1.0, 0.93, 0.68)
			else:
				node_label.modulate = Color(0.36, 0.34, 0.42)
			branch_box.add_child(node_label)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _format_item_stats(item: Dictionary) -> String:
	var stats: Dictionary = item.get("stats", {})
	var parts: Array[String] = []
	var labels := {
		"bolt_damage": "Void Bolt damage",
		"bolt_speed": "Bolt speed",
		"max_health": "Maximum Life",
		"max_corruption": "Maximum Corruption",
		"move_speed": "Movement speed",
		"fire_interval_reduction": "Faster casting",
		"rift_radius": "Rift radius",
		"rift_damage": "Rift damage",
		"corruption_gain_multiplier": "Corruption gain",
		"soul_heal": "Life per soul",
		"item_drop_bonus": "Loot chance",
	}
	for key in stats.keys():
		var value = stats[key]
		var label: String = str(labels.get(key, key))
		if key in ["corruption_gain_multiplier", "item_drop_bonus"]:
			parts.append("+%d%% %s" % [int(round(float(value) * 100.0)), label])
		elif key == "fire_interval_reduction":
			parts.append("+%d%% %s" % [int(round(float(value) / 0.18 * 100.0)), label])
		else:
			parts.append("+%s %s" % [str(value), label])
	return "  •  ".join(PackedStringArray(parts))


func _rarity_color(rarity: String) -> Color:
	match rarity:
		"Magic":
			return Color(0.42, 0.63, 1.0)
		"Rare":
			return Color(1.0, 0.90, 0.26)
		"Epic":
			return Color(0.72, 0.30, 1.0)
		"Legendary":
			return Color(1.0, 0.55, 0.12)
		"Mythic":
			return Color(1.0, 0.16, 0.24)
		_:
			return Color(0.86, 0.86, 0.90)


func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	var top_panel := ColorRect.new()
	top_panel.color = Color(0.008, 0.004, 0.014, 0.86)
	top_panel.position = Vector2(0.0, 0.0)
	top_panel.size = Vector2(1280.0, 100.0)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(top_panel)

	health_bar = ProgressBar.new()
	health_bar.position = Vector2(26.0, 22.0)
	health_bar.size = Vector2(300.0, 24.0)
	health_bar.show_percentage = false
	canvas.add_child(health_bar)

	health_label = Label.new()
	health_label.position = Vector2(37.0, 22.0)
	health_label.add_theme_font_size_override("font_size", 17)
	canvas.add_child(health_label)

	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(26.0, 58.0)
	xp_bar.size = Vector2(300.0, 19.0)
	xp_bar.show_percentage = false
	canvas.add_child(xp_bar)

	xp_label = Label.new()
	xp_label.position = Vector2(37.0, 55.0)
	xp_label.add_theme_font_size_override("font_size", 14)
	canvas.add_child(xp_label)

	objective_label = Label.new()
	objective_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective_label.position = Vector2(-185.0, 14.0)
	objective_label.size = Vector2(370.0, 32.0)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 23)
	objective_label.text = "BREAK THE COURTYARD SEALS"
	canvas.add_child(objective_label)

	generator_label = Label.new()
	generator_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	generator_label.position = Vector2(-185.0, 45.0)
	generator_label.size = Vector2(370.0, 24.0)
	generator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	generator_label.add_theme_font_size_override("font_size", 16)
	generator_label.text = "ROOM I — RITUAL COURTYARD"
	canvas.add_child(generator_label)

	kill_label = Label.new()
	kill_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	kill_label.position = Vector2(-420.0, 30.0)
	kill_label.size = Vector2(395.0, 32.0)
	kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kill_label.add_theme_font_size_override("font_size", 16)
	kill_label.text = "SOULS CLAIMED: 0     ELITES: 0     ENEMIES: 0"
	canvas.add_child(kill_label)

	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	message_label.position = Vector2(-360.0, -95.0)
	message_label.size = Vector2(720.0, 190.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 26)
	canvas.add_child(message_label)

	corruption_meter = CORRUPTION_METER_SCRIPT.new()
	corruption_meter.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	corruption_meter.position = Vector2(-235.0, -112.0)
	corruption_meter.size = Vector2(470.0, 76.0)
	canvas.add_child(corruption_meter)

	corruption_label = Label.new()
	corruption_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	corruption_label.position = Vector2(-130.0, -95.0)
	corruption_label.size = Vector2(260.0, 28.0)
	corruption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	corruption_label.add_theme_font_size_override("font_size", 16)
	canvas.add_child(corruption_label)

	boss_health_bar = ProgressBar.new()
	boss_health_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_health_bar.position = Vector2(-310.0, 105.0)
	boss_health_bar.size = Vector2(620.0, 25.0)
	boss_health_bar.show_percentage = false
	boss_health_bar.visible = false
	canvas.add_child(boss_health_bar)

	boss_health_label = Label.new()
	boss_health_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_health_label.position = Vector2(-310.0, 104.0)
	boss_health_label.size = Vector2(620.0, 28.0)
	boss_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_health_label.add_theme_font_size_override("font_size", 15)
	boss_health_label.visible = false
	canvas.add_child(boss_health_label)

	interaction_label = Label.new()
	interaction_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_label.position = Vector2(-260.0, -148.0)
	interaction_label.size = Vector2(520.0, 30.0)
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.add_theme_font_size_override("font_size", 18)
	interaction_label.modulate = Color(0.62, 0.95, 0.18)
	canvas.add_child(interaction_label)

	equipment_summary_label = Label.new()
	equipment_summary_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	equipment_summary_label.offset_left = 16.0
	equipment_summary_label.offset_right = -16.0
	equipment_summary_label.offset_top = -55.0
	equipment_summary_label.offset_bottom = -33.0
	equipment_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_summary_label.add_theme_font_size_override("font_size", 12)
	equipment_summary_label.modulate = Color(0.73, 0.62, 0.86)
	canvas.add_child(equipment_summary_label)

	menu_hint_label = Label.new()
	menu_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	menu_hint_label.offset_left = 16.0
	menu_hint_label.offset_right = -16.0
	menu_hint_label.offset_top = -30.0
	menu_hint_label.offset_bottom = -6.0
	menu_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_hint_label.add_theme_font_size_override("font_size", 14)
	menu_hint_label.text = "I / Y: INVENTORY   T / X: SKILL TREE   E / B: INTERACT   LMB / RB: VOID BOLT   RMB / Q / LB: RIFT   SPACE / A: SHADOW STEP"
	canvas.add_child(menu_hint_label)

	_build_inventory_panel(canvas)
	_build_skill_panel(canvas)
	_build_level_up_panel(canvas)


func _build_inventory_panel(canvas: CanvasLayer) -> void:
	inventory_panel = ColorRect.new()
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.position = Vector2(-520.0, -285.0)
	inventory_panel.size = Vector2(1040.0, 570.0)
	inventory_panel.color = Color(0.012, 0.006, 0.020, 0.97)
	inventory_panel.visible = false
	canvas.add_child(inventory_panel)

	var heading := Label.new()
	heading.position = Vector2(25.0, 14.0)
	heading.size = Vector2(990.0, 38.0)
	heading.text = "VOID WARLOCK INVENTORY     —     I / ESC TO CLOSE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 25)
	inventory_panel.add_child(heading)

	var equipment_scroll := ScrollContainer.new()
	equipment_scroll.position = Vector2(25.0, 65.0)
	equipment_scroll.size = Vector2(410.0, 480.0)
	inventory_panel.add_child(equipment_scroll)
	inventory_equipment_box = VBoxContainer.new()
	inventory_equipment_box.custom_minimum_size = Vector2(390.0, 470.0)
	equipment_scroll.add_child(inventory_equipment_box)

	var backpack_scroll := ScrollContainer.new()
	backpack_scroll.position = Vector2(455.0, 65.0)
	backpack_scroll.size = Vector2(560.0, 480.0)
	inventory_panel.add_child(backpack_scroll)
	inventory_backpack_box = VBoxContainer.new()
	inventory_backpack_box.custom_minimum_size = Vector2(535.0, 470.0)
	backpack_scroll.add_child(inventory_backpack_box)


func _build_skill_panel(canvas: CanvasLayer) -> void:
	skill_panel = ColorRect.new()
	skill_panel.set_anchors_preset(Control.PRESET_CENTER)
	skill_panel.position = Vector2(-500.0, -285.0)
	skill_panel.size = Vector2(1000.0, 570.0)
	skill_panel.color = Color(0.010, 0.005, 0.018, 0.97)
	skill_panel.visible = false
	canvas.add_child(skill_panel)

	var heading := Label.new()
	heading.position = Vector2(25.0, 13.0)
	heading.size = Vector2(950.0, 40.0)
	heading.text = "THE THREE FORBIDDEN PATHS     —     T / ESC TO CLOSE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 25)
	skill_panel.add_child(heading)

	var skill_scroll := ScrollContainer.new()
	skill_scroll.position = Vector2(25.0, 65.0)
	skill_scroll.size = Vector2(950.0, 480.0)
	skill_panel.add_child(skill_scroll)
	skill_columns = HBoxContainer.new()
	skill_columns.custom_minimum_size = Vector2(930.0, 460.0)
	skill_columns.add_theme_constant_override("separation", 25)
	skill_scroll.add_child(skill_columns)


func _build_level_up_panel(canvas: CanvasLayer) -> void:
	level_up_panel = ColorRect.new()
	level_up_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_up_panel.color = Color(0.003, 0.001, 0.008, 0.93)
	level_up_panel.visible = false
	canvas.add_child(level_up_panel)

	var heading := Label.new()
	heading.set_anchors_preset(Control.PRESET_CENTER_TOP)
	heading.position = Vector2(-390.0, 75.0)
	heading.size = Vector2(780.0, 80.0)
	heading.text = "THE ABYSS OFFERS POWER\nCHOOSE WHAT IT WILL MAKE OF YOU"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 29)
	level_up_panel.add_child(heading)

	var cards := HBoxContainer.new()
	cards.set_anchors_preset(Control.PRESET_CENTER)
	cards.position = Vector2(-555.0, -170.0)
	cards.size = Vector2(1110.0, 360.0)
	cards.add_theme_constant_override("separation", 24)
	level_up_panel.add_child(cards)

	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(350.0, 350.0)
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(_choose_level_card.bind(i))
		cards.add_child(button)
		level_choice_buttons.append(button)

	var footer := Label.new()
	footer.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	footer.position = Vector2(-360.0, -75.0)
	footer.size = Vector2(720.0, 40.0)
	footer.text = "Click a card or press 1, 2, or 3"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 18)
	level_up_panel.add_child(footer)
