extends CharacterBody3D
class_name Player

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
var current_weapon : Weapon
@export var mouse_sensitivity : float = 0.15
var zoom_sensitivity_multiplier := 1.0
var weapon_switch : bool = true
var grenade_ammo : int = 100
@export var first_weapon : RangedWeapon
@export var second_weapon : RangedWeapon
@export var melee_weapon: MeleeWeapon
var all_weapons: Array[Weapon] = []
var current_weapon_index: int = 0

@onready var grenade_packed = preload("res://assets/Scenes/Grenade.tscn")

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
@onready var enemy_trigger_area: Area3D = $EnemyTriggerArea
@onready var minimap_camera: Camera3D = $Head/Camera/UI/ViewportContainer/Viewport/MinimapCamera

var interact_timer: Timer
var interact_target: Interactable = null

signal speed_changed
signal timer_finished
signal update_transform
signal health_changed
signal ammo_changed
signal weapon_changed
signal enemy_entered(enemy: Enemy)
signal enemy_exited(enemy: Enemy)

var camera_x_rotation = 0

func _ready():
	first_weapon = $Head/Camera/Hand/FirstWeapon
	second_weapon = $Head/Camera/Hand/SecondWeapon
	melee_weapon = $Head/Camera/Hand/MeleeWeapon
	all_weapons = [first_weapon, second_weapon, melee_weapon]
	current_weapon_index = 0
	_activate_weapon(current_weapon_index)
	
	interact_timer = Timer.new()
	interact_timer.wait_time = 0.2
	interact_timer.one_shot = false
	interact_timer.autostart = true
	add_child(interact_timer)
	interact_timer.timeout.connect(check_collision)
	
	enemy_trigger_area.body_entered.connect(_on_enemy_trigger_entered)
	enemy_trigger_area.body_exited.connect(_on_enemy_trigger_exited)

	raycast_shooting.set_target_position(Vector3(0, 0, -first_weapon.fire_range))
	second_weapon.visible = false
	emit_signal("speed_changed", speed)
	emit_signal("health_changed", health)
	emit_signal("weapon_changed", current_weapon.weapon_type)
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

	if event.is_action_pressed("aim") and current_weapon.has_method("set_aiming"):
		current_weapon.set_aiming(true)
	elif event.is_action_released("aim") and current_weapon.has_method("set_aiming"):
		current_weapon.set_aiming(false)

	if event.is_action_pressed("interact"):
		if interact_target:
			interact_target.interact_with(self)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_weapon_switch(1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_weapon_switch(-1)

func _updater():
	var hit = false
	if current_weapon is RangedWeapon and current_weapon.check_array_col():
		hit = true
	crosshair.call("set_targeting_state", hit)
	await get_tree().create_timer(0.1).timeout
	_updater()

func _process(delta):
	gun_cam.global_transform = camera.global_transform
	minimap_camera.set_position(Vector3(position.x, position.y + 100, position.z))
	minimap_camera.set_rotation(Vector3(minimap_camera.rotation.x, rotation.y, rotation.z))

	if Input.is_action_just_pressed("Grenade"):
		throw_grenade()

func _physics_process(delta):
	var rotation = head.global_transform.basis.get_euler().y
	emit_signal("update_transform", get_position(), rotation)
	var head_basis = head.get_global_transform().basis

	direction = Vector3()
	if Input.is_action_pressed("move_fw"):
		direction -= head_basis.z
	if Input.is_action_pressed("move_bw"):
		direction += head_basis.z
	if Input.is_action_pressed("move_l"):
		direction -= head_basis.x
	if Input.is_action_pressed("move_r"):
		direction += head_basis.x
	direction = direction.normalized()

	if (abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1) and !audio.playing:
		audio.stop()
		audio.stream = running if is_running else walking
		audio.play(0)
	elif (abs(velocity.x) < 0.1 and abs(velocity.z) < 0.1) or !is_on_floor():
		audio.stop()

	if Input.is_action_just_pressed("shift"):
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

	if Input.is_action_pressed("shift"):
		speed = sprint_speed
		is_running = true
	elif Input.is_action_pressed("ctrl"):
		speed = crouch_speed
	else:
		speed = original_speed

	if current_weapon is RangedWeapon:
		current_weapon.update_aim_state()

	if current_weapon is RangedWeapon and current_weapon.is_aiming:
		var base_fov = 70.0
		zoom_sensitivity_multiplier = clamp(current_weapon.camera.fov / base_fov, 0.2, 1.0)
	else:
		zoom_sensitivity_multiplier = 1.0

	if is_on_floor():
		agility = 1
	else:
		agility = 1.05
		velocity.y -= self.gravity * delta

	velocity = Vector3(speed * direction.x, velocity.y, speed * direction.z)
	velocity = Vector3(velocity.x * agility, velocity.y, velocity.z * agility)
	velocity.lerp(direction * speed, 0.5)
	move_and_slide()

func _jump():
	can_jump = false
	velocity.y += jump_power
	await get_tree().create_timer(.5).timeout
	can_jump = true

func _weapon_switch(direction: int) -> void:
	if not weapon_switch or all_weapons.size() < 2:
		return
	weapon_switch = false

	if current_weapon.has_method("cancel_reload"):
		current_weapon.cancel_reload()
	if current_weapon.has_method("set_aiming"):
		current_weapon.set_aiming(false)

	await get_tree().create_timer(0.15).timeout
	
	if current_weapon.has_method("stop_all_sounds"):
		current_weapon.stop_all_sounds()

	current_weapon.deactivate()

	current_weapon_index = (current_weapon_index + direction) % all_weapons.size()
	current_weapon = all_weapons[current_weapon_index]
	current_weapon.activate()

	if current_weapon.has_method("fire_range"):
		raycast_shooting.set_target_position(Vector3(0, 0, -current_weapon.fire_range))

	change_ammo_ui()
	emit_signal("weapon_changed", current_weapon.weapon_type)

	weapon_switch = true

func _activate_weapon(index: int):
	for i in range(all_weapons.size()):
		var weapon = all_weapons[i]
		var active = (i == index)
		weapon.is_active = active
		weapon.visible = active
		if weapon.has_method("set_aiming"):
			weapon.set_aiming(false)
	current_weapon_index = index
	current_weapon = all_weapons[index]
	emit_signal("weapon_changed", current_weapon.weapon_type)
	if current_weapon.has_method("fire_range"):
		raycast_shooting.set_target_position(Vector3(0, 0, -current_weapon.fire_range))
	change_ammo_ui()

func throw_grenade():
	if grenade_ammo <= 0:
		return
	var thrown_grenade: Grenade = grenade_packed.instantiate()
	get_tree().current_scene.add_child(thrown_grenade)
	thrown_grenade.global_transform.origin = (camera.global_transform.origin + 
	camera.global_transform.basis.z * -1.5)
	var throw_dir = -camera.global_transform.basis.z.normalized()
	thrown_grenade._throw(throw_dir)
	grenade_ammo -= 1

func give_ammo(amount: int, type: WeaponType.Type) -> void:
	for weapon in [first_weapon, second_weapon]:
		if weapon.weapon_type == type:
			weapon.ammo_total += amount
			if weapon == current_weapon:
				change_ammo_ui()

func damage(damage):
	health -= damage
	if health < 0:
		health = 0
	emit_signal("health_changed", health)

func change_ammo_ui():
	if current_weapon is RangedWeapon:
		emit_signal("ammo_changed", current_weapon.current_ammo, current_weapon.ammo_total)
	else:
		emit_signal("ammo_changed", "∞", "∞")

func check_collision():
	if interact_raycast.is_colliding():
		var collider = interact_raycast.get_collider()
		if collider is Interactable:
			var interactable: Interactable = collider
			interact_text.text = interactable.get_interact_text()
			interact_target = collider
			interact_text.visible = true
		else:
			interact_text.visible = false
	else:
		interact_target = null
		interact_text.visible = false

func _on_Timer_timeout():
	emit_signal("timer_finished")

func _on_enemy_trigger_entered(body: Node):
	print("enemy entered")
	if body is Enemy:
		body.on_body_entered(self)

func _on_enemy_trigger_exited(body: Node):
	print("enemy enxited")
	if body is Enemy:
		body.on_body_exited(self)
