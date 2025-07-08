extends Weapon
class_name MeleeWeapon

@export var melee_range: float = 1.5
@export var swing_cooldown: float = 0.5
@export var swing_anim_name: String = "MeleeSwing"

var can_swing := true
@onready var weapon_root: Node3D = self

func _ready():
	_set_layer_recursively(self)

func _physics_process(delta):
	if Input.is_action_just_pressed("mouseClick") and can_swing and is_active:
		_melee_attack()

func _melee_attack():
	can_swing = false

	if attack_audio:
		attack_audio.play()

	var start_pos: Vector3 = weapon_root.position
	var start_rot: Vector3 = weapon_root.rotation_degrees

	var stab_pos: Vector3 = start_pos + Vector3(0, 0, -0.2)
	var stab_rot: Vector3 = Vector3(60, -110, 0)

	var tween := create_tween()
	tween.tween_property(weapon_root, "rotation_degrees", stab_rot, 0.05)
	tween.tween_property(weapon_root, "position", stab_pos, 0.05)
	tween.tween_property(weapon_root, "rotation_degrees", start_rot, 0.1).set_delay(0.05)
	tween.tween_property(weapon_root, "position", start_pos, 0.1).set_delay(0.05)

	var origin = camera.global_transform.origin
	var direction = -camera.global_transform.basis.z
	var target = origin + direction * melee_range

	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [player]
	query.collision_mask = 1

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	if result:
		var collider = result.collider
		if collider and collider.is_in_group("Enemies"):
			collider = collider as Enemy
			collider.take_damage(damage)

	var mesh := ArrayMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.RED

	var verts = PackedVector3Array()
	verts.append(origin)
	verts.append(target)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)

	await get_tree().create_timer(swing_cooldown).timeout
	can_swing = true
