extends Node

@export var time : float

func _ready():
	await get_tree().create_timer(time).timeout
	queue_free()
