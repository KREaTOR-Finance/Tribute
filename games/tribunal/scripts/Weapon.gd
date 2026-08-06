# Weapon.gd
# Basic equippable weapon system for melee focus.
# Different weapons have different attack profiles (damage, cooldowns, windup, knockback).
# Attach to Player or equip via script.
# Supports light jab and heavy attack profiles.
# For now: simple class with data; later can be Resource or scene with visuals.

extends Node
class_name Weapon

enum WeaponType {
	SWORD,   # Balanced, fast light, decent heavy
	AXE,     # Slow but powerful heavy, good knockback
	DAGGER,  # Very fast light, weak heavy
	SPEAR    # Longer range (future), medium
}

@export var weapon_type: WeaponType = WeaponType.SWORD
@export var weapon_name: String = "Sword"

# Base profiles — these override or modify PlayerController values when equipped
var light_damage: int = 12
var light_cooldown: float = 0.35
var heavy_damage: int = 35
var heavy_windup: float = 0.55
var heavy_cooldown: float = 0.9
var knockback_multiplier: float = 1.0
# Reach — absolute meters used by PlayerController._melee_shape_query
# Distinct tools: dagger short, sword mid, axe mid-short/wide, spear long
var range_mul: float = 1.0  # legacy scale (kept for any external reads)
var light_reach: float = 1.35
var heavy_reach: float = 1.65
var hit_radius_light: float = 0.55
var hit_radius_heavy: float = 0.70
# Optional horizontal sweep half-angle scale (1.0 = default sphere feel)
var arc: float = 1.0

# Visual / future
var mesh_path: String = ""

func _ready():
	_apply_profile()

func _apply_profile():
	match weapon_type:
		WeaponType.SWORD:
			weapon_name = "Sword"
			light_damage = 12
			light_cooldown = 0.32
			heavy_damage = 32
			heavy_windup = 0.50
			heavy_cooldown = 0.85
			knockback_multiplier = 1.1
			range_mul = 1.0
			light_reach = 1.35
			heavy_reach = 1.65
			hit_radius_light = 0.55
			hit_radius_heavy = 0.70
			arc = 1.0
		WeaponType.AXE:
			weapon_name = "Axe"
			light_damage = 15
			light_cooldown = 0.55
			heavy_damage = 48
			heavy_windup = 0.75
			heavy_cooldown = 1.15
			knockback_multiplier = 1.8   # Brutal knockback
			range_mul = 0.88
			light_reach = 1.22
			heavy_reach = 1.52
			hit_radius_light = 0.62
			hit_radius_heavy = 0.82
			arc = 1.18
		WeaponType.DAGGER:
			weapon_name = "Dagger"
			light_damage = 8
			light_cooldown = 0.18
			heavy_damage = 22
			heavy_windup = 0.35
			heavy_cooldown = 0.55
			knockback_multiplier = 0.7
			range_mul = 0.72
			light_reach = 1.05
			heavy_reach = 1.20
			hit_radius_light = 0.42
			hit_radius_heavy = 0.52
			arc = 0.82
		WeaponType.SPEAR:
			weapon_name = "Spear"
			light_damage = 14
			light_cooldown = 0.40
			heavy_damage = 38
			heavy_windup = 0.60
			heavy_cooldown = 0.95
			knockback_multiplier = 1.3
			range_mul = 1.25
			light_reach = 1.70
			heavy_reach = 2.05
			hit_radius_light = 0.48
			hit_radius_heavy = 0.58
			arc = 0.68

	print("Equipped: ", weapon_name, " (type: ", WeaponType.keys()[weapon_type], ") reach L/H=", light_reach, "/", heavy_reach)

# These getters are used by PlayerController when a weapon is equipped
func get_light_damage() -> int:
	return light_damage

func get_light_cooldown() -> float:
	return light_cooldown

func get_heavy_damage() -> int:
	return heavy_damage

func get_heavy_windup() -> float:
	return heavy_windup

func get_heavy_cooldown() -> float:
	return heavy_cooldown

func get_knockback_multiplier() -> float:
	return knockback_multiplier

func get_range_mul() -> float:
	return range_mul

func get_arc() -> float:
	return arc

func get_light_reach() -> float:
	return light_reach

func get_heavy_reach() -> float:
	return heavy_reach

func get_hit_radius(heavy: bool) -> float:
	return hit_radius_heavy if heavy else hit_radius_light

# Future: equip/unequip logic, visual mesh swap, attack animations per weapon
func equip(new_type: WeaponType):
	weapon_type = new_type
	_apply_profile()

func unequip():
	# Reset to default or nothing
	pass
