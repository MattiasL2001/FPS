extends Node
class_name AStar_Cell

@export var position : Vector3 = Vector3()
@export var id := ""
@export var is_active : bool = true
@export var is_blocked : bool = false
@export var is_checked : bool = false
@export var _is_neighbor : bool = false
@export var neighbors = []
@export var cost : float = 0
@export var diagonal_cost : float = 0
@export var g_cost : float = 0
@export var h_cost : float = 0
@export var parent : Node = null

func get_f_cost():
	return g_cost + h_cost
