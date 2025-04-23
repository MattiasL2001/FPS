extends Node

signal state_changed(new_state: int)

enum AIState { IDLE, PATROLLING, CHASING, ATTACKING, DEAD }

var state: AIState = AIState.IDLE

func set_state(new_state: AIState) -> void:
	if new_state != state:
		state = new_state
		print("[STATEMACHINE] State ändrat till:", AIState.keys()[new_state])
		emit_signal("state_changed", new_state)

func get_state() -> AIState:
	return state

func get_state_name() -> String:
	return AIState.keys()[state]
