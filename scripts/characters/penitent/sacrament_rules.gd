extends RefCounted
class_name SacramentRules

const FERVOR_COST := 40.0
const COOLDOWN := 8.0
const CAST_RADIUS := 6.5
const SIGIL_COLLAPSE_BONUS := 6
const BRAND_BONUS := 8


static func is_in_cast_radius(origin: Vector3, target: Vector3, radius: float = CAST_RADIUS) -> bool:
	var offset := target - origin
	offset.y = 0.0
	return offset.length() <= maxf(radius, 0.1)


static func is_eligible(mark_state: int, inside_active_sigil: bool) -> bool:
	return mark_state > 0 or inside_active_sigil


static func should_force_complete(mark_state: int) -> bool:
	return mark_state > 0 and mark_state < 3


static func get_damage(
	mark_state_before_cast: int,
	branded: bool,
	inside_active_sigil: bool,
	health_percent_paid: int,
	boss_safe: bool
) -> int:
	var base_damage := 18
	if mark_state_before_cast >= 3:
		base_damage = 42
	elif mark_state_before_cast > 0:
		base_damage = 30
	if branded:
		base_damage += BRAND_BONUS
	if inside_active_sigil:
		base_damage += SIGIL_COLLAPSE_BONUS
	var blood_multiplier := 1.0 + float(clampi(health_percent_paid, 0, 20)) * 0.02
	var resolved := int(round(float(base_damage) * blood_multiplier))
	if boss_safe:
		resolved = int(round(float(resolved) * 0.70))
	return maxi(resolved, 1)


static func get_visual_intensity(health_percent_paid: int, completed_rites: int) -> float:
	return clampf(
		1.0 + float(clampi(health_percent_paid, 0, 20)) * 0.045 + float(maxi(completed_rites, 0)) * 0.08,
		1.0,
		3.2
	)


static func get_stagger_duration(mark_state_before_cast: int, boss_safe: bool) -> float:
	if boss_safe:
		return 0.10
	if mark_state_before_cast >= 3:
		return 0.42
	if mark_state_before_cast > 0:
		return 0.28
	return 0.16
