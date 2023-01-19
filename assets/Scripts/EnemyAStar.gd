extends CharacterBody3D

enum {
	IDLE,
	ALERT
}
var state = IDLE
var target
const TURN_SPEED = 2

@onready var eyes = $Eyes
@onready var raycast = $Eyes/RayCastShooting
@onready var shoottimer = $ShootTimer
@onready var raycast_col1 = $Eyes/RayCastCollission
var max_look_angle_y : int = 75
var max_look_angle_x : int = 50
var speed = 3
var gravity : float = 0.98
var health : int = 100
var damage : int = 20
var head_basis
var direction : Vector3 = Vector3()
var look_dir_hor
var look_dir_ver
var path := []
var current_target := Vector3(INF, INF, INF)

var cell_size := 1.0
var cell_y := 0.5
@export var points := {}
var astar = AStar3D.new()

func _ready():
	_movement()
#	update_path()
	var pathables : Array = get_tree().get_nodes_in_group("pathable")
	var levels : Array = get_tree().get_nodes_in_group("Level")
	
	#for levels who are its own scene, where the parent is not a body, but a node3d
	for level in levels:
		print("level children: ", level.get_children())
		if level.get_node("Ground") != null and !level.get_node("Ground").is_in_group("pathable"):
			pathables.append(level.get_node("Ground"))
		elif level.get_node("Level_Design") != null:
			var children : Array = level.get_node("Level_Design").get_children()
			for child in children:
#				if the type of the child is equal to 21, which is StaticBody3D
				if child is StaticBody3D:
					print("is child static body: ", (child is StaticBody3D))
					pathables.append(child)
#				print("child type: ", typeof(child))
#				print("MeshI3D type: " ,typeof(MeshInstance3D))
#				if child.typeof(StaticBody3D):
#					pathables.append(child)
	print(pathables)
	
	_add_points(pathables)
	_connect_points()

func _process(delta):
#	for point in astar.find_path(get_transform().origin, get_node("../../Players/Player").get_transform().origin):
#		print(point)
	match state:
		IDLE:
			pass
		ALERT:
			pass
#			eyes.look_at(target.global_transform.origin, Vector3.UP)
#			rotate_y(deg2rad(eyes.rotation.y * TURN_SPEED))
	
func _physics_process(delta):
	head_basis = eyes.get_global_transform().basis
	direction = Vector3()
	
	for i in range (get_slide_collision_count() -1):
		var collision = get_last_slide_collision()
#		if collision != null:
#			print (collision.to_string() + "!!!")
	velocity.y -= gravity
	move_and_slide()
	var new_velocity := Vector3.ZERO
	var lerp_weight = delta * 8.0
	if current_target != Vector3(INF, INF, INF):
		var dir_to_target = global_transform.origin.direction_to(current_target).normalized()
#		new_velocity = lerp(speed, speed, lerp_weight)
		if global_transform.origin.distance_to(current_target) < 0.5:
			find_next_point_in_path()
#	else:
#		new_velocity = lerp(speed, Vector3.ZERO, lerp_weight)
#	current_velocity = move_and_slide(new_velocity)

func _movement():
	match state:
		IDLE:
			velocity = Vector3()
			if (look_dir_hor == "left" and rad2deg(eyes.get_basis().get_euler().y) <= max_look_angle_y):
				eyes.rotate_y(deg2rad(get_rotation().y) +0.05 * TURN_SPEED)
			else:
				look_dir_hor = "right"
				
			if (look_dir_hor == "right" and rad2deg(eyes.get_basis().get_euler().y) >= -max_look_angle_y):
				eyes.rotate_y(deg2rad(get_rotation().y) -0.05 * TURN_SPEED)
			else:
				look_dir_hor = "left"

		ALERT:
#			find_path(get_transform().origin, get_node("../../Players/Player").get_transform().origin)
			eyes.get_basis().get_euler().y = 0
			
			#extremely intensive code
#			for point in get_node("../").get_node("AStar").points:
#				print("point:: ", point)
#				var p = point.split(",")
#				print("point_pos: ", p[0], p[1], p[2])
#				var point_pos : Vector3 = Vector3(p[0].to_int(), p[1].to_int(), p[2].to_int())
#				print("point_pos_vector: ", point_pos)
#				eyes.look_at(point_pos, Vector3.UP)
#				rotate_y(deg2rad(eyes.rotation.y * TURN_SPEED))
			
#			if sqrt(pow((get_position().x - target.get_position().x), 2) +
#				pow(get_position().z - target.get_position().z, 2)) > 7:
#				velocity = Vector3(-get_basis().z.x * speed, velocity.y, -get_basis().z.z * speed)
#			else:
#				velocity = Vector3()
			
	await(get_tree().create_timer(0.1).timeout)
	_movement()

#func _on_Weapon_body_entered(body):
#	if (body.is_in_group("Player")):
#		body.queue.free()

func _on_SightRange_body_entered(body):
	if (body.is_in_group("Player")):
		state = ALERT
		target = body
		shoottimer.start()
		_state_transition()

func _on_SightRange_body_exited(body):
	if (body.is_in_group("Player")):
		state = IDLE
		shoottimer.stop()
		_state_transition()

func _on_ShootTimer_timeout():
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit.is_in_group("Player"):
			hit.damage(damage)
			
func _state_transition():
	var original_rotation = eyes.get_basis().get_euler().y
	look_dir_hor = "left"
	look_dir_ver = "up"

func find_next_point_in_path():
	if path.size() > 0:
		var new_target = path.pop_front()
		new_target.y = global_transform.origin.y
		current_target = new_target
	else:
		current_target = Vector3()

func update_path(new_path: Array):
	path = new_path
	find_next_point_in_path()

func _add_points(pathables : Array):
	#for every pathable, that is to say every ground that the enemy can walk on
	for pathable in pathables:
		var mesh : MeshInstance3D
		var aabb : AABB
		
		if pathable.get_parent().is_in_group("Level"):
			mesh = pathable
			aabb = mesh.get_transformed_aabb()
			print("success: ", mesh)
		else:
			print(pathable.get_parent())
			mesh = pathable.get_child(0).get_child(0)
#			mesh = pathable.get_node("CollisionShape3D").get_node("MeshInstance3D")
			aabb = mesh.get_transformed_aabb()
		
		#the amount of x and z steps is equal to the size of the grid divided by the
		#size of each cell in the grid
		var x_steps = aabb.size.x / cell_size
		var z_steps = aabb.size.z / cell_size
		var start_point = aabb.position + Vector3(cell_size/2, 0, cell_size/2)
		
		for x in x_steps -1:
			for z in z_steps -2:
				var next_point = start_point + Vector3(x * cell_size, 0, z * cell_size)
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
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GREEN
		mesh_instance.set_surface_override_material(0, material)
		cube.size = Vector3(0.5, 0.5, 0.5)
		add_child(mesh_instance)
		mesh_instance.global_transform.origin = Vector3(world_pos_int.x, 2, world_pos_int.z)
		get_tree().root.get_node("Level").add_child(mesh_instance)
		
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
				

func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var start_id = astar.get_closest_point(from)
#	print("start id: ", start_id)
	var end_id = astar.get_closest_point(to)
#	print("end id: ", end_id)
#	print("points: ", points)
	
	var id = 0
	for point in points:
		id+= 1
	
	return astar.get_point_path(start_id, end_id)

#rounds the coordinates of the "world" argument, to be snapped to nearest cell in the AStar grid
func _world_to_astar(world : Vector3) -> String:
	var x = snapped(world.x, cell_size)
	var y = snapped(world.y, cell_size)
	var z = snapped(world.z, cell_size)
	return "%d, %d, %d" % [x, y, z]
