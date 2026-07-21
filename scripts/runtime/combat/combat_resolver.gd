class_name CombatResolver
extends RefCounted


static func resolve_damage(request: Dictionary) -> Dictionary:
	var base_damage: float = maxf(0.0, float(request.get("base_damage", 0.0)))
	var power: float = maxf(0.0, float(request.get("power", 0.0)))
	var coefficient: float = maxf(0.0, float(request.get("coefficient", 1.0)))
	var armor: float = maxf(0.0, float(request.get("armor", 0.0)))
	var resistance: float = clampf(float(request.get("resistance", 0.0)), -1.0, 0.90)
	var critical: bool = bool(request.get("critical", false))
	var critical_multiplier: float = maxf(1.0, float(request.get("critical_multiplier", 1.5)))

	var raw_damage := base_damage + power * coefficient
	if critical:
		raw_damage *= critical_multiplier

	var armor_reduction := armor / (armor + 100.0) if armor > 0.0 else 0.0
	var after_armor := raw_damage * (1.0 - armor_reduction)
	var final_damage := maxf(0.0, after_armor * (1.0 - resistance))

	return {
		"raw_damage": raw_damage,
		"armor_reduction": armor_reduction,
		"resistance": resistance,
		"critical": critical,
		"final_damage": final_damage,
	}
