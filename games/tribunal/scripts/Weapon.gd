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
# Reach multiplier applied in PlayerController._melee_shape_query
# Sword mid, axe slightly shorter, dagger shorter (faster profile already in cooldowns)
var range_mul: float = 1.0
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
			arc = 1.0
		WeaponType.AXE:
			weapon_name = "Axe"
			light_damage = 15
			light_cooldown = 0.55
			heavy_damage = 48
			heavy_windup = 0.75
			heavy_cooldown = 1.15
			knockback_multiplier = 1.8   # Brutal knockback
			range_mul = 0.88            # Slightly shorter, heavier
			arc = 1.15
		WeaponType.DAGGER:
			weapon_name = "Dagger"
			light_damage = 8
			light_cooldown = 0.18
			heavy_damage = 22
			heavy_windup = 0.35
			heavy_cooldown = 0.55
			knockback_multiplier = 0.7
			range_mul = 0.72            # Shorter, faster
			arc = 0.85
		WeaponType.SPEAR:
			weapon_name = "Spear"
			light_damage = 14
			light_cooldown = 0.40
			heavy_damage = 38
			heavy_windup = 0.60
			heavy_cooldown = 0.95
			knockback_multiplier = 1.3
			range_mul = 1.25
			arc = 0.7

	print("Equipped: ", weapon_name, " (type: ", WeaponType.keys()[weapon_type], ")")

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

# Future: equip/unequip logic, visual mesh swap, attack animations per weapon
func equip(new_type: WeaponType):
	weapon_type = new_type
	_apply_profile()

func unequip():
	# Reset to default or nothing
	pass
