extends Node

signal player_detected(player: Node3D)

@export var check_interval := 0.3

@onready var enemy: Enemy = get_node("../../") as Enemy
@onready var raycast: RayCast3D = enemy.get_node("Eyes/RayCastShooting")

var timer := 0.0
var player_seen := false

func _process(delta: float) -> void:
	timer += delta
	if timer < check_interval:
		return
	timer = 0.0

	if player_seen:
		return

	#var player = enemy.player_target
	#if player == null:
		#print(enemy.name, " ❌ NO player_target")
		#return
#
	#if not is_instance_valid(player):
		#print(enemy.name, " ❌ Invalid player instance")
		#return
#
	#if raycast == null:
		#print(enemy.name, " ❌ Raycast is null!")
		#return
#
	## Uppdatera raycastens riktning
	#raycast.look_at(player.global_transform.origin)
	#raycast.force_raycast_update()
#
	#if raycast.is_colliding():
		#var hit = raycast.get_collider()
		#print(enemy.name, " 👁 Raycast hit: ", hit.name)
		#if hit == player:
			#print(enemy.name, " ✅ Sees player – emitting signal")
			#player_seen = true
			#emit_signal("player_detected", player)
	#else:
		#print(enemy.name, " 🚫 Raycast found no hit")
