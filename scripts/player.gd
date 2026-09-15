extends CharacterBody2D
## TRY HACKING ME NOW — procedural player.
## Movement is preserved. Walk uses a controlled 8-pose animation cycle.

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
@export var animation_frames: int = 8

var facing_direction: float = 1.0
var is_sprinting: bool = false
var is_crouching: bool = false
var animation_time: float = 0.0
var animation_frame: int = 0
var animation_state: String = "idle"
var idle_time: float = 0.0
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
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
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
	elif abs(velocity.x) > 15.0:
		next_state = "run" if is_sprinting else "walk"

	if next_state != animation_state:
		animation_state = next_state
		animation_time = 0.0
		animation_frame = 0
		if next_state == "idle":
			idle_time = 0.0
	else:
		if next_state == "idle":
			idle_time += delta
		else:
			animation_time += delta
			var frame_duration: float = 1.0 / maxf(animation_fps, 1.0)
			if animation_time >= frame_duration:
				animation_time -= frame_duration
				animation_frame = (animation_frame + 1) % max(animation_frames, 1)

func _draw() -> void:
	var skin: Color = Color(0.96, 0.96, 0.96, 1.0)
	var skin_shadow: Color = Color(0.72, 0.74, 0.78, 1.0)
	var outline: Color = Color(0.025, 0.028, 0.035, 1.0)
	var shirt: Color = Color(0.12, 0.15, 0.19, 1.0)
	var shirt_light: Color = Color(0.19, 0.23, 0.28, 1.0)
	var pants: Color = Color(0.065, 0.075, 0.095, 1.0)
	var shoe: Color = Color(0.025, 0.028, 0.035, 1.0)

	var d: float = facing_direction
	var body_y: float = 0.0
	var body_lean: float = 0.0
	var head_y: float = -31.0
	var shoulder_y: float = -14.0
	var hip_y: float = 16.0

	var left_knee: Vector2 = Vector2(-7.0, 31.0)
	var right_knee: Vector2 = Vector2(7.0, 31.0)
	var left_ankle: Vector2 = Vector2(-7.0, 49.0)
	var right_ankle: Vector2 = Vector2(7.0, 49.0)
	var left_foot: Vector2 = Vector2(-7.0, 52.0)
	var right_foot: Vector2 = Vector2(7.0, 52.0)
	var left_elbow: Vector2 = Vector2(-13.0, -1.0)
	var right_elbow: Vector2 = Vector2(13.0, -1.0)
	var left_hand: Vector2 = Vector2(-14.0, 11.0)
	var right_hand: Vector2 = Vector2(14.0, 11.0)

	if animation_state == "walk":
		_apply_walk_pose(animation_frame, left_knee, right_knee, left_ankle, right_ankle, left_foot, right_foot, left_elbow, right_elbow, left_hand, right_hand)
		var pose_body_y: float = 0.0
		match animation_frame:
			0, 4:
				pose_body_y = 0.0
			1, 5:
				pose_body_y = 1.8
			2, 6:
				pose_body_y = -0.8
			3, 7:
				pose_body_y = -1.6
		body_y = pose_body_y
		body_lean = 1.0 * d
	else:
		var breath: float = sin(idle_time * TAU * 0.85)
		body_y = breath * 0.45
		if animation_state == "run":
			body_y = -1.0
			body_lean = 2.0 * d
		elif animation_state == "crouch":
			body_y = 10.0
			head_y = -22.0
			shoulder_y = -7.0
			hip_y = 20.0
		elif animation_state == "jump":
			body_y = -2.0
			body_lean = 3.0 * d
		elif animation_state == "fall":
			body_y = 2.0
			body_lean = -2.0 * d

	var torso_top: Vector2 = Vector2(body_lean, shoulder_y + body_y)
	var torso_bottom: Vector2 = Vector2(-body_lean * 0.35, hip_y + body_y)
	var head: Vector2 = Vector2(body_lean * 0.25, head_y + body_y)
	var neck: Vector2 = Vector2(body_lean * 0.05, -19.0 + body_y)
	var shoulder_l: Vector2 = torso_top + Vector2(-9.5, 1.0)
	var shoulder_r: Vector2 = torso_top + Vector2(9.5, 1.0)
	var hip_l: Vector2 = torso_bottom + Vector2(-6.5, 0.0)
	var hip_r: Vector2 = torso_bottom + Vector2(6.5, 0.0)

	left_knee.y += body_y
	right_knee.y += body_y
	left_ankle.y += body_y
	right_ankle.y += body_y
	left_foot.y += body_y
	right_foot.y += body_y
	left_elbow.y += body_y
	right_elbow.y += body_y
	left_hand.y += body_y
	right_hand.y += body_y

	if d < 0.0:
		left_knee.x *= -1.0
		right_knee.x *= -1.0
		left_ankle.x *= -1.0
		right_ankle.x *= -1.0
		left_foot.x *= -1.0
		right_foot.x *= -1.0
		left_elbow.x *= -1.0
		right_elbow.x *= -1.0
		left_hand.x *= -1.0
		right_hand.x *= -1.0

	_draw_limb(hip_l, left_knee, 7.0, pants, outline)
	_draw_limb(left_knee, left_ankle, 6.0, pants, outline)
	_draw_limb(hip_r, right_knee, 7.0, pants, outline)
	_draw_limb(right_knee, right_ankle, 6.0, pants, outline)

	_draw_limb(shoulder_l, left_elbow, 6.0, shirt, outline)
	_draw_limb(left_elbow, left_hand, 4.8, skin, outline)
	_draw_limb(shoulder_r, right_elbow, 6.0, shirt, outline)
	_draw_limb(right_elbow, right_hand, 4.8, skin, outline)

	# Feet are kept close to the ground and angled in the travel direction.
	_draw_limb(left_ankle, left_foot + Vector2(4.0 * d, 0.0), 5.5, shoe, outline)
	_draw_limb(right_ankle, right_foot + Vector2(4.0 * d, 0.0), 5.5, shoe, outline)

	# Neck and torso.
	_draw_limb(neck, head + Vector2(0.0, 8.0), 5.0, skin_shadow, outline)
	draw_line(torso_top, torso_bottom, outline, 19.0, true)
	draw_line(torso_top, torso_bottom, shirt, 14.0, true)
	draw_line(torso_top + Vector2(-3.0, 2.0), torso_bottom + Vector2(-1.0, -2.0), shirt_light, 3.0, true)

	# Head, face and tiny eye highlight.
	draw_circle(head, 12.5, outline)
	draw_circle(head, 10.2, skin)
	var eye: Vector2 = head + Vector2(4.2 * d, -1.3)
	draw_circle(eye, 2.2, outline)
	draw_circle(eye + Vector2(0.55 * d, -0.5), 0.65, Color.WHITE)

	# Shoulder and knee joints give the stickman a cleaner silhouette.
	draw_circle(shoulder_l, 3.8, shirt)
	draw_circle(shoulder_r, 3.8, shirt)
	draw_circle(left_knee, 3.2, pants)
	draw_circle(right_knee, 3.2, pants)

func _apply_walk_pose(frame: int, left_knee: Vector2, right_knee: Vector2, left_ankle: Vector2, right_ankle: Vector2, left_foot: Vector2, right_foot: Vector2, left_elbow: Vector2, right_elbow: Vector2, left_hand: Vector2, right_hand: Vector2) -> void:
	# 8 classic poses: Contact, Down, Passing, Up, then the mirrored four.
	# Stride stays compact so the legs never fly apart.
	match frame:
		0:
			left_knee.x = -9.0
			left_ankle.x = -12.0
			left_foot.x = -13.0
			right_knee.x = 6.0
			right_ankle.x = 4.0
			right_foot.x = 4.0
			left_elbow.x = -9.0
			left_hand.x = -7.0
			right_elbow.x = 15.0
			right_hand.x = 17.0
		1:
			left_knee.x = -8.0
			left_ankle.x = -10.0
			left_foot.x = -11.0
			right_knee.x = 5.0
			right_ankle.x = 1.0
			right_foot.x = 1.0
			left_elbow.x = -10.0
			left_hand.x = -9.0
			right_elbow.x = 16.0
			right_hand.x = 18.0
		2:
			left_knee.x = -4.0
			left_ankle.x = -3.0
			left_foot.x = -3.0
			right_knee.x = 5.0
			right_ankle.x = 6.0
			right_foot.x = 6.0
			left_elbow.x = -14.0
			left_hand.x = -14.0
			right_elbow.x = 13.0
			right_hand.x = 13.0
		3:
			left_knee.x = 1.0
			left_ankle.x = 5.0
			left_foot.x = 6.0
			right_knee.x = 4.0
			right_ankle.x = 2.0
			right_foot.x = 2.0
			left_elbow.x = -16.0
			left_hand.x = -18.0
			right_elbow.x = 10.0
			right_hand.x = 8.0
		4:
			left_knee.x = -6.0
			left_ankle.x = -4.0
			left_foot.x = -4.0
			right_knee.x = 9.0
			right_ankle.x = 12.0
			right_foot.x = 13.0
			left_elbow.x = -15.0
			left_hand.x = -17.0
			right_elbow.x = 9.0
			right_hand.x = 7.0
		5:
			left_knee.x = -5.0
			left_ankle.x = -1.0
			left_foot.x = -1.0
			right_knee.x = 8.0
			right_ankle.x = 10.0
			right_foot.x = 11.0
			left_elbow.x = -16.0
			left_hand.x = -18.0
			right_elbow.x = 10.0
			right_hand.x = 9.0
		6:
			left_knee.x = -5.0
			left_ankle.x = -6.0
			left_foot.x = -6.0
			right_knee.x = 4.0
			right_ankle.x = 3.0
			right_foot.x = 3.0
			left_elbow.x = -13.0
			left_hand.x = -13.0
			right_elbow.x = 14.0
			right_hand.x = 14.0
		7:
			left_knee.x = -4.0
			left_ankle.x = -2.0
			left_foot.x = -2.0
			right_knee.x = -1.0
			right_ankle.x = -5.0
			right_foot.x = -6.0
			left_elbow.x = -10.0
			left_hand.x = -8.0
			right_elbow.x = 16.0
			right_hand.x = 18.0

func _draw_limb(a: Vector2, b: Vector2, width: float, fill_color: Color, outline_color: Color) -> void:
	draw_line(a, b, outline_color, width + 3.0, true)
	draw_line(a, b, fill_color, width, true)
