extends CharacterBody2D
## TRY HACKING ME NOW — procedural Player controller.
## Movement/physics preserved. Character is rendered entirely with _draw().

@export_category("Movement")
@export var move_speed: float = 260.0
@export var sprint_speed: float = 390.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_power: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

@export_category("Animation")
@export var animation_fps: float = 12.0
@export var animation_frames: int = 12

var facing_direction: float = 1.0
var is_sprinting: bool = false
var is_crouching: bool = false
var animation_time: float = 0.0
var animation_frame: int = 0
var animation_state: String = "idle"
var landing_punch: float = 0.0

func _ready() -> void:
	visible = true
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	z_index = 100
	queue_redraw()

func _physics_process(delta: float) -> void:
	var input_axis: float = Input.get_axis("move_left", "move_right")
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	is_sprinting = Input.is_key_pressed(KEY_SHIFT) and not is_crouching

	var target_speed: float = sprint_speed if is_sprinting else move_speed
	if is_crouching:
		target_speed *= 0.45

	if input_axis != 0.0:
		velocity.x = move_toward(velocity.x, input_axis * target_speed, acceleration * delta)
		facing_direction = sign(input_axis)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	var was_on_floor: bool = is_on_floor()
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0
		if Input.is_action_just_pressed("jump") and not is_crouching:
			velocity.y = -jump_power

	move_and_slide()

	if not was_on_floor and is_on_floor():
		landing_punch = 1.0
	landing_punch = move_toward(landing_punch, 0.0, delta * 7.0)

	_update_animation(delta)
	queue_redraw()

func _update_animation(delta: float) -> void:
	var next_state: String = "idle"
	if not is_on_floor():
		next_state = "jump" if velocity.y < 0.0 else "fall"
	elif is_crouching:
		next_state = "crouch"
	elif absf(velocity.x) > 15.0:
		next_state = "run" if is_sprinting else "walk"

	if next_state != animation_state:
		animation_state = next_state
		animation_time = 0.0
		animation_frame = 0
	else:
		animation_time += delta
		var frame_duration: float = 1.0 / maxf(animation_fps, 1.0)
		if animation_time >= frame_duration:
			animation_time -= frame_duration
			animation_frame = (animation_frame + 1) % max(animation_frames, 1)

func _draw_limb(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var outline: Color = Color(0.02, 0.02, 0.025, 1.0)
	draw_line(a, b, outline, width + 3.0, true)
	draw_line(a, b, color, width, true)

func _draw() -> void:
	var skin: Color = Color(0.97, 0.97, 0.97, 1.0)
	var outline: Color = Color(0.02, 0.02, 0.025, 1.0)
	var shirt: Color = Color(0.13, 0.15, 0.18, 1.0)
	var pants: Color = Color(0.075, 0.085, 0.105, 1.0)
	var d: float = facing_direction

	var head: Vector2 = Vector2(0, -31)
	var neck: Vector2 = Vector2(0, -18.5)
	var knee_l: Vector2 = Vector2(-7, 31)
	var knee_r: Vector2 = Vector2(7, 31)
	var ankle_l: Vector2 = Vector2(-7, 49)
	var ankle_r: Vector2 = Vector2(7, 49)
	var elbow_l: Vector2 = Vector2(-13, -1)
	var elbow_r: Vector2 = Vector2(13, -1)
	var hand_l: Vector2 = Vector2(-13, 11)
	var hand_r: Vector2 = Vector2(13, 11)

	if animation_state == "walk":
		var p: float = (float(animation_frame) + animation_time * animation_fps) / float(animation_frames) * TAU
		var s: float = sin(p)
		knee_l.x = -7.0 - s * 8.5
		knee_r.x = 7.0 + s * 8.5
		ankle_l.x = -7.0 - s * 10.0
		ankle_r.x = 7.0 + s * 10.0
		elbow_l.x = -13.0 - s * 6.0
		elbow_r.x = 13.0 + s * 6.0
		hand_l.x = -13.0 - s * 7.0
		hand_r.x = 13.0 + s * 7.0

	if d < 0.0:
		head.x *= -1.0
		neck.x *= -1.0
		knee_l.x *= -1.0
		knee_r.x *= -1.0
		ankle_l.x *= -1.0
		ankle_r.x *= -1.0
		elbow_l.x *= -1.0
		elbow_r.x *= -1.0
		hand_l.x *= -1.0
		hand_r.x *= -1.0

	_draw_limb(Vector2(-6.5, 16), knee_l, 7.0, pants)
	_draw_limb(knee_l, ankle_l, 6.0, pants)
	_draw_limb(Vector2(6.5, 16), knee_r, 7.0, pants)
	_draw_limb(knee_r, ankle_r, 6.0, pants)
	_draw_limb(Vector2(-10, -15), elbow_l, 5.8, shirt)
	_draw_limb(elbow_l, hand_l, 4.8, skin)
	_draw_limb(Vector2(10, -15), elbow_r, 5.8, shirt)
	_draw_limb(elbow_r, hand_r, 4.8, skin)
	_draw_limb(neck, head + Vector2(0, 7), 5.0, skin)

	draw_line(Vector2(-7, -14), Vector2(7, 15), outline, 18.0, true)
	draw_line(Vector2(-7, -14), Vector2(7, 15), shirt, 14.0, true)
	draw_circle(head, 12.0, outline)
	draw_circle(head, 9.7, skin)
	draw_circle(Vector2(head.x + 4.0 * d, head.y - 1.0), 2.0, outline)
