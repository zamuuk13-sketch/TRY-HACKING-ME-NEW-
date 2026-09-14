extends CharacterBody2D
## TRY HACKING ME NOW — Player controller
## Star 2: movement + gravity + jump + basic stickman presentation.

@export_category("Movement")
@export var move_speed: float = 260.0
@export var sprint_speed: float = 390.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_power: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

var facing_direction := 1.0
var is_sprinting := false
var last_grounded := false

func _physics_process(delta: float) -> void:
	var input_axis := Input.get_axis("move_left", "move_right")
	is_sprinting = Input.is_key_pressed(KEY_SHIFT)

	var target_speed := sprint_speed if is_sprinting else move_speed
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
		if Input.is_action_just_pressed("jump"):
			velocity.y = -jump_power

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Clean cartoon stickman. The actual art can be replaced later without
	# changing the runtime object or physics architecture.
	var body_color := Color("f4f4f4")
	var outline := Color("171717")
	var accent := Color("e8b44d")

	draw_circle(Vector2(0, -30), 13.0, outline)
	draw_circle(Vector2(0, -30), 10.0, body_color)
	draw_line(Vector2(0, -17), Vector2(0, 18), outline, 6.0, true)
	draw_line(Vector2(0, -14), Vector2(20 * facing_direction, 2), outline, 5.0, true)
	draw_line(Vector2(0, -14), Vector2(-17 * facing_direction, 5), outline, 5.0, true)
	draw_line(Vector2(0, 18), Vector2(12 * facing_direction, 40), outline, 6.0, true)
	draw_line(Vector2(0, 18), Vector2(-12 * facing_direction, 40), outline, 6.0, true)

	if is_sprinting:
		draw_line(Vector2(-7, -39), Vector2(7, -39), accent, 3.0, true)
