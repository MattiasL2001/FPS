extends VehicleBody3D

@onready var wheel_1 : VehicleWheel3D = $Wheel_1
@onready var wheel_2 : VehicleWheel3D = $Wheel_2
@onready var wheel_3 : VehicleWheel3D = $Wheel_3
@onready var wheel_4 : VehicleWheel3D = $Wheel_4
var wheels : Array
var accelerate : bool = true
var var_brake : bool = false

func _ready():
	wheels.append(wheel_1)
	wheels.append(wheel_2)
	wheels.append(wheel_3)
	wheels.append(wheel_4)
	await(get_tree().create_timer(3).timeout)
	gravity_scale = 1
#	steering = deg2rad(-45)
#	await get_tree().create_timer(6.6).timeout
#	steering = deg2rad(0)
#	await get_tree().create_timer(3).timeout
	set_engine_force(800 * 1.5)
	accelerate = false
	var_brake = true

#func _physics_process(delta):
#	if accelerate:
#		set_engine_force(800 * 2)
#	if brake:
#		brake = 5000

#func _process(delta):
#	if accelerate:
#		set_engine_force(800 * 2 * delta)
#	if brake:
#		brake = 5000 * delta
