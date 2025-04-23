extends Node3D

@export var sway_threshold = 3.0
@export var sway_lerp = 3.0
@export var sway_x: Vector3 = Vector3(0, 0.07, 0)
@export var sway_y: Vector3 = Vector3(0, 0, 0.25)

var sway_normal: Vector3 = Vector3.ZERO
var mouse_mov: Vector2 = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov = Vector2(-event.relative.x, -event.relative.y)

func _process(delta):
	var rot = rotation

	if mouse_mov.x > sway_threshold:
		rot = rot.lerp(sway_normal + sway_x, sway_lerp * delta)
	elif mouse_mov.x < -sway_threshold:
		rot = rot.lerp(sway_normal - sway_x, sway_lerp * delta)
	else:
		rot = rot.lerp(sway_normal, sway_lerp * delta)

	if mouse_mov.y > sway_threshold:
		rot = rot.lerp(sway_normal + sway_y, sway_lerp * delta)
	elif mouse_mov.y < -sway_threshold:
		rot = rot.lerp(sway_normal - sway_y, sway_lerp * delta)
	else:
		rot = rot.lerp(sway_normal, sway_lerp * delta)

	rotation = rot
