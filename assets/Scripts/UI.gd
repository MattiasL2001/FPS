extends Control

@onready var speed_text = $speed_text
@onready var ammo_text = $ammo_text
@onready var coords_text = $coords_text
@onready var health_text = $health_text
@onready var FPS_text = $FPS_text
@onready var interact_text = $interact_text
@onready var hotbar_text = $Hotbar_text
@onready var player : CharacterBody3D = self.get_parent().get_parent().get_parent()

func _ready():
	speed_text.set_text("Speed: ")
	ammo_text.set_text("Ammo: ")
	interact_text.set_visible(false)

func _process(delta):
	FPS_text.set_text("FPS: " + str(Engine.get_frames_per_second()))
	coords_text.set_text(
		"Coords: " + "X: " + str(round(player.position.x)) + "   Z: " + str(round(player.position.z)))

func _on_player_speed_changed(speed):
	speed_text.set_text("Speed: " + str(speed))

func _on_player_health_changed(health):
	health_text.set_text("Health: " + str(health))

func _on_lightSwitch_interaction(collider):
	if collider != null and collider.is_in_group("Player"):
		interact_text.set_visible(true)
	else:
		interact_text.set_visible(false)

func _on_player_weapon_changed(current_weapon):
	hotbar_text.set_text(str(current_weapon))

func _on_player_ammo_changed(current_ammo, ammo_total):
	ammo_text.set_text(str(current_ammo) + "/" + str(ammo_total))
