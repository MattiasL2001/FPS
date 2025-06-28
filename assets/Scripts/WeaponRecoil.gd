extends Object
class_name WeaponRecoil

@export var base_spread: float = 0.005
@export var max_spread: float = 0.03
@export var spread_increase: float = 0.005
@export var spread_decay: float = 2.0

var current_spread: float = base_spread

func get_spread_direction(original_dir: Vector3, aiming: bool) -> Vector3:
	var spread_angle = base_spread
	if not aiming:
		var spread = clamp(current_spread, base_spread, max_spread)
		spread_angle = spread

	# Rotera riktningen slumpmässigt inom en kon
	var random_rotation = Basis()
	random_rotation = random_rotation.rotated(Vector3.UP, randf_range(-spread_angle, spread_angle))
	random_rotation = random_rotation.rotated(Vector3.RIGHT, randf_range(-spread_angle, spread_angle))
	var new_dir = (random_rotation * original_dir).normalized()

	if not aiming:
		current_spread += spread_increase

	return new_dir

func decay(delta: float) -> void:
	if current_spread > base_spread:
		current_spread = max(base_spread, current_spread - spread_decay * delta)

func reset() -> void:
	current_spread = base_spread
