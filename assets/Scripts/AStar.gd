#extends Node
#class_name AStar
#
#var astar: AStar3D = AStar3D.new()
#var cell_size: float = 1
#@export var points: Dictionary = {}
#
#func _ready() -> void:
	#var pathables: Array = get_tree().get_nodes_in_group("pathable")
	#var levels: Array = get_tree().get_nodes_in_group("Level")
#
	#for level in levels:
		#if level.get_node("Ground") != null and !level.get_node("Ground").is_in_group("pathable"):
			#pathables.append(level.get_node("Ground"))
		#elif level.get_node("Level_Design") != null:
			#var children: Array = level.get_node("Level_Design").get_children()
			#for child in children:
				#if !pathables.has(child) and ("Cube" in child.name or "Ramp" in child.name):
					#pathables.append(child)
#
	#_add_points(pathables)
	#_connect_points()
#
#func _add_points(pathables: Array) -> void:
	#for pathable in pathables:
		#if not pathable is MeshInstance3D:
			#continue
#
		#var mesh: MeshInstance3D = pathable
		#var transform: Transform3D = mesh.global_transform
		#var aabb: AABB = mesh.get_mesh().get_aabb()
		#var mesh_size: Vector3 = aabb.size * mesh.scale
		#var aabb_offset: Vector3 = aabb.position * mesh.scale
#
		#var x_steps: int = int(ceil(mesh_size.x / cell_size))
		#var z_steps: int = int(ceil(mesh_size.z / cell_size))
#
		#var total_grid_size_x: float = x_steps * cell_size
		#var total_grid_size_z: float = z_steps * cell_size
#
		#var offset_x: float = (total_grid_size_x - mesh_size.x) * 0.5
		#var offset_z: float = (total_grid_size_z - mesh_size.z) * 0.5
#
		#var origin: Vector3 = transform.origin + aabb_offset - Vector3(offset_x, 0, offset_z)
#
		#for x in range(x_steps):
			#for z in range(z_steps):
				#var pos: Vector3 = origin + Vector3(
					#x * cell_size + 0.5 * cell_size,
					#0,
					#z * cell_size + 0.5 * cell_size
				#)
#
				## 🟨 Sätt höjd till objektets höjd direkt
				#pos.y = transform.origin.y
#
				#_add_point(pos)
#
				## 🔲 Rita gul ruta som även representerar nod
				#var box: BoxMesh = BoxMesh.new()
				#box.size = Vector3(cell_size * 0.2, 0.01, cell_size * 0.2)
#
				#var box_instance: MeshInstance3D = MeshInstance3D.new()
				#box_instance.mesh = box
				#box_instance.global_transform.origin = pos + Vector3(0, 0.1, 0)
#
				#var mat: StandardMaterial3D = StandardMaterial3D.new()
				#mat.albedo_color = Color(1.0, 1.0, 0.0, 0.8)
				#mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				#mat.flags_transparent = true
				#box_instance.set_surface_override_material(0, mat)
#
				#add_child(box_instance)
#
#
#
#func _add_point(position: Vector3) -> void:
	#var id: int = astar.get_available_point_id()
	#astar.add_point(id, position)
	#points[world_to_astar(position)] = id
#
#func _connect_points() -> void:
	#for point in points:
		#var world_pos: Vector3 = point
		#var search_offsets: Array = [-cell_size, 0, cell_size]
#
		#for x in search_offsets:
			#for z in search_offsets:
				#if x == 0 and z == 0:
					#continue
#
				#var offset: Vector3 = Vector3(x, 0, z)
				#var neighbor_key: Vector3 = world_to_astar(world_pos + offset)
#
				#if points.has(neighbor_key):
					#var current_id: int = points[point]
					#var neighbor_id: int = points[neighbor_key]
#
					#if not astar.are_points_connected(current_id, neighbor_id):
						#astar.connect_points(current_id, neighbor_id)
#
#func find_path(from: Vector3, to: Vector3) -> Array:
	#var start_id: int = astar.get_closest_point(from)
	#var end_id: int = astar.get_closest_point(to)
#
	#if astar.has_point(start_id) and astar.has_point(end_id):
		#return astar.get_point_path(start_id, end_id)
#
	#return []
#
#func world_to_astar(position: Vector3) -> Vector3:
	#var x: float = snapped(position.x, cell_size)
	#var y: float = snapped(position.y, cell_size)
	#var z: float = snapped(position.z, cell_size)
	#return Vector3(x, y, z)
#
#func _get_transformed_aabb(aabb: AABB, transform: Transform3D) -> AABB:
	#var vertices: Array = []
	#vertices.append(aabb.position)
	#vertices.append(aabb.position + Vector3(aabb.size.x, 0, 0))
	#vertices.append(aabb.position + Vector3(0, aabb.size.y, 0))
	#vertices.append(aabb.position + Vector3(0, 0, aabb.size.z))
	#vertices.append(aabb.position + Vector3(aabb.size.x, aabb.size.y, 0))
	#vertices.append(aabb.position + Vector3(0, aabb.size.y, aabb.size.z))
	#vertices.append(aabb.position + Vector3(aabb.size.x, 0, aabb.size.z))
	#vertices.append(aabb.position + aabb.size)
#
	#for i in range(vertices.size()):
		#vertices[i] = transform * vertices[i]
#
	#var min_point: Vector3 = vertices[0]
	#var max_point: Vector3 = vertices[0]
#
	#for v in vertices:
		#min_point = min_point.min(v)
		#max_point = max_point.max(v)
#
	#var new_position: Vector3 = min_point
	#var new_size: Vector3 = max_point - min_point
	#return AABB(new_position, new_size)
