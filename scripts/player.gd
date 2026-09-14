extends CharacterBody2D
## TRY HACKING ME NOW — animated Player controller
## 32-frame procedural animation system for smoother, more natural motion.

@export_category("Movement")
@export var move_speed: float = 260.0
@export var sprint_speed: float = 390.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_power: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

@export_category("Animation")
@export var animation_fps: float = 24.0
@export var animation_frames: int = 32

var facing_direction := 1.0
var is_sprinting := false
var is_crouching := false
var animation_time := 0.0
var animation_frame := 0
var animation_state := "idle"

func _ready() -> void:
	z_index = 100
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
	_update_animation(delta)
	queue_redraw()

func _update_animation(delta: float) -> void:
	var next_state := "idle"
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
	else:
		animation_time += delta
		if animation_time >= 1.0 / animation_fps:
			animation_time = 0.0
			animation_frame = (animation_frame + 1) % animation_frames

func _draw() -> void:
	var body := Color(0.96, 0.96, 0.96, 1.0)
	var outline := Color(0.04, 0.04, 0.04, 1.0)
	var accent := Color(0.91, 0.71, 0.29, 1.0)
	var f := animation_frame
	var phase := float(f) / float(animation_frames)
	var d := facing_direction

	# Smooth 32-frame procedural motion using continuous sine curves.
	var walk_phase := phase * TAU
	var stride := sin(walk_phase)
	var stride_opposite := sin(walk_phase + PI)
	var bob := sin(walk_phase * 2.0) * 1.4

	var head_y := -30.0 + bob
	var shoulder_y := -17.0 + bob
	var hip_y := 18.0
	var arm_a := Vector2(20.0 + stride * 5.0, 2.0 + stride_opposite * 3.0)
	var arm_b := Vector2(-17.0 + stride_opposite * 5.0, 5.0 + stride * 3.0)
	var leg_a := Vector2(12.0 + stride_opposite * 9.0, 40.0 + abs(stride) * 2.0)
	var leg_b := Vector2(-12.0 + stride * 9.0, 40.0 + abs(stride_opposite) * 2.0)

	match animation_state:
		"idle":
			var idle_bob := sin(phase * TAU) * 1.2
			head_y = -30.0 + idle_bob
			shoulder_y = -17.0 + idle_bob
			arm_a = Vector2(20.0, 2.0 + idle_bob)
			arm_b = Vector2(-17.0, 5.0 + idle_bob)
			leg_a = Vector2(12.0, 40.0)
			leg_b = Vector2(-12.0, 40.0)
		"walk":
			# Natural alternating limbs across all 32 frames.
			arm_a = Vector2(20.0 + stride * 9.0, 2.0 + stride_opposite * 5.0)
			arm_b = Vector2(-17.0 + stride_opposite * 9.0, 5.0 + stride * 5.0)
			leg_a = Vector2(12.0 + stride_opposite * 13.0, 40.0 - abs(stride) * 3.0)
			leg_b = Vector2(-12.0 + stride * 13.0, 40.0 - abs(stride_opposite) * 3.0)
		"run":
			# Larger, faster stride for sprinting.
			var run_phase := phase * TAU * 1.35
			var rs := sin(run_phase)
			var ro := sin(run_phase + PI)
			bob = sin(run_phase * 2.0) * 2.2
			head_y = -31.0 + bob
			shoulder_y = -18.0 + bob
			arm_a = Vector2(23.0 + rs * 12.0, -1.0 + ro * 8.0)
			arm_b = Vector2(-21.0 + ro * 12.0, 7.0 + rs * 8.0)
			leg_a = Vector2(13.0 + ro * 18.0, 42.0 - abs(rs) * 6.0)
			leg_b = Vector2(-13.0 + rs * 18.0, 42.0 - abs(ro) * 6.0)
		"jump":
			var jump_pose := sin(phase * TAU)
			head_y = -32.0 + jump_pose * 1.2
			arm_a = Vector2(18.0 + jump_pose * 4.0, -17.0 + jump_pose * 3.0)
			arm_b = Vector2(-18.0 - jump_pose * 4.0, -12.0 - jump_pose * 3.0)
			leg_a = Vector2(14.0 + jump_pose * 4.0, 30.0)
			leg_b = Vector2(-14.0 - jump_pose * 4.0, 30.0)
		"fall":
			var fall_pose := sin(phase * TAU)
			arm_a = Vector2(24.0 + fall_pose * 3.0, 8.0)
			arm_b = Vector2(-24.0 - fall_pose * 3.0, 8.0)
			leg_a = Vector2(18.0 + fall_pose * 4.0, 42.0)
			leg_b = Vector2(-18.0 - fall_pose * 4.0, 42.0)
		"crouch":
			var crouch_pose := sin(phase * TAU)
			head_y = -18.0 + crouch_pose * 0.8
			shoulder_y = -7.0 + crouch_pose * 0.8
			hip_y = 15.0
			arm_a = Vector2(21.0 + crouch_pose * 3.0, 12.0)
			arm_b = Vector2(-20.0 - crouch_pose * 3.0, 14.0)
			leg_a = Vector2(14.0 + crouch_pose * 5.0, 28.0)
			leg_b = Vector2(-14.0 - crouch_pose * 5.0, 27.0)

	arm_a.x *= d
	arm_b.x *= d
	leg_a.x *= d
	leg_b.x *= d

	# High-quality smooth stickman rendering.
	draw_circle(Vector2(0, head_y), 14.0, outline)
	draw_circle(Vector2(0, head_y), 10.5, body)
	draw_line(Vector2(0, shoulder_y), Vector2(0, hip_y), outline, 7.0, true)
	draw_line(Vector2(0, shoulder_y + 3.0), arm_a, outline, 6.0, true)
	draw_line(Vector2(0, shoulder_y + 3.0), arm_b, outline, 6.0, true)
	draw_line(Vector2(0, hip_y), leg_a, outline, 7.0, true)
	draw_line(Vector2(0, hip_y), leg_b, outline, 7.0, true)
	draw_circle(Vector2(4.0 * d, head_y - 1.0), 2.2, outline)

	if is_sprinting:
		draw_line(Vector2(-7, -43), Vector2(7, -43), accent, 3.0, true)
