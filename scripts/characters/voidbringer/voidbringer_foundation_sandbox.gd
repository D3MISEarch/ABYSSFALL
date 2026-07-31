class_name VoidbringerFoundationSandbox
extends Node3D

const CONTROLLER_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_controller.gd")
const CATALOG_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_ability_catalog.gd")
const POLISHED_IMPACT_PRESENTATION_SCRIPT = preload("res://scripts/characters/voidbringer/voidbringer_polished_impact_presentation.gd")

var controller: VoidbringerController = CONTROLLER_SCRIPT.new()
var ability_catalog: VoidbringerAbilityCatalog = CATALOG_SCRIPT.new()
var runtime_session: RuntimeSession
var runtime_character: RuntimeCharacter
var combat_projection := PlayableCombatProjection.new()
var mass_brand_definition: AbilityDefinition
var null_shard_definition: AbilityDefinition
var equipped_ability_ids: Array[StringName] = []

var debug_level := 1
var player_origin := Vector3(0.0, 0.58, 4.6)
var anchor_visual_root: Node3D
var fold_line_visual_root: Node3D
var projectile_visual_root: Node3D
var contact_visual_root: Node3D
var hud_label: Label
var sandbox_camera: Camera3D
var player_marker: Node3D
var enemy_fixture: VoidbringerSandboxTarget
var terrain_fixture: Node3D
var corpse_fixture: Node3D
var projectile_visuals: Dictionary = {}
var impact_presentation: VoidbringerPolishedImpactPresentation
var last_skill_result: Dictionary = {}
var last_impact_result: Dictionary = {}
var last_status := "READY"
var _hud_refresh_remaining := 0.0
var _presentation_signature := ""


func _ready() -> void:
	name = "VoidbringerFoundationSandbox"
	_build_world()
	_build_runtime()
	_connect_controller_signals()
	_refresh_presentation(true)
	print("ABYSSFALL_SANDBOX_LAUNCHED:voidbringer_anchor")


func _process(delta: float) -> void:
	_advance_simulation(delta)
	_tick_impact_presentation(delta)
	_hud_refresh_remaining -= delta
	if _hud_refresh_remaining <= 0.0:
		_hud_refresh_remaining = 0.1
		_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed or (event as InputEventKey).echo:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_Q:
			simulate_command(&"mass_brand_enemy")
		KEY_W:
			simulate_command(&"mass_brand_terrain")
		KEY_E:
			simulate_command(&"mass_brand_corpse")
		KEY_SPACE:
			simulate_command(&"fire_null_shard")
		KEY_1:
			simulate_command(&"place_enemy")
		KEY_2:
			simulate_command(&"place_terrain")
		KEY_3:
			simulate_command(&"place_corpse")
		KEY_M:
			simulate_command(&"load_mass")
		KEY_I:
			simulate_command(&"add_instability")
		KEY_T:
			simulate_command(&"advance_time")
		KEY_L:
			simulate_command(&"toggle_level")
		KEY_C:
			simulate_command(&"clear")
		KEY_R:
			simulate_command(&"replay_impact")


func simulate_command(command: StringName) -> bool:
	var success := true
	match command:
		&"mass_brand_enemy":
			success = _cast_mass_brand(&"enemy", enemy_fixture, enemy_fixture.global_position, 8.0)
		&"mass_brand_terrain":
			success = _cast_mass_brand(&"terrain", terrain_fixture, terrain_fixture.global_position, 5.0)
		&"mass_brand_corpse":
			success = _cast_mass_brand(&"corpse", corpse_fixture, corpse_fixture.global_position, 20.0)
		&"fire_null_shard":
			success = _fire_null_shard()
		&"place_enemy":
			controller.place_anchor(&"enemy", enemy_fixture, enemy_fixture.global_position, 8.0)
		&"place_terrain":
			controller.place_anchor(&"terrain", terrain_fixture, terrain_fixture.global_position, 5.0)
		&"place_corpse":
			controller.place_anchor(&"corpse", corpse_fixture, corpse_fixture.global_position, 20.0)
		&"load_mass":
			var anchors: Array[Dictionary] = controller.anchors.active_anchors()
			if anchors.is_empty():
				return false
			controller.add_anchor_mass(anchors.back().get("anchor_id", &""), 20.0)
		&"add_instability":
			controller.commit_spatial_ability(20.0)
		&"advance_time":
			_advance_simulation(1.0)
		&"toggle_level":
			debug_level = 5 if debug_level < 5 else 1
			runtime_character.level = debug_level
			controller.configure(debug_level)
			last_status = "LEVEL %d" % debug_level
		&"clear", &"reset":
			_reset_sandbox()
		&"replay_impact":
			_reset_sandbox()
			success = _fire_null_shard()
		_:
			return false
	_refresh_presentation()
	return success


func simulate_seconds(seconds: float, step: float = 0.02) -> void:
	var remaining := maxf(seconds, 0.0)
	var bounded_step := clampf(step, 0.001, 0.25)
	while remaining > 0.0:
		var current_step := minf(remaining, bounded_step)
		_advance_simulation(current_step)
		_tick_impact_presentation(current_step)
		remaining -= current_step
	_refresh_presentation()


func debug_snapshot() -> Dictionary:
	var snapshot := controller.snapshot()
	var charge_state := _mass_brand_charge_snapshot()
	snapshot["debug_level"] = debug_level
	snapshot["capacity"] = controller.anchors.capacity()
	snapshot["runtime_bound"] = controller.is_runtime_bound()
	snapshot["mass_brand_runtime"] = charge_state
	snapshot["enemy"] = {
		"health": 0 if enemy_fixture == null else enemy_fixture.health,
		"maximum_health": 0 if enemy_fixture == null else enemy_fixture.maximum_health,
		"alive": false if enemy_fixture == null else enemy_fixture.alive,
		"hit_calls": 0 if enemy_fixture == null else enemy_fixture.hit_calls,
	}
	snapshot["last_skill"] = last_skill_result.duplicate(true)
	snapshot["last_impact"] = last_impact_result.duplicate(true)
	snapshot["projectile_visual_count"] = projectile_visuals.size()
	snapshot["impact_presentation"] = {} if impact_presentation == null else impact_presentation.snapshot()
	snapshot["status"] = last_status
	return snapshot


func _build_runtime() -> void:
	mass_brand_definition = ability_catalog.mass_brand_definition()
	null_shard_definition = ability_catalog.null_shard_definition()
	equipped_ability_ids = [mass_brand_definition.ability_id, null_shard_definition.ability_id]

	runtime_character = RuntimeCharacter.new()
	runtime_character.build_id = "voidbringer-skill-sandbox"
	runtime_character.class_id = &"void_warlock"
	runtime_character.level = debug_level
	runtime_character.unlocked_abilities = equipped_ability_ids.duplicate()
	runtime_character.class_resource.configure(&"corruption", 100.0)
	runtime_character.class_resource.fill()

	runtime_session = RuntimeSession.new()
	runtime_session.name = "VoidbringerSandboxRuntime"
	add_child(runtime_session)
	runtime_session.character = runtime_character
	combat_projection.configure({"power": 0.0, "critical_chance": 0.0})
	controller.bind_runtime(runtime_session, runtime_character)


func _connect_controller_signals() -> void:
	controller.foundation_changed.connect(_on_foundation_changed)
	controller.skill_committed.connect(_on_skill_committed)
	controller.skill_rejected.connect(_on_skill_rejected)
	controller.null_shard_spawned.connect(_on_null_shard_spawned)
	controller.null_shard_ended.connect(_on_null_shard_ended)
	controller.impact_committed.connect(_on_impact_committed)


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var environment_resource := Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color(0.006, 0.008, 0.018)
	environment_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment_resource.ambient_light_color = Color(0.16, 0.13, 0.25)
	environment_resource.ambient_light_energy = 0.55
	environment.environment = environment_resource
	add_child(environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
	light.light_energy = 1.25
	light.light_color = Color(0.68, 0.72, 1.0)
	light.shadow_enabled = true
	add_child(light)

	sandbox_camera = Camera3D.new()
	sandbox_camera.position = Vector3(0.0, 10.8, 12.8)
	add_child(sandbox_camera)
	sandbox_camera.look_at(Vector3(0.0, 0.0, -0.5), Vector3.UP)

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(16.0, 0.18, 13.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.12, -0.25)
	floor.material_override = _material(Color(0.035, 0.03, 0.065), 0.0)
	add_child(floor)

	var center_disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 3.2
	disc_mesh.bottom_radius = 3.2
	disc_mesh.height = 0.025
	center_disc.mesh = disc_mesh
	center_disc.position = Vector3(0.0, 0.01, -0.5)
	center_disc.material_override = _material(Color(0.11, 0.025, 0.22), 1.2)
	add_child(center_disc)

	player_marker = _build_player_marker()
	enemy_fixture = VoidbringerSandboxTarget.new()
	enemy_fixture.name = "EnemyFixture"
	enemy_fixture.position = Vector3(0.0, 0.52, -4.0)
	add_child(enemy_fixture)
	enemy_fixture.configure_visuals(
		_material(Color(0.62, 0.08, 0.16), 0.35),
		_material(Color(0.20, 0.035, 0.055), 0.08)
	)
	terrain_fixture = _build_fixture("TerrainFixture", Vector3(-2.8, 0.60, -0.5), Color(0.18, 0.20, 0.28), &"terrain")
	corpse_fixture = _build_fixture("CorpseFixture", Vector3(2.8, 0.48, -0.5), Color(0.22, 0.42, 0.18), &"corpse")

	anchor_visual_root = Node3D.new()
	anchor_visual_root.name = "AnchorDebugVisuals"
	add_child(anchor_visual_root)
	fold_line_visual_root = Node3D.new()
	fold_line_visual_root.name = "FoldLineDebugVisuals"
	add_child(fold_line_visual_root)
	projectile_visual_root = Node3D.new()
	projectile_visual_root.name = "NullShardVisuals"
	add_child(projectile_visual_root)
	contact_visual_root = Node3D.new()
	contact_visual_root.name = "ContactVisuals"
	add_child(contact_visual_root)
	impact_presentation = POLISHED_IMPACT_PRESENTATION_SCRIPT.new()
	impact_presentation.name = "VoidbringerPolishedImpactPresentation"
	contact_visual_root.add_child(impact_presentation)
	impact_presentation.configure(contact_visual_root, sandbox_camera)

	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud_label = Label.new()
	hud_label.position = Vector2(22.0, 18.0)
	hud_label.size = Vector2(1180.0, 430.0)
	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.add_theme_color_override("font_color", Color(0.88, 0.90, 1.0))
	hud_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	hud_label.add_theme_constant_override("shadow_offset_x", 2)
	hud_label.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(hud_label)


func _build_player_marker() -> Node3D:
	var root := Node3D.new()
	root.name = "VoidbringerCastOrigin"
	root.position = player_origin
	add_child(root)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.35
	body.mesh = capsule
	body.material_override = _material(Color(0.14, 0.08, 0.22), 0.25)
	root.add_child(body)
	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.16
	core_mesh.height = 0.32
	core.mesh = core_mesh
	core.position = Vector3(0.0, 0.22, -0.32)
	core.material_override = _material(Color(0.82, 0.76, 1.0), 4.0)
	root.add_child(core)
	var label := Label3D.new()
	label.text = "VOIDBRINGER"
	label.position.y = 1.25
	label.font_size = 28
	root.add_child(label)
	return root


func _build_fixture(fixture_name: String, position: Vector3, color: Color, carrier_type: StringName) -> Node3D:
	var fixture_root := Node3D.new()
	fixture_root.name = fixture_name
	fixture_root.position = position
	fixture_root.set_meta("carrier_type", carrier_type)
	add_child(fixture_root)

	var mesh_instance := MeshInstance3D.new()
	if carrier_type == &"terrain":
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 1.2, 1.5)
		mesh_instance.mesh = box
	else:
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.48
		capsule.height = 0.96
		mesh_instance.mesh = capsule
	mesh_instance.material_override = _material(color, 0.35)
	fixture_root.add_child(mesh_instance)

	var label := Label3D.new()
	label.text = String(carrier_type).to_upper()
	label.position.y = 1.25 if carrier_type != &"corpse" else 0.65
	label.font_size = 30
	label.modulate = Color(0.92, 0.93, 1.0)
	fixture_root.add_child(label)
	return fixture_root


func _cast_mass_brand(
	carrier_type: StringName,
	carrier: Variant,
	position: Vector3,
	mass: float
) -> bool:
	var result := controller.execute_mass_brand_command(
		mass_brand_definition,
		carrier_type,
		carrier,
		position,
		mass,
		{
			"attack_origin": player_origin + Vector3(0.0, 1.8, 0.0),
			"surface_normal": Vector3.UP,
			"surface_profile": carrier_type,
			"death_profile": &"sandbox",
			"target_mass_class": &"standard",
		},
		equipped_ability_ids,
		combat_projection
	)
	last_skill_result = result.duplicate(true)
	last_status = "MASS BRAND: %s" % String(result.get("reason", &"unknown")).to_upper()
	return bool(result.get("success", false))


func _fire_null_shard() -> bool:
	if enemy_fixture == null or not enemy_fixture.alive:
		last_status = "NULL SHARD: NO LIVE TARGET"
		return false
	var direction := (enemy_fixture.global_position - player_origin).normalized()
	var result := controller.execute_null_shard_command(
		null_shard_definition,
		player_origin,
		direction,
		combat_projection,
		{
			"surface_profile": &"flesh_armor",
			"death_profile": &"sandbox",
		},
		equipped_ability_ids
	)
	last_skill_result = result.duplicate(true)
	last_status = "NULL SHARD: %s" % String(result.get("reason", &"unknown")).to_upper()
	return bool(result.get("success", false))


func _advance_simulation(delta: float) -> void:
	var step := maxf(delta, 0.0)
	if step <= 0.0:
		return
	if runtime_session != null:
		runtime_session.tick_runtime(step)
	controller.tick(step)
	_check_projectile_contacts()
	_update_projectile_visuals()


func _check_projectile_contacts() -> void:
	if enemy_fixture == null or not enemy_fixture.alive:
		return
	for raw_id: Variant in controller.active_null_shards.keys().duplicate():
		var projectile_id := StringName(str(raw_id))
		var projectile := controller.get_null_shard(projectile_id)
		if projectile == null or not projectile.active:
			continue
		var closest := _closest_point_on_segment(
			enemy_fixture.global_position,
			projectile.previous_position,
			projectile.position
		)
		var contact_radius := enemy_fixture.collision_radius + VoidbringerNullShardProjectile.PROJECTILE_RADIUS
		if closest.distance_to(enemy_fixture.global_position) > contact_radius:
			continue
		projectile.commit_contact(
			enemy_fixture,
			closest,
			-projectile.direction,
			&"standard",
			&"flesh_armor",
			&"sandbox"
		)


func _closest_point_on_segment(point: Vector3, start: Vector3, finish: Vector3) -> Vector3:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return start
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * t


func _on_foundation_changed(_snapshot: Dictionary) -> void:
	_refresh_presentation()


func _on_skill_committed(commit: VoidbringerSkillCommit) -> void:
	last_skill_result = commit.snapshot()


func _on_skill_rejected(commit: VoidbringerSkillCommit) -> void:
	last_skill_result = commit.snapshot()
	last_status = "REJECTED: %s" % String(commit.reason()).to_upper()


func _on_null_shard_spawned(projectile: VoidbringerNullShardProjectile) -> void:
	_create_projectile_visual(projectile)
	if impact_presentation != null:
		impact_presentation.begin_null_shard_cast(projectile)


func _on_null_shard_ended(projectile_id: StringName, reason: StringName) -> void:
	if projectile_visuals.has(projectile_id):
		var visual := projectile_visuals[projectile_id] as Node3D
		projectile_visuals.erase(projectile_id)
		if is_instance_valid(visual):
			visual.queue_free()
	last_status = "NULL SHARD %s" % String(reason).to_upper()


func _on_impact_committed(result: VoidbringerImpactResult) -> void:
	last_impact_result = result.snapshot()
	if impact_presentation != null:
		impact_presentation.present_accepted_null_shard(result, enemy_fixture)
	var ability_id := String(last_impact_result.get("ability_id", &""))
	last_status = "%s HIT %d%s" % [
		ability_id.get_slice(".", ability_id.get_slice_count(".") - 1).to_upper(),
		int(last_impact_result.get("damage", 0)),
		" CRIT" if bool(last_impact_result.get("critical", false)) else "",
	]


func _create_projectile_visual(projectile: VoidbringerNullShardProjectile) -> void:
	if projectile == null or projectile_visuals.has(projectile.projectile_id):
		return
	var root := Node3D.new()
	root.name = String(projectile.projectile_id)
	projectile_visual_root.add_child(root)
	var core := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.17
	sphere.height = 0.34
	core.mesh = sphere
	core.material_override = _material(Color(0.84, 0.80, 1.0), 5.0)
	root.add_child(core)
	var trail := MeshInstance3D.new()
	var trail_mesh := BoxMesh.new()
	trail_mesh.size = Vector3(0.09, 0.09, 1.15)
	trail.mesh = trail_mesh
	trail.position.z = 0.58
	trail.material_override = _material(Color(0.30, 0.10, 0.62), 3.2)
	root.add_child(trail)
	projectile_visuals[projectile.projectile_id] = root
	_update_one_projectile_visual(projectile, root)


func _update_projectile_visuals() -> void:
	for raw_id: Variant in projectile_visuals.keys().duplicate():
		var projectile_id := StringName(str(raw_id))
		var visual := projectile_visuals.get(projectile_id) as Node3D
		var projectile := controller.get_null_shard(projectile_id)
		if projectile == null or not projectile.active:
			projectile_visuals.erase(projectile_id)
			if is_instance_valid(visual):
				visual.queue_free()
			continue
		_update_one_projectile_visual(projectile, visual)


func _update_one_projectile_visual(projectile: VoidbringerNullShardProjectile, visual: Node3D) -> void:
	if projectile == null or not is_instance_valid(visual):
		return
	visual.global_position = projectile.position
	visual.look_at(projectile.position + projectile.direction, Vector3.UP)
	var bonus_scale := 1.0 + 0.12 * float(projectile.crossing_count)
	visual.scale = Vector3.ONE * bonus_scale


func _tick_impact_presentation(delta: float) -> void:
	if impact_presentation != null:
		impact_presentation.tick(delta)


func _refresh_presentation(force_rebuild: bool = false) -> void:
	var signature := _build_presentation_signature()
	if force_rebuild or signature != _presentation_signature:
		_presentation_signature = signature
		_rebuild_anchor_visuals()
		_rebuild_fold_line_visuals()
	_update_projectile_visuals()
	_refresh_hud()


func _build_presentation_signature() -> String:
	var tokens := PackedStringArray()
	for anchor: Dictionary in controller.anchors.active_anchors():
		var position: Vector3 = anchor.get("position", Vector3.ZERO)
		tokens.append(
			"%s|%s|%.2f|%s|%.3f,%.3f,%.3f" % [
				String(anchor.get("anchor_id", &"")),
				String(anchor.get("carrier_type", &"")),
				float(anchor.get("mass", 0.0)),
				String(anchor.get("mass_stage", &"")),
				position.x,
				position.y,
				position.z,
			]
		)
	tokens.append("lines:%d" % controller.fold_lines.line_count())
	return ";".join(tokens)


func _rebuild_anchor_visuals() -> void:
	_clear_children(anchor_visual_root)
	for anchor: Dictionary in controller.anchors.active_anchors():
		var root := Node3D.new()
		root.name = String(anchor.get("anchor_id", &"anchor"))
		root.position = (anchor.get("position", Vector3.ZERO) as Vector3) + Vector3(0.0, 0.22, 0.0)
		anchor_visual_root.add_child(root)

		var stage := StringName(str(anchor.get("mass_stage", &"dormant")))
		var color := Color(0.42, 0.20, 0.78)
		var emission := 1.5
		if stage == &"dense":
			color = Color(0.62, 0.18, 0.92)
			emission = 2.8
		elif stage == &"critical":
			color = Color(0.92, 0.90, 1.0)
			emission = 5.0

		var core := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.28
		sphere.height = 0.56
		core.mesh = sphere
		core.material_override = _material(color, emission)
		root.add_child(core)

		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.42
		torus.outer_radius = 0.48
		ring.mesh = torus
		ring.rotation_degrees.x = 90.0
		ring.material_override = _material(color, emission * 0.75)
		root.add_child(ring)

		var label := Label3D.new()
		label.text = "%s  %d MASS" % [String(stage).to_upper(), int(round(float(anchor.get("mass", 0.0))))]
		label.position.y = 0.72
		label.font_size = 28
		root.add_child(label)


func _rebuild_fold_line_visuals() -> void:
	_clear_children(fold_line_visual_root)
	for line: Dictionary in controller.fold_lines.lines():
		var start: Vector3 = line.get("start", Vector3.ZERO)
		var finish: Vector3 = line.get("end", Vector3.ZERO)
		var length := start.distance_to(finish)
		if length <= 0.001:
			continue
		var visual := MeshInstance3D.new()
		visual.name = String(line.get("line_id", &"fold_line"))
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.055, 0.055, length)
		visual.mesh = mesh
		var visual_position := (start + finish) * 0.5 + Vector3(0.0, 0.24, 0.0)
		var visual_target := finish + Vector3(0.0, 0.24, 0.0)
		visual.look_at_from_position(visual_position, visual_target, Vector3.UP)
		visual.material_override = _material(Color(0.72, 0.62, 1.0), 3.2)
		fold_line_visual_root.add_child(visual)


func _refresh_hud() -> void:
	if not is_instance_valid(hud_label):
		return
	var snapshot := controller.snapshot()
	var instability_state: Dictionary = snapshot.get("instability", {})
	var state_name := "BREACH" if bool(instability_state.get("in_breach", false)) else "CONTAINED"
	var charge_state := _mass_brand_charge_snapshot()
	var lines := PackedStringArray([
		"VOIDBRINGER MASS BRAND + NULL SHARD SANDBOX",
		"[Q] Brand Enemy   [W] Brand Terrain   [E] Brand Corpse   [SPACE] Fire Null Shard   [R] Reset + Replay",
		"[1/2/3] Direct Anchor Debug   [M] +20 Mass   [I] +20 Instability   [T] Advance 1s",
		"[L] Toggle Level 1/5   [C] Clear + Reset   Null Shard presentation: cast brace → contact → reset",
		"",
		"Level %d | Anchor Capacity %d | Active %d | Fold Lines %d | Projectiles %d" % [
			debug_level,
			controller.anchors.capacity(),
			controller.anchors.active_count(),
			controller.fold_lines.line_count(),
			controller.active_null_shards.size(),
		],
		"Mass Brand Charges %d / %d | Recharge %.1fs | Null Shard ALWAYS READY" % [
			int(charge_state.get("current", 2)),
			int(charge_state.get("maximum", 2)),
			float(charge_state.get("recharge_remaining", 0.0)),
		],
		"Instability %.1f / 100 | %s | Breach %.1fs | Anchor Influence x%.2f" % [
			float(instability_state.get("current", 0.0)),
			state_name,
			float(instability_state.get("breach_remaining", 0.0)),
			float(instability_state.get("anchor_influence_multiplier", 1.0)),
		],
		"Enemy %d / %d HP | %s | Hits %d | %s" % [
			enemy_fixture.health,
			enemy_fixture.maximum_health,
			"ALIVE" if enemy_fixture.alive else "DEAD",
			enemy_fixture.hit_calls,
			last_status,
		],
	])
	for anchor: Dictionary in controller.anchors.active_anchors():
		lines.append(
			"%s | %s | %s | Mass %.0f | %.1fs" % [
				String(anchor.get("anchor_id", &"")),
				String(anchor.get("carrier_type", &"")).to_upper(),
				String(anchor.get("mass_stage", &"")).to_upper(),
				float(anchor.get("mass", 0.0)),
				float(anchor.get("remaining_seconds", 0.0)),
			]
		)
	if not last_impact_result.is_empty():
		lines.append(
			"LAST IMPACT | %s | Damage %d | Crit %s | Fold Crossings %d" % [
				String(last_impact_result.get("ability_id", &"")),
				int(last_impact_result.get("damage", 0)),
				"YES" if bool(last_impact_result.get("critical", false)) else "NO",
				int(last_impact_result.get("fold_crossing_count", 0)),
			]
		)
	hud_label.text = "\n".join(lines)


func _mass_brand_charge_snapshot() -> Dictionary:
	if runtime_session == null or runtime_character == null or mass_brand_definition == null:
		return {"current": 2, "maximum": 2, "recharge_remaining": 0.0}
	var snapshot := runtime_session.ability_executor.charge_snapshot(
		runtime_character.build_id,
		mass_brand_definition.ability_id
	)
	if snapshot.is_empty():
		return {
			"current": mass_brand_definition.maximum_charges,
			"maximum": mass_brand_definition.maximum_charges,
			"recharge_remaining": 0.0,
		}
	return snapshot


func _reset_sandbox() -> void:
	if impact_presentation != null:
		impact_presentation.clear()
	controller.clear()
	if runtime_session != null and runtime_character != null:
		runtime_session.ability_executor.clear_build(runtime_character.build_id)
		runtime_character.class_resource.fill()
	controller.configure(debug_level)
	if enemy_fixture != null:
		enemy_fixture.reset_target()
	last_skill_result.clear()
	last_impact_result.clear()
	last_status = "RESET COMPLETE"
	projectile_visuals.clear()
	_clear_children(projectile_visual_root)
	_refresh_presentation(true)


func set_impact_presentation_mode(presentation_mode: StringName) -> void:
	if impact_presentation != null:
		impact_presentation.set_mode(presentation_mode)


func _clear_children(root: Node) -> void:
	if not is_instance_valid(root):
		return
	for child: Node in root.get_children():
		child.queue_free()


func _material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.18
	material.roughness = 0.28
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
