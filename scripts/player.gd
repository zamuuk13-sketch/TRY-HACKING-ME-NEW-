extends CharacterBody2D
## TRY HACKING ME NOW — animated Player controller
## 12-frame procedural animation with compact, natural stickman poses.

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

	# 12-frame smooth cycle with restrained limb movement.
	var walk_phase := phase * TAU
	var stride := sin(walk_phase)
	var opposite := sin(walk_phase + PI)
	var bob := sin(walk_phase * 2.0) * 1.0

	var head_y := -30.0 + bob
	var shoulder_y := -17.0 + bob
	var hip_y := 17.0
	var arm_a := Vector2(12.0 + stride * 5.0, 5.0 + opposite * 2.0)
	var arm_b := Vector2(-12.0 + opposite * 5.0, 5.0 + stride * 2.0)
	var leg_a := Vector2(7.0 + opposite * 7.0, 40.0)
	var leg_b := Vector2(-7.0 + stride * 7.0, 40.0)

	match animation_state:
		"idle":
			var idle := sin(phase * TAU)
			head_y = -30.0 + idle * 0.7
			shoulder_y = -17.0 + idle * 0.7
			arm_a = Vector2(11.0, 5.0 + idle)
			arm_b = Vector2(-11.0, 5.0 - idle)
			leg_a = Vector2(6.0, 40.0)
			leg_b = Vector2(-6.0, 40.0)
		"walk":
			# Arms and legs stay close to the torso for a natural walk.
			arm_a = Vector2(12.0 + stride * 6.0, 5.0 + opposite * 2.0)
			arm_b = Vector2(-12.0 + opposite * 6.0, 5.0 + stride * 2.0)
			leg_a = Vector2(7.0 + opposite * 8.0, 40.0 - abs(stride) * 1.5)
			leg_b = Vector2(-7.0 + stride * 8.0, 40.0 - abs(opposite) * 1.5)
		"run":
			var run_phase := phase * TAU * 1.2
			var rs := sin(run_phase)
			var ro := sin(run_phase + PI)
			bob = sin(run_phase * 2.0) * 1.5
			head_y = -30.5 + bob
			shoulder_y = -17.5 + bob
			arm_a = Vector2(15.0 + rs * 8.0, 2.0 + ro * 4.0)
			arm_b = Vector2(-15.0 + ro * 8.0, 6.0 + rs * 4.0)
			leg_a = Vector2(8.0 + ro * 11.0, 40.0 - abs(rs) * 3.0)
			leg_b = Vector2(-8.0 + rs * 11.0, 40.0 - abs(ro) * 3.0)
		"jump":
			var jump_phase := sin(phase * TAU)
			head_y = -31.0 + jump_phase * 0.8
			arm_a = Vector2(11.0 + jump_phase * 3.0, -10.0)
			arm_b = Vector2(-11.0 - jump_phase * 3.0, -9.0)
			leg_a = Vector2(8.0, 30.0)
			leg_b = Vector2(-8.0, 30.0)
		"fall":
			arm_a = Vector2(14.0, 5.0)
			arm_b = Vector2(-14.0, 5.0)
			leg_a = Vector2(10.0, 40.0)
			leg_b = Vector2(-10.0, 40.0)
		"crouch":
			var crouch_phase := sin(phase * TAU)
			head_y = -19.0 + crouch_phase * 0.5
			shoulder_y = -8.0 + crouch_phase * 0.5
			hip_y = 14.0
			arm_a = Vector2(13.0, 9.0)
			arm_b = Vector2(-13.0, 10.0)
			leg_a = Vector2(10.0 + crouch_phase * 2.0, 28.0)
			leg_b = Vector2(-10.0 - crouch_phase * 2.0, 28.0)

	arm_a.x *= d
	arm_b.x *= d
	leg_a.x *= d
	leg_b.x *= d

	# Clean, compact silhouette — no exaggerated X-shaped limbs.
	draw_circle(Vector2(0, head_y), 14.0, outline)
	draw_circle(Vector2(0, head_y), 10.5, body)
	draw_line(Vector2(0, shoulder_y), Vector2(0, hip_y), outline, 7.0, true)
	draw_line(Vector2(0, shoulder_y + 2.0), arm_a, outline, 5.5, true)
	draw_line(Vector2(0, shoulder_y + 2.0), arm_b, outline, 5.5, true)
	draw_line(Vector2(0, hip_y), leg_a, outline, 6.0, true)
	draw_line(Vector2(0, hip_y), leg_b, outline, 6.0, true)
	draw_circle(Vector2(4.0 * d, head_y - 1.0), 2.0, outline)

	if is_sprinting:
		draw_line(Vector2(-6, -43), Vector2(6, -43), accent, 3.0, true)
