extends RefCounted
class_name InputPromptProfile

const KEYBOARD_MOUSE := "keyboard_mouse"
const PLAYSTATION := "playstation"
const XBOX := "xbox"


static func profile_for_joy_name(joy_name: String) -> String:
	var normalized := joy_name.strip_edges().to_lower()
	for token in ["dualsense", "dual sense", "dualshock", "playstation", "ps4", "ps5", "sony"]:
		if normalized.contains(token):
			return PLAYSTATION
	return XBOX


static func connected_profile() -> String:
	var fallback := KEYBOARD_MOUSE
	for device_id in Input.get_connected_joypads():
		var profile := profile_for_joy_name(Input.get_joy_name(device_id))
		if profile == PLAYSTATION:
			return PLAYSTATION
		fallback = XBOX
	return fallback


static func profile_for_event(event: InputEvent) -> String:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return profile_for_joy_name(Input.get_joy_name(event.device))
	if event is InputEventKey or event is InputEventMouseButton:
		return KEYBOARD_MOUSE
	return ""


static func build_hint(class_id: String, profile: String, resource_name: String) -> String:
	if class_id == "void_warlock":
		return _build_warlock_hint(profile)
	return _build_penitent_hint(profile, resource_name)


static func _build_warlock_hint(profile: String) -> String:
	match profile:
		PLAYSTATION:
			return "TRIANGLE: INVENTORY   SQUARE: SKILL TREE   CIRCLE: INTERACT   R1: VOID BOLT   L1: RIFT   CROSS: SHADOW STEP"
		XBOX:
			return "Y: INVENTORY   X: SKILL TREE   B: INTERACT   RB: VOID BOLT   LB: RIFT   A: SHADOW STEP"
		_:
			return "I: INVENTORY   T: SKILL TREE   E: INTERACT   LMB: VOID BOLT   RMB / Q: RIFT   SPACE: SHADOW STEP"


static func _build_penitent_hint(profile: String, resource_name: String) -> String:
	var resource_copy := resource_name.to_upper()
	match profile:
		PLAYSTATION:
			return "PENITENT   R1: BLADE   R3: BRAND (12)   L1: SEAL (18)   L3: CHAIN (14)   D-PAD DOWN: SACRAMENT (40+)   CROSS: DODGE   %s" % resource_copy
		XBOX:
			return "PENITENT   RB: BLADE   R3: BRAND (12)   LB: SEAL (18)   L3: CHAIN (14)   D-PAD DOWN: SACRAMENT (40+)   A: DODGE   %s" % resource_copy
		_:
			return "PENITENT   LMB: BLADE   F: BRAND (12)   Q: SEAL (18)   C: CHAIN (14)   V: SACRAMENT (40+)   SPACE: DODGE   %s" % resource_copy
