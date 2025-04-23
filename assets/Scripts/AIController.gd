extends Node

@onready var state_machine = $StateMachine
@onready var movement = $MovementHandler
@onready var combat = $CombatHandler

func _ready():
	state_machine.set_state(state_machine.AIState.IDLE)
	state_machine.state_changed.connect(_on_state_changed)

func _on_state_changed(new_state: String):
	match new_state:
		"IDLE":
			movement.stop()
			combat.disable()
		"ALERT":
			movement.chase(combat.get_target())
			combat.enable()
