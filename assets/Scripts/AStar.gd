extends Node
class_name AStar

var cell_size := 1
var cell_y := .3
@export var points := {}
var material = StandardMaterial3D.new()

func _ready() -> void:
	var pathables : Array = get_tree().get_nodes_in_group("pathable")
	var levels : Array = get_tree().get_nodes_in_group("Level")
	
	for level in levels:
		if level.get_node("Ground") != null and !level.get_node("Ground").is_in_group("pathable"):
			pathables.append(level.get_node("Ground"))
		elif level.get_node("Level_Design") != null:
			var children : Array = level.get_node("Level_Design").get_children()
			for child in children:
				if !pathables.has(child) and (
					"Cube" in child.get_name() or "Ramp" in child.get_name()):
					pathables.append(child)
	
	_add_points(pathables)
	_connect_points()

func _add_points(pathables : Array):
	for pathable in pathables:
		var mesh : MeshInstance3D
		var aabb : AABB
		if pathable.get_parent().is_in_group("Level"):
			mesh = pathable
			aabb = mesh.get_transformed_aabb()
		else:
			mesh = pathable
			aabb = mesh.get_aabb()
			aabb.size.x = mesh.transform.basis.x[0]
			aabb.size.z = mesh.transform.basis.z[2]
		
		var x_steps = aabb.size.x / cell_size
		var z_steps = aabb.size.z / cell_size
		
		if x_steps > 0 and z_steps > 0:
			for x in range(int(x_steps -1)):
				for z in range(int(z_steps -1)):
					var next_point = Vector3(
						-aabb.size.x / 2 + cell_size * 0.5 + cell_size * x,
						0,
						-aabb.size.z / 2 + cell_size * 0.5 + cell_size * z)
					_add_point(next_point)
				
func _add_point(position : Vector3):
	var node_point : AStar_Cell = AStar_Cell.new()
	node_point.position = world_to_astar(position)
	node_point.position.y = cell_y
	var id = str(round(node_point.position[0])) + "_" + str(round(node_point.position[2]))
	points.merge({id: node_point})
	
func _connect_points():
	for point_id in points:
		var point = points[point_id]
		
		var cube := BoxMesh.new()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = cube
		material.albedo_color = Color.GREEN
		mesh_instance.set_surface_override_material(0, material)
		cube.size = Vector3(cell_size * .2, cell_size * .2, cell_size * .2)
		add_child(mesh_instance)
		mesh_instance.global_transform.origin = Vector3(point.position[0], .5, point.position[2])
		mesh_instance.set_name("cube_mesh_" + point_id)
		
	for point_id in points:
		var point = points[point_id]
		var potential_neighbors = [
			
			#all the neighbors that lies next to the current point:
			Vector3(point.position[0] + 1, point.position[1], point.position[2]),
			Vector3(point.position[0], point.position[1], point.position[2] + 1),
			Vector3(point.position[0] - 1, point.position[1], point.position[2]),
			Vector3(point.position[0], point.position[1], point.position[2] - 1),
			
			#corner-neighbors:
			Vector3(point.position[0] + 1, point.position[1], point.position[2] + 1),
			Vector3(point.position[0] + 1, point.position[1], point.position[2] - 1),
			Vector3(point.position[0] - 1, point.position[1], point.position[2] - 1),
			Vector3(point.position[0] - 1, point.position[1], point.position[2] + 1)
		]
		for potential_neighbor in potential_neighbors:
			var potential_neighbor_id = get_astar_id(potential_neighbor)
			if points.has(potential_neighbor_id) && !points[potential_neighbor_id].is_blocked:
				points[point_id].neighbors.append(potential_neighbor)

func evaluate_neighbors(current_node : AStar_Cell, start_node : AStar_Cell, target_node : AStar_Cell):
	var neighbor_count = 0
	var lowest_f_cost = null
	var g_cost : int
	var h_cost : int
	var f_cost : int
	var neighbors = []
	
	for neighbor in current_node.neighbors:
		neighbor_count += 1
		var neighbor_cell = points[get_astar_id(neighbor)]
		if neighbor_count < 4:
			neighbor_cell.g_cost = 1 * 10
		else:
			neighbor_cell.g_cost = round(sqrt(2) * 10)
		
		g_cost = calculate_distance(start_node.position, current_node.position)
		h_cost = calculate_distance(target_node.position, current_node.position)
		f_cost = g_cost + h_cost
		
		if lowest_f_cost == null or f_cost < lowest_f_cost:
			lowest_f_cost = f_cost
		
		neighbor_cell.g_cost = g_cost
		neighbor_cell.h_cost = h_cost
		neighbors.append(neighbor)
	
	return [neighbors, lowest_f_cost]

func calculate_distance(from : Vector3, to : Vector3):
	var distance_x = abs(from[0] - to[0])
	var distance_z = abs(from[2] - to[2])
	
	if distance_x > distance_z:
		return sqrt(2) * 10 * distance_z + 10 * (distance_x - distance_z)

	return sqrt(2) * 10 * distance_x + 10 * (distance_z - distance_x)

func get_astar_id(position : Vector3):
	return str(position[0]) + "_" + str(position[2])

func world_to_astar(position : Vector3):
	var x = snapped(position.x, cell_size)
	var y = snapped(position.y, cell_size)
	var z = snapped(position.z, cell_size)
	return Vector3(x, y, z)
