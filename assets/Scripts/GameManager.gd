extends Node3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	DisplayServer.window_set_mode(3, DisplayServer.window_get_current_screen())
#
func _physics_process(_delta):
	if (Input.is_action_just_pressed("esc")):
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		DisplayServer.window_set_mode(0, DisplayServer.window_get_current_screen())
#
	if (Input.is_action_just_pressed("mouseClick")):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
