# MeleeTestScene.gd
# Rapid melee feel iteration + local 2-player hotseat testing scene.
# This is the critical "prove the core loop" arena per the fusion decision.
#
# Controls for hotseat testing (start with number 7):
# Player 1 (default): WASD + Mouse look | LMB = Light Jab | RMB = Heavy (windup) | Space = Block | F = Shove
# Player 2 (hotseat): IJKL + Mouse (or second keyboard) | U = Light | O = Heavy | P = Block | ; = Shove
#
# WEAPON TESTING (melee-continue-2):
# Player 1: Press 1 = Sword, 2 = Axe, 3 = Dagger (changes attack profiles live)
# Player 2: Press 4 = Sword, 5 = Axe, 6 = Dagger
#
# Continued melee focus: Knockback, particles, and improved feedback now integrated.
# Camera: Press Tab (or ui_focus_next) to toggle between fixed overview and follow cam on P1.
# For true simultaneous: Plug in a second controller or use two keyboards.
#
# ASSETS: Real CC0 .blend sources + procedural .glb stand-ins are ready.
# WeaponVisual automatically shows the correct 3D weapon model when equipped.

extends Node3D

@export var use_hotseat: bool = true

@onready var player1: PlayerController = $Player1
@onready var player2: PlayerController = $Player2
@onready var arena_manager: ArenaManager = $ArenaManager

@onready var ui_layer: CanvasLayer = $UI
@onready var instructions_label: Label = $UI/InstructionsLabel
@onready var p1_status: Label = $UI/P1Status
@onready var p2_status: Label = $UI/P2Status
@onready var p1_weapon_label: Label = $UI/P1Weapon
@onready var p2_weapon_label: Label = $UI/P2Weapon

@onready var camera: Camera3D = $Camera3D
var follow_camera: FollowCamera = null

func _ready():
	print("=== THE CULLING - MELEE FEEL + LOCAL 2P TEST SCENE (ENHANCED) ===")
	print("Focus: Does every jab, heavy, block, and shove feel satisfying and weighty?")
	print("Per fusion: Prove this in the smallest arena before any big scope.")
	print("NEW: Knockback on hits, hit particles, improved windup/release tweens + flinch reactions.")
	print("WEAPONS: 1/2/3 for P1 (Sword/Axe/Dagger), 4/5/6 for P2")
	print("Camera: Tab to toggle fixed overview <-> follow cam on P1")
	print("ASSETS: Procedural .glb + real CC0 .blend sources in assets/models/. WeaponVisual swaps live models.")

	# Assign player ids for future input separation
	if player1:
		player1.player_id = 1
		# Give P1 a starting weapon for testing
		var starting_weapon = Weapon.new()
		starting_weapon.weapon_type = Weapon.WeaponType.SWORD
		starting_weapon._apply_profile()
		player1.equip_weapon(starting_weapon)
		player1.weapon_equipped.connect(_on_weapon_equipped.bind(player1, p1_weapon_label))
		# Sync 3D visual immediately
		_sync_weapon_visual(player1, 1)  # Sword
	if player2:
		player2.player_id = 2
		var starting_weapon2 = Weapon.new()
		starting_weapon2.weapon_type = Weapon.WeaponType.AXE
		starting_weapon2._apply_profile()
		player2.equip_weapon(starting_weapon2)
		player2.weapon_equipped.connect(_on_weapon_equipped.bind(player2, p2_weapon_label))
		_sync_weapon_visual(player2, 2)  # Axe

	# Register with arena for win conditions
	if arena_manager:
		if player1:
			arena_manager.register_player(player1)
		if player2:
			arena_manager.register_player(player2)

	# Setup camera follow (for better melee feel)
	if camera and camera.has_method("set_target"):
		follow_camera = camera as FollowCamera
		if follow_camera and player1:
			follow_camera.set_target(player1)

	# Setup UI
	_setup_ui()

	# Connect death signals for status
	if player1:
		player1.player_died.connect(_on_player_died.bind(player1))
	if player2:
		player2.player_died.connect(_on_player_died.bind(player2))

	print("Both players registered. Fight! Particles, reactions, weapon profiles and 3D visuals are live.")

func _setup_ui():
	if not ui_layer:
		return

	instructions_label.text = """MELEE FEEL TEST + LOCAL 2P HOTSEAT + WEAPONS (ENHANCED)
Player 1 (RED): WASD + Mouse | LMB=Light Jab | RMB=Heavy | Space=Block | F=Shove
Player 2 (BLUE): IJKL + Mouse | U=Light | O=Heavy | P=Block | ;=Shove

WEAPON SWAP (test profiles live):
P1: 1=Sword (balanced) | 2=Axe (heavy knockback) | 3=Dagger (fast light)
P2: 4=Sword | 5=Axe | 6=Dagger

Focus: Prove the core loop feels incredible here first.
Knockback, hit particles, improved reactions + tweens + real 3D weapon models are LIVE.
Press TAB to toggle fixed cam <-> follow cam on P1 (better melee feel).
Tweak @export values on Player1/Player2 in the inspector while the game runs!
Assets (CC0 + procedural) ready in assets/models/ — WeaponVisual swaps them."""

	# Create weapon labels if not present in scene (we'll add them via code for robustness)
	if not p1_weapon_label:
		p1_weapon_label = Label.new()
		p1_weapon_label.position = Vector2(20, 260)
		ui_layer.add_child(p1_weapon_label)
	if not p2_weapon_label:
		p2_weapon_label = Label.new()
		p2_weapon_label.position = Vector2(20, 285)
		ui_layer.add_child(p2_weapon_label)

	p1_weapon_label.modulate = Color(1, 0.4, 0.4, 1)
	p2_weapon_label.modulate = Color(0.4, 0.6, 1, 1)

func _process(_delta):
	_update_status()

func _update_status():
	if p1_status and player1:
		p1_status.text = "P1 HP: %d  STA: %d" % [player1.health, player1.stamina]
	if p2_status and player2:
		p2_status.text = "P2 HP: %d  STA: %d" % [player2.health, player2.stamina]

func _on_weapon_equipped(weapon_name: String, player: PlayerController, label: Label):
	if label:
		label.text = "%s Weapon: %s" % [player.name, weapon_name]
	print(player.name, " now using: ", weapon_name)
	# Update the 3D visual on the player's hand
	var wtype = 0
	if "Sword" in weapon_name or "sword" in weapon_name.to_lower():
		wtype = 1
	elif "Axe" in weapon_name or "axe" in weapon_name.to_lower():
		wtype = 2
	elif "Dagger" in weapon_name or "dagger" in weapon_name.to_lower():
		wtype = 3
	_sync_weapon_visual(player, wtype)

func _sync_weapon_visual(player: PlayerController, wtype: int):
	if not player:
		return
	var hand = player.get_node_or_null("Hand")
	if hand:
		var wv = hand.get_node_or_null("WeaponVisual")
		if wv and wv.has_method("set_weapon_type"):
			wv.set_weapon_type(wtype)
			print("  -> WeaponVisual updated to type ", wtype, " for ", player.name)

func _on_player_died(player: PlayerController):
	print(player.name, " has been eliminated!")
	if arena_manager:
		# ArenaManager already listens via signal, this is extra logging
		pass

func _on_match_ended(winner):
	print("MATCH ENDED — Winner:", winner.name if winner else "Draw")
