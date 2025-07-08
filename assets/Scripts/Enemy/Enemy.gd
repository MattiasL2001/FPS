extends CharacterBody3D
class_name Enemy

enum EnemyType { MELEE, RIFLE, SNIPER }
@export var enemy_type: EnemyType

@onready var body_mesh: MeshInstance3D = $Body/BodyMesh

@onready var state_machine = $AIController/StateMachine
@onready var combat_handler = $AIController/CombatHandler
@onready var movement_handler = $AIController/MovementHandler

@onready var rifle = $Weapons/M16
@onready var sniper = $Weapons/AWP
@onready var melee = $Weapons/Knife_6
@onready var perception_handler: Node = $AIController/PerceptionHandler

@export var player_target: Player = null
var health := 100

func _ready():
	state_machine.connect("state_changed", _on_state_changed)

	if perception_handler and perception_handler.has_signal("player_detected"):
		perception_handler.connect("player_detected", Callable(self, "_on_perception_handler_player_detected"))

	rifle.visible = false
	sniper.visible = false
	melee.visible = false

	match enemy_type:
		EnemyType.MELEE:
			melee.visible = true
		EnemyType.RIFLE:
			rifle.visible = true
		EnemyType.SNIPER:
			sniper.visible = true

func on_body_entered(body):
	if body.is_in_group("Player"):
		player_target = body
		set_ai_state(state_machine.AIState.CHASING)

func on_body_exited(body):
	if body.is_in_group("Player"):
		player_target = null
		set_ai_state(state_machine.AIState.IDLE)

func take_damage(damage: int):
	health -= damage
	if health <= 0:
		kill()

func kill():
	set_ai_state(state_machine.AIState.DEAD)
	queue_free()

func set_ai_state(new_state: int):
	if state_machine.get_state() != new_state:
		state_machine.set_state(new_state)

func _on_state_changed(new_state: int):
	# Färgfeedback
	var color := Color.DARK_BLUE
	match new_state:
		state_machine.AIState.CHASING:
			color = Color.RED
		state_machine.AIState.IDLE:
			color = Color.YELLOW

	if body_mesh and body_mesh.mesh:
		var mat = body_mesh.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			body_mesh.material_override = mat.duplicate()
			body_mesh.material_override.albedo_color = color

	if movement_handler.has_method("on_state_changed"):
		movement_handler.on_state_changed(new_state)
	if combat_handler.has_method("on_state_changed"):
		combat_handler.on_state_changed(new_state)
