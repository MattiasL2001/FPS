extends RigidBody3D

@export var force : int = 10
@export var time : float = 4
@export var from : NodePath

func _ready():
#	set_position(to_global(Vector3(get_parent().get_node("Head/Camera/Grenade_Pos").get_position())))
	await get_tree().create_timer(time).timeout
	_explode()
	
func throw():
	apply_impulse(
		Vector3(-get_parent().get_node("Player").get_basis().z.x * force, force / 1, -get_parent().get_node("Player").get_basis().z.z * force))
	
func _explode():
	queue_free() 
