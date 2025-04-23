extends Node

@onready var enemy: CharacterBody3D = get_parent().get_parent()
@onready var agent: NavigationAgent3D = enemy.get_node("NavigationAgent3D")
@onready var raycast: RayCast3D = enemy.get_node("Eyes/RayCastShooting")
@onready var state_machine: Node = get_parent().get_node("StateMachine")

var patrol_positions: Array[Vector3] = []
var current_patrol_index := 0
var player: Node3D = null

var patrolling := true
var has_spotted := false
var patrol_loop_started := false

@export var patrol_radius := 5.0
@export var patrol_point_count := 3
@export var move_speed := 3.0
@export var gravity := 0.98
@export var wait_time := 1.5

enum AIBehavior { RUSH, HOLD_POSITION, FLANK }
@export var behavior: AIBehavior = AIBehavior.RUSH

func _ready():
	state_machine.connect("state_changed", _on_state_changed)
	await get_tree().process_frame
	_generate_patrol_points()
	if patrol_positions.size() > 0:
		print("[READY] Startar patrullering mot:", patrol_positions[0])
	else:
		print("[FEL] Inga patrullpunkter genererade!")

func _physics_process(delta):
	var direction = Vector3.ZERO

	if patrolling and !patrol_loop_started:
		patrol_loop_started = true
		_start_patrol_loop()

	if not agent.is_navigation_finished():
		var next_pos = agent.get_next_path_position()
		direction = (next_pos - enemy.global_position).normalized()

	enemy.velocity.x = direction.x * move_speed
	enemy.velocity.z = direction.z * move_speed
	if enemy.is_on_floor():
		enemy.velocity.y = 0
	else:
		enemy.velocity.y -= gravity

	enemy.move_and_slide()
	_rotate_towards(direction)

	if state_machine.get_state() == state_machine.AIState.CHASING and player:
		var dist = enemy.global_position.distance_to(player.global_position)
		if dist < 2.0:
			set_state(state_machine.AIState.ATTACKING)
			print("[ATTACK] Inom räckvidd, byter till ATTACKING")

	# Raycast för att upptäcka spelare
	if player != null and not has_spotted:
		raycast.look_at(player.global_position)
		raycast.force_raycast_update()
		if raycast.is_colliding() and raycast.get_collider() == player:
			has_spotted = true
			print("[DETEKTION] Spelare upptäckt!")
			set_state(state_machine.AIState.CHASING)

func _on_state_changed(new_state: int):
	if new_state == state_machine.AIState.CHASING and player != null:
		chase(player)

func _rotate_towards(direction: Vector3):
	if direction.length() < 0.01:
		return
	var flat_direction = Vector3(direction.x, 0, direction.z).normalized()
	var target_rotation = atan2(flat_direction.x, flat_direction.z)
	enemy.rotation.y = lerp_angle(enemy.rotation.y, target_rotation, 0.1)

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
				print("[PATHGEN] Lägger till:", path[-1])
			else:
				print("[PATHGEN] Path för kort (", path.size(), ")")
		else:
			print("[PATHGEN] Otillgänglig punkt:", goal_position)

	print("[PATHGEN] Totalt:", patrol_positions.size(), "punkter")

func _start_patrol_loop() -> void:
	await get_tree().process_frame
	set_state(state_machine.AIState.PATROLLING)

	while patrolling and !has_spotted and patrol_positions.size() > 0:
		var next_pos = patrol_positions[current_patrol_index]
		print("[PATRULL] Går till punkt", current_patrol_index, "→", next_pos)

		agent.set_target_position(next_pos)

		while not agent.is_navigation_finished() and !has_spotted:
			await get_tree().process_frame

		if has_spotted:
			break

		print("[PATRULL] Nådde punkt", current_patrol_index, ", väntar", wait_time, "sek")
		await get_tree().create_timer(wait_time).timeout

		current_patrol_index = (current_patrol_index + 1) % patrol_positions.size()

func set_player(target: Node3D):
	player = target

func set_state(new_state: int):
	if state_machine:
		state_machine.set_state(new_state)
	else:
		print("[FEL] Kunde inte byta state – state_machine saknas")

func chase(new_target: Node3D):
	patrolling = false
	player = new_target
	has_spotted = true
	set_state(state_machine.AIState.CHASING)

	match behavior:
		AIBehavior.RUSH:
			print("[CHASE] RUSH – springer rakt på spelaren")
			agent.set_target_position(player.global_position)

		AIBehavior.HOLD_POSITION:
			print("[CHASE] HOLD_POSITION – stannar kvar och skjuter")
			agent.set_target_position(enemy.global_position)

		AIBehavior.FLANK:
			print("[CHASE] FLANK – försöker gå runt")
			var offset = Vector3(2, 0, -2)
			agent.set_target_position(player.global_position + offset)

func stop():
	print("[STOP] Slutar jaga, återgår till patrull")
	patrolling = true
	player = null
	has_spotted = false
	patrol_loop_started = false
	current_patrol_index = 0
	set_state(state_machine.AIState.PATROLLING)
	_generate_patrol_points()
	if patrol_positions.size() > 0:
		agent.set_target_position(patrol_positions[0])
