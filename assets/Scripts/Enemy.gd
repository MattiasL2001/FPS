extends CharacterBody3D

@onready var state_machine = $AIController/StateMachine
@onready var combat_handler = $AIController/CombatHandler
@onready var movement_handler = $AIController/MovementHandler

var health := 100

func _on_SightRange_body_entered(body):
	if body.is_in_group("Player"):
		combat_handler.player = body
		movement_handler.set_player(body)  # 👈 viktig fix!
		state_machine.set_state(state_machine.AIState.CHASING)

func _on_SightRange_body_exited(body):
	if body.is_in_group("Player"):
		combat_handler.player = null
		movement_handler.set_player(null)  # nollställ vid utgång
		state_machine.set_state(state_machine.AIState.IDLE)
		movement_handler.stop()

func take_damage(damage: int):
	health -= damage
	if health <= 0:
		state_machine.set_state(state_machine.AIState.DEAD)
		queue_free()
