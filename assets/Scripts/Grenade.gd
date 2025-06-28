extends RigidBody3D
class_name Grenade

@export var force: float = 10.0
@export var radius: float = 5.0
@export var explodeTime: float = 4.0
@export var ghostTime: float = 0.5
@onready var audio = $Audio
@onready var explosionEffect = $Explosion

var stopped := false

func _ready():
	linear_damp = .5
	angular_damp = 1
	$ExplosionRadius.get_node("CollisionShape3D").shape.radius = radius
	$EnemyDetector.body_entered.connect(_on_enemy_touched)
	await get_tree().create_timer(explodeTime).timeout
	_explode()

func _throw(throw_direction: Vector3):
	sleeping = false
	freeze = false
	apply_impulse((throw_direction + Vector3.UP * 0.5).normalized() * force, Vector3.ZERO)

func _on_enemy_touched(body):
	if stopped:
		return

	if body.is_in_group("Enemies") or body.is_in_group("Player"):
		stopped = true
		await get_tree().create_timer(ghostTime).timeout

func _explode():
	explosionEffect.restart()
	audio.play()

	var origin = global_transform.origin
	var space_state = get_world_3d().direct_space_state

	for body in $ExplosionRadius.get_overlapping_bodies():
		if body.is_in_group("Enemies"):

			var points = [
				body.global_transform.origin,
				body.global_transform.origin + Vector3(0, 0.5, 0),
				body.global_transform.origin + Vector3(0, 1.0, 0),
				body.global_transform.origin + Vector3(0, 1.5, 0)
			]

			var hit_visible = false

			for point in points:
				var query = PhysicsRayQueryParameters3D.create(origin, point)
				query.exclude = [self]
				query.collide_with_bodies = true
				query.collide_with_areas = false

				var result = space_state.intersect_ray(query)
				if result and result.collider == body:
					hit_visible = true
					break

			if hit_visible:
				var distance = origin.distance_to(body.global_transform.origin)
				var damage = 1000 * (1 - clamp(distance / radius, 0, 1))
				body.take_damage(damage)
				print("Enemy hit: " + str(body) + ", Damage dealt: " + str(damage))

	self.visible = false
	await audio.finished
	queue_free()
