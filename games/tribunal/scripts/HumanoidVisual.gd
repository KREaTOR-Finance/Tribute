# HumanoidVisual.gd
# Handles loading the low-poly humanoid model for players.
# Supports team coloring via modulate and proper hand attachment point.
# Attach this instead of (or in addition to) a static MeshInstance3D.

extends Node3D
class_name HumanoidVisual

@export var team_color: Color = Color(1, 0.4, 0.4, 1)  # Red default (P1)

var body_mesh_instance: MeshInstance3D

func _ready():
	_setup_body()

func _setup_body():
	# Create or find the MeshInstance3D for the humanoid
	body_mesh_instance = get_node_or_null("BodyMesh")
	if not body_mesh_instance:
		body_mesh_instance = MeshInstance3D.new()
		body_mesh_instance.name = "BodyMesh"
		add_child(body_mesh_instance)
	
	# Load the neutral humanoid glb (procedural low-poly, CC0-style)
	# Note: trimesh-exported glb loads as a single mesh in Godot when assigned this way.
	var humanoid_mesh = load("res://assets/models/characters/lowpoly_humanoid.glb")
	if humanoid_mesh:
		# Some glb exports from trimesh come as ArrayMesh when loaded directly in certain Godot versions
		# If it's a PackedScene, we take the first mesh child (common pattern)
		if humanoid_mesh is PackedScene:
			var instance = humanoid_mesh.instantiate()
			var found_mesh = _find_first_mesh(instance)
			if found_mesh:
				body_mesh_instance.mesh = found_mesh.mesh if found_mesh is MeshInstance3D else found_mesh
			instance.queue_free()
		else:
			body_mesh_instance.mesh = humanoid_mesh
	
	# Apply team color via modulate (works well for simple meshes)
	body_mesh_instance.modulate = team_color
	
	# Optional: slight scale tweak for better proportions in game
	body_mesh_instance.scale = Vector3(1.05, 1.05, 1.05)

func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_first_mesh(child)
		if result:
			return result
	return null

func set_team_color(color: Color):
	team_color = color
	if body_mesh_instance:
		body_mesh_instance.modulate = color

func get_body_mesh() -> MeshInstance3D:
	return body_mesh_instance
