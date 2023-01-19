extends RigidBody3D

@onready var default_material = $CollisionShape/MeshInstance.get_mesh().get_material()

@onready var light_material = preload("res://assets/Materials/emissionMat.tres")
@onready var is_emitting = false

func _ready():
	_change_material()

func _change_material():
	if is_emitting:
		$CollisionShape/MeshInstance.set_surface_override_material(0, default_material)
		is_emitting = false
	else:
		$CollisionShape/MeshInstance.set_surface_override_material(0, light_material)
		is_emitting = true
	await get_tree().create_timer(2).timeout
	_change_material()
