extends Node2D
## Blue Dash - endless runner en 2D, sin plugins externos.

const WIDTH := 1280.0
const HEIGHT := 720.0
const GROUND_Y := 571.0
const HERO_X := 235.0
const GRAVITY := 1900.0
const JUMP_VELOCITY := -760.0
const DOUBLE_JUMP_VELOCITY := -700.0
const HERO_SIZE := Vector2(190, 158)

var hero_texture: Texture2D = preload("res://assets/hero.png")
var grass_texture: Texture2D = preload("res://assets/grass.png")
var bin_texture: Texture2D = preload("res://assets/bins.png")
var gull_texture: Texture2D = preload("res://assets/gull.png")

var hero: CharacterBody2D
var hero_sprite: Sprite2D
var grass_nodes: Array[Sprite2D] = []
var objects: Array[Area2D] = []
var rng := RandomNumberGenerator.new()
var score := 0.0
var record := 0
var speed := 420.0
var spawn_countdown := 1.25
var jump_count := 0
var state := "ready" # ready / playing / over
var run_clock := 0.0
var time_alive := 0.0
var hud_score: Label
var hud_record: Label
var message: Label
var caption: Label
var shade: ColorRect
var save_path := "user://record.save"

func _ready() -> void:
	rng.randomize()
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f:
			record = int(f.get_as_text())
	_build_world()
	_show_ready()

func _build_world() -> void:
	# Protagonista con CharacterBody2D y colision fisica rectangular.
	hero = CharacterBody2D.new()
	hero.name = "Hero"
	hero.position = Vector2(HERO_X, GROUND_Y - 77)
	hero.collision_layer = 1
	hero.collision_mask = 2
	add_child(hero)
	var shape := CollisionShape2D.new()
	var box_shape := RectangleShape2D.new()
	box_shape.size = Vector2(94, 116)
	shape.shape = box_shape
	hero.add_child(shape)
	hero_sprite = Sprite2D.new()
	hero_sprite.texture = hero_texture
	hero_sprite.scale = HERO_SIZE / hero_texture.get_size()
	hero.add_child(hero_sprite)
	# Tira de pasto desplazada en bucle.
	for i in range(4):
		var g := Sprite2D.new()
		g.texture = grass_texture
		g.centered = false
		g.position = Vector2(float(i) * 494.0, GROUND_Y - 44.0)
		g.scale = Vector2(494.0 / grass_texture.get_width(), 125.0 / grass_texture.get_height())
		g.z_index = 4
		add_child(g)
		grass_nodes.append(g)
	# HUD
	hud_score = _label("PUNTOS  00000", 30, Vector2(34, 22), Color("f9fbff"))
	hud_record = _label("RÉCORD  00000", 23, Vector2(36, 63), Color("c4eaff"))
	shade = ColorRect.new()
	shade.color = Color(0.02, 0.09, 0.21, 0.66)
	shade.position = Vector2(0, 0)
	shade.size = Vector2(WIDTH, HEIGHT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = 10
	add_child(shade)
	message = _label("BLUE DASH", 64, Vector2(0, 192), Color("ffffff"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.size.x = WIDTH
	message.z_index = 11
	caption = _label("TOCA LA PANTALLA O PRESIONA ESPACIO PARA EMPEZAR\nToca otra vez en el aire para hacer DOBLE SALTO", 24, Vector2(0, 305), Color("d5f3ff"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.size = Vector2(WIDTH, 120)
	caption.z_index = 11

func _label(value: String, font_size: int, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color("163152"))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	add_child(l)
	return l

func _draw() -> void:
	# Cielo simple original para diferenciarlo del fondo negro del material de referencia.
	draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color("76d9ff"))
	draw_rect(Rect2(0, 340, WIDTH, 250), Color("9aebff"))
	draw_circle(Vector2(1085, 123), 71.0, Color("ffe8a1"))
	for c in [Vector2(115, 150), Vector2(490, 99), Vector2(905, 255)]:
		draw_circle(c, 38.0, Color(1, 1, 1, 0.70))
		draw_circle(c + Vector2(43, 9), 30.0, Color(1, 1, 1, 0.70))
		draw_circle(c + Vector2(-32, 13), 26.0, Color(1, 1, 1, 0.70))
	draw_rect(Rect2(0, GROUND_Y, WIDTH, HEIGHT - GROUND_Y), Color("36794a"))
	draw_rect(Rect2(0, GROUND_Y + 82, WIDTH, HEIGHT - GROUND_Y - 82), Color("275f41"))

func _unhandled_input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventScreenTouch:
		tapped = event.pressed
	elif event is InputEventMouseButton:
		tapped = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event.is_action_pressed("jump") and not event.is_echo():
		tapped = true
	if tapped:
		_handle_jump()

func _handle_jump() -> void:
	if state == "ready" or state == "over":
		_start_game()
		return
	if state != "playing" or jump_count >= 2:
		return
	jump_count += 1
	hero.velocity.y = JUMP_VELOCITY if jump_count == 1 else DOUBLE_JUMP_VELOCITY
	if jump_count == 2:
		_spawn_jump_flash()

func _start_game() -> void:
	for obj in objects:
		if is_instance_valid(obj):
			obj.queue_free()
	objects.clear()
	hero.position = Vector2(HERO_X, GROUND_Y - 77)
	hero.velocity = Vector2.ZERO
	jump_count = 0
	score = 0
	speed = 420.0
	time_alive = 0
	spawn_countdown = 1.3
	state = "playing"
	shade.visible = false
	message.visible = false
	caption.visible = false
	_handle_jump()

func _show_ready() -> void:
	state = "ready"
	shade.visible = true
	message.visible = true
	caption.visible = true
	hud_record.text = "RÉCORD  %05d" % record

func _physics_process(delta: float) -> void:
	if state != "playing":
		return
	time_alive += delta
	score += delta * 12.0
	speed = minf(780.0, 420.0 + time_alive * 10.0)
	hud_score.text = "PUNTOS  %05d" % int(score)
	run_clock += delta
	hero.velocity.y += GRAVITY * delta
	hero.move_and_slide()
	if hero.position.y >= GROUND_Y - 77.0:
		hero.position.y = GROUND_Y - 77.0
		hero.velocity.y = 0.0
		jump_count = 0
		hero_sprite.rotation = sin(run_clock * 18.0) * 0.042
	else:
		hero_sprite.rotation = clampf(hero.velocity.y / 4000.0, -0.13, 0.14)
	# Desplazamiento de grass infinito
	for g in grass_nodes:
		g.position.x -= speed * delta * 0.54
		if g.position.x < -494.0:
			var farthest := -9999.0
			for other in grass_nodes:
				farthest = maxf(farthest, other.position.x)
			g.position.x = farthest + 494.0
	spawn_countdown -= delta
	if spawn_countdown <= 0.0:
		_spawn_obstacle()
		spawn_countdown = rng.randf_range(1.18, 1.85) * (420.0 / speed)
	for obj in objects.duplicate():
		if not is_instance_valid(obj):
			objects.erase(obj)
			continue
		obj.position.x -= speed * delta
		if obj.position.x < -180.0:
			objects.erase(obj)
			obj.queue_free()
		elif _overlaps_hero(obj):
			_game_over()
			break

func _spawn_obstacle() -> void:
	var gull := rng.randf() < minf(0.50, 0.28 + time_alive / 100.0)
	var obj := Area2D.new()
	obj.name = "Gaviota" if gull else "Tachos"
	obj.position.x = WIDTH + 110.0
	obj.collision_layer = 4
	obj.collision_mask = 1
	var sprite := Sprite2D.new()
	var hit := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	if gull:
		# Bajo: requiere buen tiempo de salto, medio/alto: se puede pasar por debajo.
		obj.position.y = [GROUND_Y - 116.0, GROUND_Y - 220.0, GROUND_Y - 300.0][rng.randi_range(0, 2)]
		sprite.texture = gull_texture
		sprite.scale = Vector2(130.0 / gull_texture.get_width(), 120.0 / gull_texture.get_height())
		rect.size = Vector2(90, 59)
	else:
		obj.position.y = GROUND_Y - 51.0
		sprite.texture = bin_texture
		sprite.scale = Vector2(130.0 / bin_texture.get_width(), 102.0 / bin_texture.get_height())
		rect.size = Vector2(112, 90)
	obj.add_child(sprite)
	hit.shape = rect
	obj.add_child(hit)
	obj.set_meta("half_size", rect.size * 0.5)
	add_child(obj)
	objects.append(obj)

func _overlaps_hero(obj: Area2D) -> bool:
	# AABB mas acotada que los sprites para perdonar bordes transparentes.
	var half: Vector2 = obj.get_meta("half_size")
	var d := obj.position - hero.position
	return absf(d.x) < half.x + 44.0 and absf(d.y) < half.y + 52.0

func _game_over() -> void:
	state = "over"
	hero.velocity = Vector2.ZERO
	var points := int(score)
	if points > record:
		record = points
		var f := FileAccess.open(save_path, FileAccess.WRITE)
		if f:
			f.store_string(str(record))
	hud_record.text = "RÉCORD  %05d" % record
	shade.visible = true
	message.text = "¡FIN DE PARTIDA!"
	message.visible = true
	caption.text = "PUNTOS: %d     ·     RÉCORD: %d\nTOCA PARA REINTENTAR" % [points, record]
	caption.visible = true

func _spawn_jump_flash() -> void:
	# Pequeño destello temporal en el segundo salto.
	var puff := Polygon2D.new()
	puff.polygon = PackedVector2Array([Vector2(-29, 0), Vector2(0, -20), Vector2(29, 0), Vector2(0, 20)])
	puff.color = Color(0.75, 1.0, 1.0, 0.85)
	puff.position = hero.position + Vector2(-40, 62)
	add_child(puff)
	var tween := create_tween()
	tween.tween_property(puff, "modulate:a", 0.0, 0.23)
	tween.tween_callback(puff.queue_free)
