extends Node3D

class_name Weapon

@export var weapon_name: String
@export var weapon_class: int
@export var is_scoped: bool
@export var damage: int
@export var fire_range = 0
@export var fire_rate: float
@export var clip_size = 0
@export var reload_rate = 0
@export var ammo_total = 0

@export var camera_shake: float = 0.02
@export var ads_position: Vector3 = Vector3(0, -0.1, -0.15)
@export var aim_fov: float
@export var ads_speed: float = 20.0

var _original_position: Vector3
var _original_rotation: Vector3
var original_fov: float
var camera_position: Vector3
var is_aiming: bool = false

@onready var player: CharacterBody3D = get_node("../../../../")
@onready var sway_pivot: Node3D = get_node("../")
@onready var animation_player: AnimationPlayer = get_node("../../UI/Reloading/AnimationPlayer")
@onready var audio: AudioStreamPlayer3D = get_node("Audio")
@onready var bullet_hole = preload("res://assets/Scenes/Bullet_Hole.tscn")
@onready var raycast: RayCast3D = get_node("../../RayCastShooting")
@onready var camera: Camera3D = get_node("../../")

signal ammo_changed

var current_ammo = 0
@onready var is_active = false
var can_fire = true
var reloading = false
var tween_finished: bool = true

# Sway
var mouse_mov
@export var sway_threshold = 3.0
@export var sway_lerp = 3.0
@export var sway_x: Vector3 = Vector3(0, 0.07, 0)
@export var sway_y: Vector3 = Vector3(0, 0, 0.25)
var sway_normal: Vector3 = Vector3.ZERO

# Scoped hide delay
var scope_hide_delay := 0.05
var scope_hide_timer: Timer

func _ready():
    _original_position = position
    _original_rotation = rotation
    rotation = _original_rotation
    if camera:
        original_fov = camera.fov
    camera_position = camera.get_position()

    # Scoped weapon delay timer
    scope_hide_timer = Timer.new()
    scope_hide_timer.one_shot = true
    scope_hide_timer.wait_time = scope_hide_delay
    add_child(scope_hide_timer)

    get_node("../../UI/Reloading").visible = false
    current_ammo = clip_size
    emit_signal("ammo_changed", current_ammo, ammo_total)
    raycast.set_target_position(Vector3(0, 0, -fire_range))

    if weapon_class == 1:
        is_active = true

func _input(event):
    if event is InputEventMouseMotion:
        mouse_mov = Vector2(-event.relative.x, -event.relative.y)

func _process(delta):
    if is_active:
        # ADS position
        var target_pos = ads_position if is_aiming else _original_position
        position = position.lerp(target_pos, delta * ads_speed)

        # ADS rotation
        var current_rot = rotation
        var target_y = deg_to_rad(-90) if is_aiming else _original_rotation.y
        rotation.y = lerp_angle(current_rot.y, target_y, delta * ads_speed)

        # Camera FOV
        if camera:
            var target_fov = aim_fov if is_aiming else original_fov
            camera.fov = lerp(camera.fov, target_fov, delta * ads_speed)

    # Shooting
    if Input.is_action_pressed("mouseClick") and can_fire and is_active:
        if current_ammo > 0 and not reloading:
            if (audio != null and !audio.playing) or (audio != null and weapon_name.contains("Rifle")):
                audio.play(0)

            var offset = randf_range(-camera_shake, camera_shake)
            var tween := create_tween()
            tween.finished.connect(func(): tween_finished = true)
            tween.set_ease(Tween.EASE_OUT)
            tween.TRANS_ELASTIC

            if tween_finished:
                tween.tween_property(get_node("../.."), "position:z", 0.01, .1)
                tween_finished = false

            check_collision()
            can_fire = false
            current_ammo -= 1
            player.change_ammo_ui()
            emit_signal("ammo_changed", current_ammo, ammo_total)

            await get_tree().create_timer(fire_rate).timeout
            can_fire = true

        elif not reloading and is_active:
            _reloading()

    elif Input.is_action_just_pressed("reload") and current_ammo < clip_size and is_active:
        _reloading()
    else:
        camera.set_position(camera_position)

func set_aiming(state: bool) -> void:
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

func _reloading():
    reloading = true
    get_node("../../UI/Reloading").visible = true
    animation_player.speed_scale = animation_player.speed_scale / reload_rate
    animation_player.play("Reloading")

    await get_tree().create_timer(reload_rate).timeout
    get_node("../../UI/Reloading").visible = false
    animation_player.speed_scale = 1

    if is_active and reloading:
        if ammo_total >= (clip_size - current_ammo):
            ammo_total -= (clip_size - current_ammo)
            current_ammo = clip_size
        elif ammo_total > 0:
            current_ammo += ammo_total
            ammo_total = 0

        emit_signal("ammo_changed", current_ammo, ammo_total)
        player.change_ammo_ui()
        reloading = false

func check_array_col():
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        if collider != null and collider.is_in_group("Enemies"):
            return true
    return false

func check_collision():
    if raycast.is_colliding():
        var collider = raycast.get_collider()
        if collider.is_in_group("Enemies"):
            collider.take_damage(damage)
        elif !collider.is_in_group("Player") or !collider.is_in_group("Enemies"):
            var b_h = bullet_hole.instantiate()
            raycast.get_collider().get_node("../").get_node("../").add_child(b_h)
            b_h.global_transform.origin = raycast.get_collision_point()
            b_h.rotate_y(raycast.get_rotation().y)
            b_h.look_at(raycast.get_collision_point() + raycast.get_collision_normal(), Vector3.UP)
