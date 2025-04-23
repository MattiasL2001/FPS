extends CharacterBody3D

@export var health : int = 100
@export var original_speed : float = 4
@export var crouch_speed : float = 1
@export var sprint_speed : float = 7
var at_start_falling_position : bool = true
var start_y_position : float
var speed = original_speed
var agility : float = 1
var can_jump : bool = true
var is_running : bool = false
@export var acceleration = 15
@export var gravity = 50
var crouch_gravity = gravity * 1.5
@export var jump_power = 15
@export var inertia = 100
@export var current_weapon : Weapon
@export var mouse_sensitivity : float = 0.15
var zoom_sensitivity_multiplier := 1.0
var weapon_switch : bool = true
var grenade_ammo : int = 1
@export var first_weapon : Node3D
@export var second_weapon : Node3D
@onready var grenade_packed = preload("res://assets/Scenes/Grenade.tscn")
@onready var grenade = grenade_packed.instantiate()

@onready var walking : AudioStream = preload("res://assets/Sounds/walking.wav")
@onready var running : AudioStream = preload("res://assets/Sounds/running.wav")

@export var direction : Vector3
@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera
@onready var gun_cam : Camera3D = $Head/Camera/SubViewportContainer/SubViewport/GunCamera
@onready var interact_text = $Head/Camera/UI/interact_text
@onready var crosshair = $Head/Camera/UI/CC/Crosshair
@onready var sniper_scope = $Head/Camera/UI/SniperScope
@onready var audio : AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var interact_raycast : RayCast3D = $Head/Camera/RayCastInteraction
@onready var raycast_shooting : RayCast3D = $Head/Camera/RayCastShooting
@onready var fall_damage_threshold = 5
signal speed_changed
signal timer_finished
signal update_transform
signal health_changed
signal ammo_changed
signal weapon_changed

var camera_x_rotation = 0

func _ready():
	first_weapon = $Head/Camera/Hand/FirstWeapon
	second_weapon = $Head/Camera/Hand/SecondWeapon
	current_weapon = first_weapon
	raycast_shooting.set_target_position(Vector3(0, 0, -first_weapon.fire_range))
	second_weapon.visible = false
	emit_signal("speed_changed", speed)
	emit_signal("health_changed", health)
	emit_signal("weapon_changed", current_weapon.weapon_class)
	change_ammo_ui()
	_updater()

func _input(event):
	if event is InputEventMouseMotion:
		var multiplier = zoom_sensitivity_multiplier
		self.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity * multiplier))
		var x_delta = event.relative.y * mouse_sensitivity * multiplier
		if camera_x_rotation + x_delta > -90 and camera_x_rotation + x_delta < 90:
			camera.rotate_x(deg_to_rad(-x_delta))
			camera_x_rotation += x_delta

	if event.is_action_pressed("aim"):
		if current_weapon:
			current_weapon.set_aiming(true)
	elif event.is_action_released("aim"):
		if current_weapon:
			current_weapon.set_aiming(false)

	if event is InputEventMouseButton:
		if event.button_index == 4 or event.button_index == 5:
			_weapon_switch()

func _updater():
	var hit = false

	if (current_weapon == first_weapon 
	and first_weapon.check_array_col()) or (current_weapon == second_weapon 
	and second_weapon.check_array_col()):
		hit = true

	crosshair.call("set_targeting_state", hit)

	await get_tree().create_timer(0.1).timeout
	_updater()

func _process(delta):
	gun_cam.global_transform = camera.global_transform
	if Input.is_action_pressed("Grenade") and get_node("../Grenade") != null and grenade_ammo > 0:
		get_node("../Grenade").set_position(
		Vector3(to_global(get_node("Head/Camera/Grenade_Pos").get_position())))

func _physics_process(delta):
	var rotation = head.global_transform.basis.get_euler().y
	emit_signal("update_transform", get_position(), rotation)
	
	var head_basis = head.get_global_transform().basis
	direction = Vector3()

	if (Input.is_action_pressed("move_fw")):
		direction -= head_basis.z
	elif (Input.is_action_pressed("move_bw")):
		direction += head_basis.z

	if (Input.is_action_pressed("move_l")):
		direction -= head_basis.x
	elif (Input.is_action_pressed("move_r")):
		direction += head_basis.x

	if (abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1) and !audio.playing:
		audio.stop()
		if !is_running:
			audio.stream = walking
		else:
			audio.stream = running
		audio.play(0)
	elif (abs(velocity.x) < 0.1 and abs(velocity.z) < 0.1) or !is_on_floor():
		audio.stop()

	if (Input.is_action_just_pressed("shift")):
		audio.stop()
		audio.stream = running
		audio.play()
	elif Input.is_action_just_released("shift"):
		audio.stop()
		audio.stream = walking
		audio.play()

	if !is_on_floor() and velocity.y < 0 and at_start_falling_position:
		at_start_falling_position = false
		start_y_position = get_position().y

	if is_on_floor():
		var end_y_position : float = get_position().y
		var height : float = start_y_position - end_y_position
		start_y_position = end_y_position
		if height > 5:
			damage(round(pow(height, 2) * 0.3))

	if Input.is_action_pressed("jump") and is_on_floor() and can_jump:
		_jump()

	var is_aiming = current_weapon.is_aiming if current_weapon else false

	if is_aiming:
		speed = original_speed * .5
		crosshair.visible = false
		if current_weapon.is_scoped:
			sniper_scope.visible = true
	elif Input.is_action_pressed("shift"):
		speed = sprint_speed
		is_running = true
		crosshair.visible = true
		sniper_scope.visible = false
	elif Input.is_action_pressed("ctrl"):
		speed = crouch_speed
		crosshair.visible = true
		sniper_scope.visible = false
	else:
		speed = original_speed
		crosshair.visible = true
		sniper_scope.visible = false

	# Korrigera mushastighet baserat på zoom
	if current_weapon and current_weapon.is_aiming:
		var base_fov = 70.0
		var current_fov = current_weapon.camera.fov
		zoom_sensitivity_multiplier = clamp(current_fov / base_fov, 0.2, 1.0)
	else:
		zoom_sensitivity_multiplier = 1.0

	direction = direction.normalized()
	velocity = Vector3(speed * direction.x, velocity.y, speed * direction.z)

	if is_on_floor():
		agility = 1
	else:
		agility = 1.05
		velocity.y -= self.gravity * delta

	velocity = Vector3(velocity.x * agility, velocity.y, velocity.z * agility)
	velocity.lerp(direction * speed, 0.5)
	move_and_slide()

func _jump():
	can_jump = false
	velocity.y += jump_power
	await get_tree().create_timer(.5).timeout
	can_jump = true

func _weapon_switch():
	get_node("Head/Camera/UI/Reloading").visible = false

	if weapon_switch:
		if current_weapon == first_weapon:
			current_weapon = second_weapon
			emit_signal("weapon_changed", current_weapon.weapon_class)
			first_weapon.is_active = false
			second_weapon.is_active = true
			first_weapon.visible = false
			second_weapon.visible = true
			first_weapon.reloading = false
			second_weapon.is_aiming = false
			second_weapon.emit_signal("ammo_changed", second_weapon.current_ammo, second_weapon.ammo_total)
			raycast_shooting.set_target_position(Vector3(0, 0, -second_weapon.fire_range))
			change_ammo_ui()
			weapon_switch = false
		elif current_weapon == second_weapon:
			current_weapon = first_weapon
			emit_signal("weapon_changed", current_weapon.weapon_class)
			first_weapon.is_active = true
			second_weapon.is_active = false
			first_weapon.visible = true
			second_weapon.visible = false
			second_weapon.reloading = false
			first_weapon.is_aiming = false
			first_weapon.emit_signal("ammo_changed", first_weapon.current_ammo, first_weapon.ammo_total)
			raycast_shooting.set_target_position(Vector3(0, 0, -first_weapon.fire_range))
			change_ammo_ui()
			weapon_switch = false
		await get_tree().create_timer(.3).timeout
		weapon_switch = true

func damage(damage):
	health -= damage
	if health < 0:
		health = 0
	emit_signal("health_changed", health)

func change_ammo_ui():
	if current_weapon == first_weapon:
		emit_signal("ammo_changed", first_weapon.current_ammo, first_weapon.ammo_total)
	elif current_weapon == second_weapon:
		emit_signal("ammo_changed", second_weapon.current_ammo, second_weapon.ammo_total)

func _on_Area_body_entered(body):
	if body != self:
		pass

func check_collision():
	if interact_raycast.is_colliding():
		var collider = interact_raycast.get_collider()
		if collider.is_in_group("Interact"):
			if interact_text.is_visible() == false:
				interact_text.set_visible(true)
	else:
		interact_text.set_visible(false)

func _on_Timer_timeout():
	emit_signal("timer_finished")

func _on_Interact_Timer_timeout():
	check_collision()
