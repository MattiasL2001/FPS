extends Node3D

@export var sway_threshold := 3.0
@export var sway_lerp := 3.0
@export var sway_intensity := Vector3(0, 0.07, 0.05)

var sway_normal: Vector3 = Vector3.ZERO
var mouse_mov := Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion:
		mouse_mov = Vector2(-event.relative.x, -event.relative.y)

func _process(delta):
	var sway_offset := Vector3.ZERO

	if mouse_mov.x > sway_threshold:
		sway_offset += sway_intensity
	elif mouse_mov.x < -sway_threshold:
		sway_offset -= sway_intensity

	if mouse_mov.y > sway_threshold:
		sway_offset += Vector3(sway_intensity.y, sway_intensity.x, 0)
	elif mouse_mov.y < -sway_threshold:
		sway_offset -= Vector3(sway_intensity.y, sway_intensity.x, 0)

	rotation = rotation.lerp(sway_normal + sway_offset, sway_lerp * delta)
