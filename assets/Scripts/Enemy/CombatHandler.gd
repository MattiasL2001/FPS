extends Node

@onready var enemy = get_parent().get_parent()
@onready var eyes = enemy.get_node("Eyes")
@onready var raycast = eyes.get_node("RayCastShooting")
@onready var shoottimer = enemy.get_node("ShootTimer")

var damage := 20
var enabled := false

func enable():
	enabled = true
	shoottimer.start()

func disable():
	enabled = false
	shoottimer.stop()

func _on_shoot_timer_timeout():
	if !enabled:
		return
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit.is_in_group("Player"):
			hit.damage(damage)
