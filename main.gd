extends Node2D

const SPEED := 280.0
const PLAYER_RADIUS := 16.0
var player := Vector2(576, 400)
var facing := Vector2.DOWN
var arena := Rect2(48, 156, 1056, 484)
var moving := false
var clock := 0.0

func _ready() -> void:
	var title := Label.new()
	title.text = "Project 5 In Progress"
	title.position = Vector2(0, 37)
	title.size = Vector2(1152, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("edf4ff"))
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A new world starts here."
	subtitle.position = Vector2(0, 92)
	subtitle.size.x = 1152
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 17)
	subtitle.add_theme_color_override("font_color", Color("8498b5"))
	add_child(subtitle)
	var controls := Label.new()
	controls.text = "W A S D  /  MOVE                 R  /  RESET"
	controls.position = Vector2(0, 669)
	controls.size.x = 1152
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.add_theme_font_size_override("font_size", 16)
	controls.add_theme_color_override("font_color", Color("91a7c4"))
	add_child(controls)

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()
	moving = direction != Vector2.ZERO
	if moving:
		facing = direction
	player += direction * SPEED * delta
	player = player.clamp(arena.position + Vector2.ONE * PLAYER_RADIUS, arena.end - Vector2.ONE * PLAYER_RADIUS)
	if Input.is_physical_key_pressed(KEY_R):
		player = arena.get_center()
	clock += delta
	queue_redraw()

func _draw() -> void:
	draw_style_box(_panel_style(), arena)
	for x in range(80, 1104, 32):
		for y in range(188, 640, 32):
			draw_circle(Vector2(x, y), 1, Color(0.22, 0.32, 0.45, 0.45))
	var center := arena.get_center()
	draw_arc(center, 38, 0, TAU, 48, Color(0.3, 0.55, 0.67, 0.22), 1.0, true)
	draw_line(center - Vector2(7, 0), center + Vector2(7, 0), Color("344b60"), 1, true)
	draw_line(center - Vector2(0, 7), center + Vector2(0, 7), Color("344b60"), 1, true)
	draw_circle(player + Vector2(0, 7), 20, Color(0, 0, 0, 0.25))
	var pulse := 29.0 + sin(clock * 2.4) * 2.0
	draw_circle(player, pulse, Color(0.25, 0.9, 0.77, 0.055))
	draw_circle(player, PLAYER_RADIUS + 3, Color("1d736e"))
	draw_circle(player, PLAYER_RADIUS, Color("64ead0"))
	draw_circle(player + facing * 7, 4, Color("113b43"))

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101e30")
	style.border_color = Color("29405a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	return style
