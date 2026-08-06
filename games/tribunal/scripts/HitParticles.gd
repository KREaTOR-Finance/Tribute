# HitParticles.gd
# Simple, juicy hit impact particles for melee hits (light vs heavy).
# Attach this as a child of the Player or as a reusable scene.
# Call spawn_hit(position, normal, is_heavy) when a hit lands.

extends Node3D
class_name HitParticles

@export var light_particle_count: int = 12
@export var heavy_particle_count: int = 28
@export var particle_lifetime: float = 0.35
@export var particle_speed: float = 6.0

@onready var particles: CPUParticles3D = $CPUParticles3D

func _ready():
	if not particles:
		_create_particles()

func _create_particles():
	particles = CPUParticles3D.new()
	particles.name = "CPUParticles3D"
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = particle_lifetime
	particles.amount = heavy_particle_count
	particles.local_coords = true
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = particle_speed * 0.6
	particles.initial_velocity_max = particle_speed * 1.3
	particles.gravity = Vector3(0, -9.8, 0)
	particles.scale_amount_min = 0.08
	particles.scale_amount_max = 0.18
	particles.color = Color(1.0, 0.85, 0.3, 0.9)  # Warm impact color
	add_child(particles)

func spawn_hit(world_pos: Vector3, normal: Vector3 = Vector3.UP, is_heavy: bool = false):
	if not particles:
		_create_particles()

	# Position at impact
	global_position = world_pos

	# Orient particles roughly along the hit normal
	look_at(world_pos + normal, Vector3.UP)

	# Configure burst
	particles.amount = heavy_particle_count if is_heavy else light_particle_count
	particles.initial_velocity_min = particle_speed * (1.0 if is_heavy else 0.6)
	particles.initial_velocity_max = particle_speed * (1.4 if is_heavy else 1.0)
	particles.scale_amount_min = 0.12 if is_heavy else 0.06
	particles.scale_amount_max = 0.25 if is_heavy else 0.15
	particles.color = Color(1.0, 0.6, 0.2, 0.95) if is_heavy else Color(1.0, 0.9, 0.5, 0.85)

	# Fire the burst
	particles.restart()
	particles.emitting = true

	# Auto-clean after lifetime + margin
	await get_tree().create_timer(particle_lifetime + 0.6).timeout
	if is_inside_tree():
		queue_free()  # one-shot per hit (create fresh instances for many hits)