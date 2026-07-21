class_name ClassIds
extends RefCounted

const PENITENT := "penitent"
const VOID_WARLOCK := "void_warlock"

const ALL: Array[String] = [
	PENITENT,
	VOID_WARLOCK,
]


static func is_valid(class_id: String) -> bool:
	return ALL.has(class_id.strip_edges())
