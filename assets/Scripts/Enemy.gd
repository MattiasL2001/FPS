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
@onready var astar = get_tree().root.get_node("Level").get_node("AStar")
@onready var diagonal_movement : bool
var max_look_angle_y : int = 75
var max_look_angle_x : int = 50
var speed = 3.0
var gravity : float = 0.98
var health : int = 100
var damage : int = 20
var head_basis
var direction : Vector3 = Vector3()
var look_dir_hor
var look_dir_ver
var path := []
var current_point_in_path = 0
var reached_point : bool = false
var current_target := Vector3()

func _ready():
	_movement()

func _process(delta):
	match state:
		IDLE:
			velocity = Vector3()
		ALERT:
			if path.size() > 1 and sqrt(pow(transform.origin.x - path[current_point_in_path].position[0], 2) +
			pow(transform.origin.z - path[current_point_in_path].position[2], 2)) >= .5:
				eyes.look_at(path[current_point_in_path +1].position)
				rotate_y(deg_to_rad(eyes.rotation.y * TURN_SPEED))
#				velocity = Vector3(-get_basis().z.x * speed, velocity.y, -get_basis().z.z * speed)
			else:
				velocity = Vector3()
	
func _physics_process(delta):
	head_basis = eyes.get_global_transform().basis
	direction = Vector3()
	
#	for i in range (get_slide_collision_count() -1):
#		var collision = get_last_slide_collision()
#		if collision != null:
#			print (collision.to_string() + "!!!")
	velocity.y -= gravity
	move_and_slide()
	var new_velocity := Vector3.ZERO

func _movement():
	match state:
		IDLE:
			path = []
			velocity = Vector3()
			if (look_dir_hor == "left" and rad_to_deg(eyes.get_basis().get_euler().y) <= max_look_angle_y):
				eyes.rotate_y(deg_to_rad(get_rotation().y) +0.05 * TURN_SPEED)
			else:
				look_dir_hor = "right"
				
			if (look_dir_hor == "right" and rad_to_deg(eyes.get_basis().get_euler().y) >= -max_look_angle_y):
				eyes.rotate_y(deg_to_rad(get_rotation().y) -0.05 * TURN_SPEED)
			else:
				look_dir_hor = "left"
			
			for child in astar.get_children():
				var mesh : MeshInstance3D = child
				var material : StandardMaterial3D = StandardMaterial3D.new()
				material.albedo_color = Color.GREEN
				mesh.set_surface_override_material(0, material)

		ALERT:
			if target != null:
				var dir_to_target = global_transform.origin.direction_to(current_target).normalized()
				if global_transform.origin.distance_to(current_target) < 0.5:
					find_next_point_in_path()
				var points = astar.get_points()
				print("from: ", get_transform().origin)
				path = _find_path(get_transform().origin, target.get_transform().origin)
				eyes.get_basis().get_euler().y = 0
				
				for point in path:
					var mesh : MeshInstance3D = get_tree().root.get_node("Level").get_node("AStar").get_node("cube_mesh_" + astar.get_astar_id(point.position))
					var material : StandardMaterial3D = StandardMaterial3D.new()
					material.albedo_color = Color.WHITE
					if mesh != null:
						mesh.set_surface_override_material(0, material)
			
	await(get_tree().create_timer(3).timeout)
	_movement()

func _on_SightRange_body_entered(body):
	if (body.is_in_group("Player")):
		state = ALERT
		target = body
		shoottimer.start()
		_state_transition()

func _on_SightRange_body_exited(body):
	if (body.is_in_group("Player")):
		state = IDLE
		target = null
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

func _find_path(from: Vector3, to: Vector3) -> Array:
	var active_points : Dictionary
	
	for point in astar.points:
		if astar.points[point].is_active:
			astar.points[point].position[0] = round(astar.points[point].position[0])
			astar.points[point].position[2] = round(astar.points[point].position[2])
			var id = astar.get_astar_id(astar.points[point].position)
			active_points.merge({id: astar.points[point]})
	
	var open_points : Dictionary = active_points
	var closed_points : Dictionary = {}
	
	from = astar.world_to_astar(from)
	to = astar.world_to_astar(to)
	var start_point : AStar_Cell
	if astar.points[astar.get_astar_id(from)] != null:
		start_point = astar.points[astar.get_astar_id(from)]
	else:
		astar.points[astar.get_astar_id(from)] = astar.world_to_astar(from)
		start_point = astar.points[astar.get_astar_id(from)]
	
	var end_point : AStar_Cell = astar.points[astar.get_astar_id(to)]
	open_points.merge({astar.get_astar_id(start_point.position): start_point})
	var current_node : AStar_Cell = start_point
	closed_points.merge({astar.get_astar_id(start_point.position): start_point})
	open_points.erase(astar.get_astar_id(start_point.position))
	var path_packed = []
	var iterate = 0
	var lowest_f_cost = null
	
	while iterate < 50:
		iterate += 1
		var result = astar.evaluate_neighbors(astar.points[astar.get_astar_id(current_node.position)], start_point, end_point)
		var c = 0
		for neighbor in result[0]:
			c += 10
			neighbor = astar.points[astar.get_astar_id(neighbor)]
			if neighbor.get_f_cost(neighbor.g_cost, neighbor.h_cost) <= result[1] and open_points.has(astar.get_astar_id(neighbor.position)):
				current_node = neighbor
				var mesh : MeshInstance3D = get_tree().root.get_node("Level").get_node("AStar").get_node("cube_mesh_" + astar.get_astar_id(neighbor.position))
				var material : StandardMaterial3D = StandardMaterial3D.new()
				material.albedo_color = Color(0 + c/25, 0, 0, 1)
				if mesh != null:
					mesh.set_surface_override_material(0, material)
				print(current_node)
		open_points.erase(current_node)
		closed_points.merge({astar.points[astar.get_astar_id(current_node.position)]: current_node})
		
		if astar.points[astar.get_astar_id(current_node.position)] == astar.points[astar.get_astar_id(to)]:
			path_packed = _trace_path(start_point, end_point)
			print("wohoo!")
			return path_packed
		
		for neighbor in astar.points[astar.get_astar_id(current_node.position)].neighbors:
			var n = neighbor
			neighbor = astar.points[astar.get_astar_id(neighbor)]
			if !neighbor.is_active or neighbor.is_blocked or closed_points.has(neighbor):
				continue
			
			var new_movement_cost = astar.points[astar.get_astar_id(current_node.position)].g_cost + astar.calculate_distance(current_node.position, neighbor.position)
			if new_movement_cost < astar.points[astar.get_astar_id(current_node.position)].g_cost or !open_points.has(neighbor):
				neighbor.g_cost = new_movement_cost
				neighbor.h_cost = astar.calculate_distance(neighbor.position, end_point.position)
				neighbor.parent = astar.points[astar.get_astar_id(current_node.position)]
				
				if open_points.has(astar.get_astar_id(neighbor.position)) == false:
					print("!!")
					open_points.merge({astar.get_astar_id(neighbor.position): neighbor})
		
	return path_packed

func _trace_path(from : AStar_Cell, to : AStar_Cell):
	var current : AStar_Cell = to
	var point_path = []
	
	while current != from:
		point_path.append(current)
		current = current.parent
	point_path.reverse()
	return point_path

func find_next_point_in_path():
	if path.size() > 0:
		var new_target = path.pop_front()
		new_target.y = global_transform.origin.y
		current_target = new_target
	else:
		current_target = Vector3()
