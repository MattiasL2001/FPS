extends Node3D

class_name Weapon

@export var weapon_name: String
@export var weapon_class: int
@export var damage : int
@export var fire_range = 0
@export var fire_rate : float
@export var clip_size = 0
@export var reload_rate = 0
@export var ammo_total = 0
@onready var animation_player : AnimationPlayer = get_node("../UI/Reloading/AnimationPlayer")
@onready var audio : AudioStreamPlayer3D = get_node("Audio")
var camera_shake : float
var camera_position : Vector3
@onready var bullet_hole = preload("res://assets/Scenes/Bullet_Hole.tscn")
@onready var raycast : RayCast3D = get_parent().get_node("RayCastShooting")
@onready var camera : Camera3D = get_node("../")
signal ammo_changed
var current_ammo = 0
@onready var is_active = false
var can_fire = true
var reloading = false
var tween_finished : bool = true
var mouse_mov
var sway_threshold = 3
var sway_lerp = 3
var sway_x : Vector3 = Vector3(0, .07, 0)
var sway_y :Vector3 = Vector3(0, 0, .25)
@onready var sway_normal : Vector3 = get_rotation()

func _ready():
	get_node("../UI/Reloading").visible = false
	camera_position = camera.get_position()
	current_ammo = clip_size
	emit_signal("ammo_changed", current_ammo, ammo_total)
	raycast.set_target_position(Vector3(0, 0, -fire_range))
	
	if weapon_class == 1:
		is_active = true

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov = Vector2(-event.relative.x, -event.relative.y)

func _process(delta):
	if mouse_mov != null:
		if mouse_mov[0] > sway_threshold:
			rotation = rotation.lerp(sway_normal + sway_x, sway_lerp * delta)
		elif mouse_mov[0] < -sway_threshold:
			rotation = rotation.lerp(sway_normal - sway_x, sway_lerp * delta)
		else:
			rotation = rotation.lerp(sway_normal, sway_lerp * delta)
		
		if mouse_mov[1] > sway_threshold:
			rotation = rotation.lerp(sway_normal + sway_y, sway_lerp * delta)
		elif mouse_mov[1] < -sway_threshold:
			rotation = rotation.lerp(sway_normal - sway_y, sway_lerp * delta)
		else:
			rotation = rotation.lerp(sway_normal, sway_lerp * delta)
	
	#executes when the player presses the shoot button and can shoot
	if Input.is_action_pressed("mouseClick") and can_fire and is_active:
		if current_ammo > 0 and not reloading:
			if (audio != null and !audio.playing) || (audio != null and weapon_name.contains("Rifle")):
				audio.play(0)
			var offset = randf_range(-camera_shake, camera_shake)
			var tween := create_tween()
			tween.finished.connect(func(): tween_finished = true)
			var camera_shake_vector = Vector3(
				randf_range(-0.01, 0.01), randf_range(-0.01, 0.01), -0.03)
			tween.set_ease(Tween.EASE_OUT)
			tween.TRANS_ELASTIC
			
			if tween_finished:
				tween.tween_property(get_node("../"), "position:z", 0.01, .1)
				tween_finished = false
			check_collision()
			can_fire = false
			current_ammo -= 1
			get_node("../../../")._change_ammo_ui()
			emit_signal("ammo_changed", current_ammo, ammo_total)
			
			#waits the amount of time that "fire_rate" is set to, which will prevent spam-shooting
			await(get_tree().create_timer(fire_rate)).timeout
			can_fire = true
			
		elif not reloading and is_active:
			_reloading()
			
			#executes when the player still have bullets in the mag, but presses the "reload" button
	elif Input.is_action_just_pressed("reload") and current_ammo < clip_size and is_active:
		_reloading()
	
	else:
		camera.set_position(camera_position)

func _reloading():
			reloading = true
			get_node("../UI/Reloading").visible = true
			
			animation_player.speed_scale = animation_player.speed_scale / reload_rate
			animation_player.play("Reloading")
			
			#waits "reload_rate" amount of secs, which works as a reload delay
			await(get_tree().create_timer(reload_rate)).timeout
			get_node("../UI/Reloading").visible = false
			animation_player.speed_scale = 1
			
			if is_active:
				if reloading:
					if (ammo_total >= (clip_size - current_ammo)):
						ammo_total -= (clip_size - current_ammo)
						current_ammo = clip_size
					elif (ammo_total > 0):
						current_ammo += ammo_total
						ammo_total = 0
					emit_signal("ammo_changed", current_ammo, ammo_total)
					get_node("../../../")._change_ammo_ui()
					reloading = false

func check_array_col():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider != null and collider.is_in_group("Enemies"):
			return true
		else:
			return false

func check_collision():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.is_in_group("Enemies"):
			collider.take_damage(damage)
			
		elif !collider.is_in_group("Player") || !collider.is_in_group("Enemies"):
			var b_h = bullet_hole.instantiate()
			raycast.get_collider().get_node("../").get_node("../").add_child(b_h)
			b_h.global_transform.origin = raycast.get_collision_point()
			b_h.rotate_y(raycast.get_rotation().y)
			b_h.look_at(raycast.get_collision_point() + raycast.get_collision_normal(), Vector3.UP)
