extends Weapon
class_name RangedWeapon

@export var fire_rate: float = 0.5
@export var fire_range: float = 50.0
@export var clip_size: int = 30
@export var reload_rate: float = 2.0
@export var ammo_total: int = 90
@export var is_scoped: bool = false
@export var aim_fov: float = 60.0
@export var camera_shake: float = 0.02
@export var ads_position: Vector3 = Vector3(0, -0.1, -0.15)
@export var ads_rotation: Vector3 = Vector3(0, -90, 0)
@export var ads_speed: float = 20.0
@export var recoil_strength: float = 0.05
@export var recoil_recovery_speed: float = 10.0

@onready var sway_pivot: Node3D = get_node("../")
@onready var muzzle: GPUParticles3D = get_node_or_null("Muzzle")
@onready var raycast: RayCast3D = get_node("../../RayCastShooting")
@onready var reloading_ui = get_node("../../UI/Reloading")
@onready var bullet_hole = preload("res://assets/Scenes/Bullet_Hole.tscn")

signal ammo_changed

var current_ammo: int = 0
var is_aiming: bool = false
var original_fov: float = 70.0
var camera_position: Vector3
var can_fire: bool = true
var reloading: bool = false
var tween_finished: bool = true
var _original_position: Vector3
var _original_rotation: Vector3
var scope_hide_delay := 0.05
var fire_timer: Timer
var scope_hide_timer: Timer
var reload_timer: Timer

func _ready():
	_set_layer_recursively(self)
	_original_position = position
	_original_rotation = rotation
	if camera:
		original_fov = camera.fov
		camera_position = camera.position
	
	fire_timer = Timer.new()
	fire_timer.one_shot = true
	add_child(fire_timer)
	fire_timer.connect("timeout", Callable(self, "_on_fire_timer_timeout"))

	scope_hide_timer = Timer.new()
	scope_hide_timer.one_shot = true
	scope_hide_timer.wait_time = scope_hide_delay
	add_child(scope_hide_timer)

	reload_timer = Timer.new()
	reload_timer.one_shot = true
	add_child(reload_timer)

	current_ammo = clip_size
	emit_signal("ammo_changed", current_ammo, ammo_total)
	raycast.set_target_position(Vector3(0, 0, -fire_range))
	reloading_ui.visible = false

func _process(delta):
	if is_active:
		# Hantera position
		var target_pos: Vector3
		if is_aiming:
			target_pos = ads_position
		else:
			target_pos = _original_position
		position = position.lerp(target_pos, delta * ads_speed)

		# Hantera rotation
		var target_rot: Vector3
		if is_aiming:
			target_rot = Vector3(
				deg_to_rad(ads_rotation.x),
				deg_to_rad(ads_rotation.y),
				deg_to_rad(ads_rotation.z)
			)
		else:
			target_rot = _original_rotation

		rotation.x = lerp_angle(rotation.x, target_rot.x, delta * ads_speed)
		rotation.y = lerp_angle(rotation.y, target_rot.y, delta * ads_speed)
		rotation.z = lerp_angle(rotation.z, target_rot.z, delta * ads_speed)

		# Kamera-FOV för sikt
		if camera and can_aim:
			var target_fov = aim_fov if is_aiming else original_fov
			camera.fov = lerp(camera.fov, target_fov, delta * ads_speed)

		# Recoil recovery
		sway_pivot.position = sway_pivot.position.lerp(Vector3.ZERO, delta * recoil_recovery_speed)

func _physics_process(delta):
	if not is_active:
		return

	if Input.is_action_pressed("mouseClick") and can_fire and not reloading:
		if current_ammo > 0:
			_fire()
			can_fire = false
			fire_timer.wait_time = fire_rate
			fire_timer.start()
		elif ammo_total > 0:
			_reloading()
	elif Input.is_action_just_pressed("reload") and current_ammo < clip_size and ammo_total > 0:
		_reloading()
	else:
		camera.position = camera_position

func update_aim_state():
	if not player:
		return

	if is_aiming:
		player.crosshair.visible = false
		if is_scoped:
			player.sniper_scope.visible = true
	else:
		player.crosshair.visible = true
		player.sniper_scope.visible = false

func _fire():
	if audio:
		audio.play()
	if sway_pivot:
		sway_pivot.translate_object_local(Vector3(0, 0, -recoil_strength))
	if muzzle:
		muzzle.restart()

	var tween := create_tween()
	tween.finished.connect(func(): tween_finished = true)
	tween.set_ease(Tween.EASE_OUT)
	tween.TRANS_ELASTIC

	if tween_finished:
		tween.tween_property(get_node("../.."), "position:z", 0.01, 0.1)
		tween_finished = false

	check_collision()
	can_fire = false
	current_ammo -= 1
	emit_signal("ammo_changed", current_ammo, ammo_total)
	player.change_ammo_ui()

func _on_fire_timer_timeout():
	if is_active:
		can_fire = true

func _reloading():
	if reloading or current_ammo == clip_size:
		return

	reloading = true
	reloading_ui.visible = true

	animation_player.speed_scale = 1.0 / reload_rate
	animation_player.play("Reloading")

	reload_timer.wait_time = reload_rate
	reload_timer.start()
	await reload_timer.timeout

	if not reloading or not is_active or not is_inside_tree():
		return

	reloading_ui.visible = false
	animation_player.stop()
	animation_player.speed_scale = 1

	var needed = clip_size - current_ammo
	if ammo_total >= needed:
		ammo_total -= needed
		current_ammo = clip_size
	elif ammo_total > 0:
		current_ammo += ammo_total
		ammo_total = 0

	emit_signal("ammo_changed", current_ammo, ammo_total)
	player.change_ammo_ui()
	reloading = false

func cancel_reload():
	if reloading:
		reloading = false

		if reload_timer and reload_timer.time_left > 0:
			reload_timer.stop()

		if animation_player and animation_player.is_playing():
			animation_player.stop()

		if reloading_ui:
			reloading_ui.visible = false

func set_aiming(state: bool) -> void:
	if not can_aim:
		return
	is_aiming = state
	if is_scoped:
		if is_aiming:
			scope_hide_timer.start()
			scope_hide_timer.timeout.connect(func():
				if is_aiming:
					visible = false
			)
		else:
			scope_hide_timer.stop()
			visible = true

func check_collision():
	if raycast.is_colliding():
		var collider: CollisionObject3D = raycast.get_collider()
		var shape_index: int = raycast.get_collider_shape()

		# Hämta vilken shape-nod som träffats
		var owner_id = collider.shape_find_owner(shape_index)
		var hit_node = collider.shape_owner_get_owner(owner_id)

		if collider.is_in_group("Enemies"):
			if hit_node and hit_node.is_in_group("Head"):
				collider.kill()
			elif hit_node and hit_node.is_in_group("Body"):
				collider.take_damage(damage)

		elif !collider.is_in_group("Player"):
			var b_h = bullet_hole.instantiate()
			collider.get_node("../").get_node("../").add_child(b_h)
			b_h.global_transform.origin = raycast.get_collision_point()
			b_h.rotate_y(raycast.get_rotation().y)
			b_h.look_at(raycast.get_collision_point() + raycast.get_collision_normal(), Vector3.UP)

func check_array_col() -> bool:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		return collider != null and collider.is_in_group("Enemies")
	return false
