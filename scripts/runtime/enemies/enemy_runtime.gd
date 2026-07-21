class_name EnemyRuntime
extends RefCounted

signal died(enemy_id: StringName)

var enemy_id: StringName = &"enemy"
var level: int = 1
var maximum_health: float = 50.0
var current_health: float = 50.0
var armor: float = 0.0
var experience_reward: int = 10
var _death_emitted: bool = false


func configure(data: Dictionary) -> void:
	enemy_id = StringName(str(data.get("enemy_id", "enemy")))
	level = maxi(1, int(data.get("level", 1)))
	maximum_health = maxf(1.0, float(data.get("maximum_health", 50.0)))
	current_health = maximum_health
	armor = maxf(0.0, float(data.get("armor", 0.0)))
	experience_reward = maxi(0, int(data.get("experience_reward", 10)))
	_death_emitted = false


func apply_damage(amount: float) -> float:
	if is_dead():
		return 0.0
	var applied := clampf(amount, 0.0, current_health)
	current_health -= applied
	if is_dead() and not _death_emitted:
		_death_emitted = true
		died.emit(enemy_id)
	return applied


func is_dead() -> bool:
	return current_health <= 0.0
