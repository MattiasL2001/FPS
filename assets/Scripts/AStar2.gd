extends Node
class_name AStar2

var astar = AStar3D.new()
var cell_size := 1
var cell_y := .3
@export var points := {}

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
		var start_point = aabb.position
		mesh = pathable
		aabb = mesh.get_aabb()
		aabb.size.x = mesh.transform.basis.x[0]
		aabb.size.z = mesh.transform.basis.z[2]
		
		var x_steps = aabb.size.x / cell_size
		var z_steps = aabb.size.z / cell_size
		
		if x_steps > 0 and z_steps > 0:
			for x in x_steps -1:
				for z in z_steps -1:
					var next_point = start_point + Vector3(
						x * cell_size + cell_size - 0.5 * aabb.size.x,
						0, z * cell_size + cell_size - 0.5 * aabb.size.z)
					_add_point(next_point)
				
func _add_point(node : Vector3):
	node.y = cell_y
	var id = astar.get_available_point_id()
	astar.add_point(id, node)
	points[world_to_astar(node)] = id
	
func _connect_points():
	for point in points:
		var pos_str = str(point).split(",")
		var world_pos = Vector3(int(pos_str[0]), int(pos_str[1]), int(pos_str[2]))
		var search_coords = [-cell_size, 0, cell_size]
		for x in search_coords:
			for z in search_coords:
				var search_offset = Vector3(x, 0, z)
				if search_offset == Vector3.ZERO:
					continue
				
				var potential_neighbor = world_to_astar(world_pos + search_offset)
				if points.has(potential_neighbor):
					var current_id = points[point]
					var neighbor_id = points[potential_neighbor]
					if not astar.are_points_connected(current_id, neighbor_id):
						astar.connect_points(current_id, neighbor_id)
		
		var cube := BoxMesh.new()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = cube
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GREEN
		mesh_instance.set_surface_override_material(0, material)
		cube.size = Vector3(cell_size * .2, cell_size * .2, cell_size * .2)
		add_child(mesh_instance)
		mesh_instance.global_transform.origin = Vector3(int(pos_str[0]), cell_y, int(pos_str[2]))
		mesh_instance.set_name("cube_mesh_" + pos_str[0] + ", " + "0," + pos_str[2])

func find_path(from: Vector3, to: Vector3) -> Array:
	var start_id = astar.get_closest_point(from)
	var end_id = astar.get_closest_point(to)
	return astar.get_point_path(start_id, end_id)

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
