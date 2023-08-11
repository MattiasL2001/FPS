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
@onready var crosshair = $Head/Camera/UI/Crosshair/TextureRect
@onready var audio : AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var crosshairs = []
@onready var normal_crosshair = preload("res://assets/Images/Crosshair_2.png")
@onready var red_crosshair = preload("res://assets/Images/Crosshair_3.png")
@onready var point_1 = preload("res://assets/Images/Point.png")
@onready var point_2 = preload("res://assets/Images/Point_2.png")
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
	first_weapon = $Head/Camera/FirstWeapon
	second_weapon = $Head/Camera/SecondWeapon
	current_weapon = first_weapon
	crosshairs.append($Head/Camera/UI/Crosshair/TextureRect2)
	crosshairs.append($Head/Camera/UI/Crosshair/TextureRect3)
	crosshairs.append($Head/Camera/UI/Crosshair/TextureRect4)
	crosshairs.append($Head/Camera/UI/Crosshair/TextureRect5)
	raycast_shooting.set_target_position(Vector3(0, 0, -first_weapon.fire_range))
	second_weapon.visible = false
	emit_signal("speed_changed", speed)
	emit_signal("health_changed", health)
	emit_signal("weapon_changed", current_weapon.weapon_class)
	_change_ammo_ui()
	_updater()

func _input(event):
	if event is InputEventMouseMotion:
		self.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		var x_delta = event.relative.y * mouse_sensitivity
		if camera_x_rotation + x_delta > -90 and camera_x_rotation + x_delta < 90:
			camera.rotate_x(deg_to_rad(-x_delta))
			camera_x_rotation += x_delta
			
	if event is InputEventMouseButton:
		
		if event.button_index == 4 or event.button_index == 5:
			_weapon_switch()

func _updater():
	if (current_weapon == first_weapon and first_weapon.check_array_col() == true) or (current_weapon == second_weapon and second_weapon.check_array_col() == true):
		crosshair.texture = point_2
		for ch in crosshairs:
			ch.texture = red_crosshair
	
	else:
		crosshair.texture = point_1
		for ch in crosshairs:
			ch.texture = normal_crosshair
	
	await get_tree().create_timer(.1).timeout
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
	
	if Input.is_action_pressed("shift"):
		speed = sprint_speed
		is_running = true
		emit_signal("speed_changed", speed)
	else:
		is_running = false
	
	if Input.is_action_pressed("ctrl"):
		head.set_position(Vector3(0, 0.5, -0.2))
		speed = crouch_speed
		emit_signal("speed_changed", speed)
	else:
		head.set_position(Vector3(0, 0.7, -0.2))
	
	if !Input.is_action_pressed("ctrl") and !Input.is_action_pressed("shift"):
		speed = original_speed
		emit_signal("speed_changed", speed)

	if Input.is_action_just_pressed("Interact"):
		if interact_text.is_visible() == true:
			if (interact_raycast.get_collider() != null and "Knife" in interact_raycast.get_collider().get_name()):
				if interact_raycast.get_collider().get_parent():
					interact_raycast.get_collider().get_parent().remove_child(interact_raycast.get_collider())
				
				interact_raycast.get_collider().set_translation(Vector3(1, 0, -1.5))
				add_child(interact_raycast.get_collider())
				interact_raycast.get_collider().set_rotation(Vector3(0, head.global_transform.basis.get_euler().y, -90))
				
			if (interact_raycast.get_collider() != null and "LightBox" in interact_raycast.get_collider().get_name()):
				print (interact_raycast.get_collider().get_node("CollisionShape/MeshInstance").get_surface_material(0))
				interact_raycast.get_collider()._change_material()
			
			if (interact_raycast.get_collider() != null and "Ammo" in interact_raycast.get_collider().get_name()):
				first_weapon.ammo_total += first_weapon.clip_size
				second_weapon.ammo_total += second_weapon.clip_size
				interact_raycast.get_collider().queue_free()
			
			var interactObj = interact_raycast.get_collider()
			
	if Input.is_action_just_pressed("First Weapon"):
		_weapon_switch()
		
	if Input.is_action_just_pressed("Second Weapon"):
		_weapon_switch()
		emit_signal("weapon_changed", current_weapon)
	
	if Input.is_action_just_pressed("Grenade"):
		if grenade_ammo > 0:
			print(get_node("Head/Camera/Grenade_Pos").get_position())
			print(to_global(get_node("Head/Camera/Grenade_Pos").get_position()))
			get_parent().add_child(grenade)
			print(str(to_global(get_node("../Grenade").get_position())) + " global")

	if Input.is_action_just_released("Grenade"):
		if grenade_ammo > 0 and get_node("../Grenade") != null:
			get_node("../Grenade").freeze = false
#			get_node("../Grenade").throw()
			get_node("../Grenade")._throw(-camera.global_transform.basis.z.normalized())
			grenade_ammo -= 1
	
	if Input.is_action_just_released("Grenade") and get_node("../Grenade") == null:
		grenade_ammo -= 1
	
	direction = direction.normalized()
	velocity = Vector3(speed* direction.x, velocity.y, speed * direction.z)
	
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
			second_weapon.emit_signal("ammo_changed", second_weapon.current_ammo, second_weapon.ammo_total)
			raycast_shooting.set_target_position(Vector3(0, 0, -second_weapon.fire_range))
			_change_ammo_ui()
			weapon_switch = false

		elif current_weapon == second_weapon:
			current_weapon = first_weapon
			emit_signal("weapon_changed", current_weapon.weapon_class)
			first_weapon.is_active = true
			second_weapon.is_active = false
			first_weapon.visible = true
			second_weapon.visible = false
			second_weapon.reloading = false
			first_weapon.emit_signal("ammo_changed", first_weapon.current_ammo, first_weapon.ammo_total)
			raycast_shooting.set_target_position(Vector3(0, 0, -first_weapon.fire_range))
			_change_ammo_ui()
			weapon_switch = false
		await get_tree().create_timer(.3).timeout
		weapon_switch = true

func damage(damage):
	health -= damage
	if health < 0:
		health = 0
	emit_signal("health_changed", health)

func _change_ammo_ui():
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
