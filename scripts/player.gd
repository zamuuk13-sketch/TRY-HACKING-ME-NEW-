extends CharacterBody2D
## TRY HACKING ME NOW — Player controller + direct PNG animation
## O personagem é um Sprite2D real da pasta imageens.
## A colisão continua independente do visual.

@export_category("Movement")
@export var move_speed: float = 260.0
@export var sprint_speed: float = 390.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_power: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

@export_category("Visual Animation")
@export var walk_bob: float = 2.0
@export var run_bob: float = 3.5
@export var animation_smoothing: float = 12.0

@onready var player_sprite: Sprite2D = $StickmanSprite

var facing_direction := 1.0
var is_sprinting := false
var is_crouching := false
var animation_state := "idle"
var animation_time := 0.0
var was_on_floor := false
var base_scale := Vector2.ONE * 0.62
var target_rotation := 0.0
var target_scale := base_scale
var target_position := Vector2(0, -2)

func _ready() -> void:
	z_index = 100
	player_sprite.visible = true
	player_sprite.modulate = Color.WHITE
	player_sprite.scale = base_scale
	player_sprite.position = target_position
	player_sprite.rotation = 0.0
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()

func _physics_process(delta: float) -> void:
	var input_axis := Input.get_axis("move_left", "move_right")
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	is_sprinting = Input.is_key_pressed(KEY_SHIFT) and not is_crouching

	var target_speed := sprint_speed if is_sprinting else move_speed
	if is_crouching:
		target_speed *= 0.45

	if input_axis != 0.0:
		velocity.x = move_toward(velocity.x, input_axis * target_speed, acceleration * delta)
		facing_direction = sign(input_axis)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0
		if Input.is_action_just_pressed("jump") and not is_crouching:
			velocity.y = -jump_power

	move_and_slide()
	_update_animation_state()
	_update_visual(delta)
	was_on_floor = is_on_floor()
	queue_redraw()

func _update_animation_state() -> void:
	if not is_on_floor():
		animation_state = "jump" if velocity.y < 0.0 else "fall"
	elif is_crouching:
		animation_state = "crouch"
	elif abs(velocity.x) > 15.0:
		animation_state = "run" if is_sprinting else "walk"
	else:
		animation_state = "idle"

func _update_visual(delta: float) -> void:
	animation_time += delta
	var speed := max(abs(velocity.x), 1.0)
	var phase := animation_time * (7.0 if animation_state == "walk" else 10.5 if animation_state == "run" else 2.0)
	var wave := sin(phase)
	var double_wave := sin(phase * 2.0)

	target_rotation = 0.0
	target_scale = base_scale
	target_position = Vector2(0, -2)

	match animation_state:
		"idle":
			# Respiração muito leve, sem deformar demais o PNG.
			target_position.y = -2.0 + sin(animation_time * 2.2) * 0.8
			target_rotation = sin(animation_time * 1.4) * 0.012

		"walk":
			target_position.y = -2.0 + abs(double_wave) * -walk_bob
			target_rotation = wave * 0.035
			target_scale = base_scale * Vector2(1.0 + abs(wave) * 0.018, 1.0 - abs(wave) * 0.018)

		"run":
			target_position.y = -2.0 + abs(double_wave) * -run_bob
			target_rotation = wave * 0.075
		# Pequena compressão/expansão dá sensação de peso sem deixar feio.
			target_scale = base_scale * Vector2(1.0 + abs(wave) * 0.035, 1.0 - abs(wave) * 0.035)

		"jump":
			target_position.y = -5.0
			target_rotation = -0.045 * facing_direction
			target_scale = base_scale * Vector2(0.96, 1.045)

		"fall":
			target_position.y = -1.0
			target_rotation = 0.035 * facing_direction
			target_scale = base_scale * Vector2(1.02, 0.98)

		"crouch":
			target_position.y = 7.0
			target_rotation = 0.0
			target_scale = base_scale * Vector2(1.08, 0.82)

	# Espelhamento do PNG inteiro. Não altera a imagem original.
	var desired_x := abs(target_scale.x) * facing_direction
	target_scale.x = desired_x

	var weight := min(delta * animation_smoothing, 1.0)
	player_sprite.position = player_sprite.position.lerp(target_position, weight)
	player_sprite.rotation = lerp_angle(player_sprite.rotation, target_rotation, weight)
	player_sprite.scale = player_sprite.scale.lerp(target_scale, weight)

func _draw() -> void:
	# Sombra simples sob o personagem, sem interferir no PNG.
	if is_on_floor():
		var shadow_color := Color(0, 0, 0, 0.16)
		draw_set_transform(Vector2.ZERO)
		draw_ellipse(Vector2(0, 31), Vector2(15, 3.2), shadow_color)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
