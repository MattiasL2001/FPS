extends Node

var cell_size := 1.0
var cell_y := 0.5
@export var points := {}
var astar = AStar3D.new()
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
				if child is StaticBody3D:
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
			mesh = pathable.get_child(0).get_child(0)
			aabb = mesh.get_transformed_aabb()
		
		var x_steps = aabb.size.x / cell_size
		var z_steps = aabb.size.z / cell_size
		
		for x in x_steps - 8:
			for z in z_steps - 8:
				var next_point = aabb.position + Vector3(cell_size, 0, cell_size) + Vector3(x * cell_size, 0, z * cell_size)
				_add_point(next_point)
				
func _add_point(point : Vector3):
	point.y = cell_y
	var id = astar.get_available_point_id()
	astar.add_point(id, point)
	points[_world_to_astar(point)] = id
	
func _connect_points():
	for point in points:
		var pos_str = point.split(",")
		var world_pos_int = Vector3(pos_str[0].to_int(), pos_str[1].to_int(), pos_str[2].to_int())
		var world_pos = Vector3(pos_str[0].to_float(), pos_str[1].to_float(), pos_str[2].to_float())
		var search_coords = [-cell_size, 0, cell_size]
		var cube := BoxMesh.new()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = cube
		material.albedo_color = Color.GREEN
		mesh_instance.set_surface_override_material(0, material)
		cube.size = Vector3(0.1, 0.1, 0.1)
		add_child(mesh_instance)
		mesh_instance.global_transform.origin = Vector3(world_pos_int.x, 2, world_pos_int.z)
		get_tree().root.get_node("Level").add_child(mesh_instance)
		mesh_instance.set_name("cube_mesh_" + str(pos_str[0]) + "_" + str(pos_str[2].replace(" ", "")))
		
		for x in search_coords:
			for z in search_coords:
				var search_offset = Vector3(x, 0, z)
				
				if search_offset == Vector3.ZERO:
					continue
				
				var potential_neighbor = _world_to_astar(world_pos + search_offset)
				if points.has(potential_neighbor):
					var current_id = points[point]
					var neighbor_id = points[potential_neighbor]
					if not astar.are_points_connected(current_id, neighbor_id):
						astar.connect_points(current_id, neighbor_id)
	print(get_children())

func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	for child in get_children():
		child.set_surface_override_material(0, material)
	
	var start_id = astar.get_closest_point(from)
	var end_id = astar.get_closest_point(to)
	
	return astar.get_point_path(start_id, end_id)

#rounds the coordinates of the "world" argument, to be snapped to nearest cell in the AStar grid
func _world_to_astar(world : Vector3) -> String:
	var x = snapped(world.x, cell_size)
	var y = snapped(world.y, cell_size)
	var z = snapped(world.z, cell_size)
	return "%d, %d, %d" % [x, y, z]
