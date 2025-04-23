extends Control

@export var crosshair_distance_min: float = 10.0
@export var crosshair_distance_max: float = 40.0
@export var crosshair_smooth_speed: float = 15.0
@export var player_path: NodePath
@export var default_color: Color = Color.WHITE
@export var hit_color: Color = Color.RED

var current_distance: float = 6.0
var player: CharacterBody3D
var is_target_hit: bool = false

func _ready():
	if player_path != NodePath(""):
		player = get_node(player_path)

func _process(delta):
	if player == null:
		return

	var speed = player.velocity.length()
	var max_speed = 10.0
	var t = clamp(speed / max_speed, 0.0, 1.0)
	var target_distance = lerp(crosshair_distance_min, crosshair_distance_max, t)
	current_distance = lerp(current_distance, target_distance, delta * crosshair_smooth_speed)

	var color = hit_color if is_target_hit else default_color
	var line_length = 10.0

	_update_line("Top", Vector2(0, -1), current_distance, line_length, color)
	_update_line("Bottom", Vector2(0, 1), current_distance, line_length, color)
	_update_line("Left", Vector2(-1, 0), current_distance, line_length, color)
	_update_line("Right", Vector2(1, 0), current_distance, line_length, color)

	queue_redraw()

func _update_line(name: String, direction: Vector2, spacing: float, length: float, color: Color) -> void:
	var line = get_node(name) as Line2D
	var start = direction.normalized() * spacing
	var end = direction.normalized() * (spacing + length)

	line.clear_points()
	line.add_point(start)
	line.add_point(end)
	line.default_color = color

func _draw():
	var color = hit_color if is_target_hit else default_color
	draw_circle(Vector2.ZERO, 1.5, color)

func set_targeting_state(hit: bool) -> void:
	is_target_hit = hit
