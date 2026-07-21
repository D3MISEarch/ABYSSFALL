class_name ItemInstance
extends RefCounted

var instance_id: String = ""
var definition_id: StringName = &""
var quantity: int = 1
var affixes: Array[Dictionary] = []
var durability: float = 1.0


func _init(p_definition_id: StringName = &"", p_quantity: int = 1) -> void:
	instance_id = "%s-%s" % [Time.get_unix_time_from_system(), randi()]
	definition_id = p_definition_id
	quantity = maxi(1, p_quantity)


func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"definition_id": String(definition_id),
		"quantity": quantity,
		"affixes": affixes.duplicate(true),
		"durability": durability,
	}


static func from_dict(data: Dictionary) -> ItemInstance:
	var item := ItemInstance.new(StringName(str(data.get("definition_id", ""))), int(data.get("quantity", 1)))
	item.instance_id = str(data.get("instance_id", item.instance_id))
	item.affixes = Array(data.get("affixes", [])).duplicate(true)
	item.durability = clampf(float(data.get("durability", 1.0)), 0.0, 1.0)
	return item
