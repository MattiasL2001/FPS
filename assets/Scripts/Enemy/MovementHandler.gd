extends Node

@onready var enemy: Enemy = get_parent().get_parent()
@onready var agent: NavigationAgent3D = enemy.get_node("NavigationAgent3D")
@onready var raycast: RayCast3D = enemy.get_node("Eyes/RayCastShooting")
@onready var state_machine: Node = get_parent().get_node("StateMachine")

var patrol_positions: Array[Vector3] = []
var current_patrol_index := 0

var patrolling := true
var has_spotted := false
var patrol_loop_started := false

@export var patrol_radius := 5.0
@export var patrol_point_count := 3
@export var move_speed := 3.0
@export var gravity := 0.98
@export var wait_time := 1.5

var repath_timer := 0.0
const REPTH_INTERVAL := 2.0

func _ready():
	state_machine.connect("state_changed", _on_state_changed)
	await get_tree().process_frame
	_generate_patrol_points()

func _physics_process(delta):
	var direction = Vector3.ZERO
	var current_state = state_machine.get_state()

	if patrolling and not patrol_loop_started:
		patrol_loop_started = true
		_start_patrol_loop()

	match current_state:
		state_machine.AIState.CHASING:
			if enemy.player_target:
				_handle_chasing_behavior(delta)
		state_machine.AIState.ATTACKING:
			pass
		state_machine.AIState.PATROLLING:
			pass
		state_machine.AIState.IDLE:
			pass

	if not agent.is_navigation_finished():
		var next_pos = agent.get_next_path_position()
		direction = (next_pos - enemy.global_position).normalized()

	enemy.velocity.x = direction.x * move_speed
	enemy.velocity.z = direction.z * move_speed
	enemy.velocity.y = 0 if enemy.is_on_floor() else enemy.velocity.y - gravity
	enemy.move_and_slide()

	if enemy.player_target:
		_rotate_towards(enemy.player_target.global_position)

	if enemy.enemy_type == Enemy.EnemyType.MELEE and enemy.player_target:
		var dist = enemy.global_position.distance_to(enemy.player_target.global_position)
		current_state = state_machine.get_state()
		if current_state == state_machine.AIState.CHASING and dist < 2.0:
			set_state(state_machine.AIState.ATTACKING)
		elif current_state == state_machine.AIState.ATTACKING and dist >= 2.5:
			set_state(state_machine.AIState.CHASING)

func _handle_chasing_behavior(delta: float) -> void:
	match enemy.enemy_type:
		Enemy.EnemyType.MELEE:
			agent.set_target_position(enemy.player_target.global_position)

		Enemy.EnemyType.SNIPER, Enemy.EnemyType.RIFLE:
			repath_timer -= delta
			if repath_timer <= 0.0:
				repath_timer = REPTH_INTERVAL
				var new_target = get_ideal_target_position(enemy.player_target.global_position)
				agent.set_target_position(new_target)

func get_ideal_target_position(base_pos: Vector3) -> Vector3:
	var best_score := -INF
	var best_pos
	var min_distance := 3.0
	var max_distance := 6.0
	var step := 16

	for i in range(step):
		var angle = i * (TAU / step)
		var offset = Vector3(cos(angle), 0, sin(angle)) * randf_range(min_distance, max_distance)
		var candidate = base_pos + offset

		var has_line_of_sight := true
		var ray = PhysicsRayQueryParameters3D.create(enemy.global_position, candidate)
		ray.exclude = [enemy]
		var result = enemy.get_world_3d().direct_space_state.intersect_ray(ray)
		if result and result.collider.is_in_group("Enemies"):
			has_line_of_sight = false

		var separation_score = 0.0
		for other in get_tree().get_nodes_in_group("Enemies"):
			if other == enemy:
				continue
			var dist = other.global_position.distance_to(candidate)
			separation_score += clamp(dist, 0, 10)

		var score = separation_score
		if not has_line_of_sight:
			score -= 100

		if score > best_score:
			best_score = score
			best_pos = candidate

	return best_pos if best_pos else base_pos

func _on_state_changed(new_state: int) -> void:
	if new_state == state_machine.AIState.CHASING and enemy.player_target:
		chase(enemy.player_target)

func _rotate_towards(target: Vector3):
	var dir = target - enemy.global_position
	dir.y = 0
	var angle = atan2(dir.x, dir.z) + PI
	enemy.rotation.y = lerp_angle(enemy.rotation.y, angle, 0.1)

func _generate_patrol_points():
	patrol_positions.clear()
	var tries := 0
	while patrol_positions.size() < patrol_point_count and tries < 50:
		tries += 1
		var offset = Vector3(
			randf_range(-patrol_radius, patrol_radius),
			0,
			randf_range(-patrol_radius, patrol_radius)
		)
		var goal_position = enemy.global_position + offset
		goal_position.y = 0.25

		agent.set_target_position(goal_position)
		if agent.is_target_reachable():
			var path = agent.get_current_navigation_path()
			if path.size() > 1:
				patrol_positions.append(path[-1])

func _start_patrol_loop() -> void:
	await get_tree().process_frame
	set_state(state_machine.AIState.PATROLLING)

	while patrolling and not has_spotted and patrol_positions.size() > 0:
		var next_pos = patrol_positions[current_patrol_index]
		agent.set_target_position(next_pos)

		while not agent.is_navigation_finished() and not has_spotted:
			await get_tree().process_frame

		if has_spotted:
			break

		await get_tree().create_timer(wait_time).timeout
		current_patrol_index = (current_patrol_index + 1) % patrol_positions.size()

func set_state(new_state: int):
	state_machine.set_state(new_state)

func chase(new_target: Node3D):
	patrolling = false
	enemy.player_target = new_target
	has_spotted = true
	set_state(state_machine.AIState.CHASING)

	match enemy.enemy_type:
		Enemy.EnemyType.MELEE:
			agent.set_target_position(enemy.player_target.global_position)
		Enemy.EnemyType.SNIPER:
			agent.set_target_position(enemy.global_position)
		Enemy.EnemyType.RIFLE:
			var offset = Vector3(2, 0, -2)
			agent.set_target_position(enemy.player.global_position + offset)

func stop():
	patrolling = true
	enemy.player_target = null
	has_spotted = false
	patrol_loop_started = false
	current_patrol_index = 0
	set_state(state_machine.AIState.PATROLLING)
	_generate_patrol_points()
	if patrol_positions.size() > 0:
		agent.set_target_position(patrol_positions[0])
