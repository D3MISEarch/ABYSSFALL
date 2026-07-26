extends RefCounted
class_name AbyssfallArtPalette

const ABYSS_BLACK := Color(0.006, 0.004, 0.010, 1.0)
const OBSIDIAN := Color(0.020, 0.018, 0.030, 1.0)
const DROWNED_STONE := Color(0.043, 0.046, 0.055, 1.0)
const WET_STONE := Color(0.070, 0.076, 0.086, 1.0)
const RUSTED_IRON := Color(0.115, 0.078, 0.058, 1.0)
const ANCIENT_METAL := Color(0.095, 0.088, 0.105, 1.0)
const BONE := Color(0.39, 0.36, 0.31, 1.0)
const BLOOD := Color(0.21, 0.012, 0.016, 1.0)
const VOID_VIOLET := Color(0.34, 0.025, 0.70, 1.0)
const VOID_FRACTURE := Color(0.62, 0.16, 1.0, 1.0)
const GRAVITATIONAL_WHITE := Color(0.82, 0.84, 1.0, 1.0)
const CORRUPTION_GREEN := Color(0.22, 0.48, 0.045, 1.0)
const SICKNESS_GREEN := Color(0.37, 0.68, 0.075, 1.0)


static func stone(color: Color = DROWNED_STONE, wetness: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = lerpf(0.88, 0.48, clampf(wetness, 0.0, 1.0))
	material.metallic = 0.02
	return material


static func metal(color: Color = ANCIENT_METAL, rust: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color.lerp(RUSTED_IRON, clampf(rust, 0.0, 1.0))
	material.roughness = lerpf(0.48, 0.86, clampf(rust, 0.0, 1.0))
	material.metallic = lerpf(0.72, 0.28, clampf(rust, 0.0, 1.0))
	return material


static func bone() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = BONE
	material.roughness = 0.92
	return material


static func emissive(color: Color, energy: float = 1.0, roughness: float = 0.24) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = maxf(energy, 0.0)
	return material


static func translucent(color: Color, alpha: float, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))
	material.roughness = 0.70
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.no_depth_test = false
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
