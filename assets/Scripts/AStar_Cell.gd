extends Node
class_name AStar_Cell

@export var position : Vector3 = Vector3()
@export var id = str(position[0]) + "_" + str(position[2])
@export var is_active : bool = true
@export var is_blocked : bool = false
@export var is_checked : bool = false
@export var _is_neighbor : bool = false
@export var neighbors = []
@export var cost : float
@export var diagonal_cost : float
@export var g_cost : float
@export var h_cost : float
@export var parent : Node

func get_f_cost(g_cost, h_cost):
	return g_cost + h_cost
