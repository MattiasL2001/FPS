extends Node3D
class_name Weapon

@export var weapon_name: String = "Unnamed"
@export var weapon_type: WeaponType.Type
@export var is_active: bool = false
@export var can_aim: bool = false
@export var damage: int = 0

@onready var player: CharacterBody3D = get_node("../../../../")
@onready var camera: Camera3D = get_node("../../")
@onready var attack_audio: AudioStreamPlayer3D = get_node_or_null("AttackAudio")
@onready var clip_audio: AudioStreamPlayer3D = get_node_or_null("ClipAudio")
@onready var animation_player: AnimationPlayer = get_node("../../UI/Reloading/AnimationPlayer")

func activate():
	visible = true
	is_active = true
	process_mode = 0

func deactivate():
	visible = false
	is_active = false
	process_mode = 4

func stop_all_sounds():
	if attack_audio and attack_audio.playing:
		attack_audio.stop()
	if clip_audio and clip_audio.playing:
		clip_audio.stop()

func set_aiming(state: bool) -> void:
	if not can_aim:
		return

func _set_layer_recursively(node: Node) -> void:
	for child in node.get_children():
		if "layers" in child:
			child.layers = 2
		if child.get_child_count() > 0:
			_set_layer_recursively(child)
