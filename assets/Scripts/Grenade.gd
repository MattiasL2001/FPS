extends RigidBody3D

@export var force : int = 7
@export var time : float = 4
@export var from : NodePath
@onready var audio : AudioStreamPlayer3D = $Audio

func _ready():
	await get_tree().create_timer(time).timeout
	_explode()
	
func throw():
	apply_impulse(Vector3(-get_parent().get_node("Player").get_basis().z.x * force, force / 1,
	-get_parent().get_node("Player").get_basis().z.z * force))

func _throw(throw_direction):
	var vertical_force = 1.1
	throw_direction.y += vertical_force
	self.linear_velocity = throw_direction  * force

func _explode():
	audio.play(0)
	queue_free() 
