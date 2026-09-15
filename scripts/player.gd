extends CharacterBody2D
## TRY HACKING ME NOW — detailed procedural Player controller.
## Movement/physics stay intentionally unchanged; the character is rendered entirely with _draw().

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
	# Keep the procedural renderer impossible to hide accidentally.
	visible = true
	modulate = Color.WHITE
	self_modulate = Color.WHITE
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

func _limb(a: Vector2, b: Vector2, width: float, outer: Color, inner: Color) -> void:
	draw_line(a, b, outer, width + 3.0, true)
	draw_line(a, b, inner, width, true)

func _joint(p: Vector2, radius: float, outer: Color, inner: Color) -> void:
	draw_circle(p, radius + 2.0, outer)
	draw_circle(p, radius, inner)

func _foot(p: Vector2, direction: float, outer: Color, inner: Color) -> void:
	var heel := p
	var toe := p + Vector2(9.0 * direction, -1.0)
	draw_line(heel, toe, outer, 8.0, true)
	draw_line(heel, toe, inner, 4.8, true)
	draw_circle(toe, 2.4, inner)

func _draw() -> void:
	# Strong, readable cartoon palette.
	var skin := Color(0.97, 0.97, 0.97, 1.0)
	var skin_shadow := Color(0.76, 0.78, 0.81, 1.0)
	var outline := Color(0.025, 0.025, 0.03, 1.0)
	var shirt := Color(0.13, 0.15, 0.18, 1.0)
	var shirt_light := Color(0.23, 0.26, 0.31, 1.0)
	var pants := Color(0.08, 0.09, 0.11, 1.0)
	var shoe := Color(0.035, 0.035, 0.045, 1.0)
	var eye := Color(0.03, 0.03, 0.035, 1.0)
	var accent := Color(0.91, 0.71, 0.29, 1.0)

	var d := facing_direction
	var cycle := (float(animation_frame) + animation_time * animation_fps) / float(max(animation_frames, 1))
	var phase := cycle * TAU
	var stride := sin(phase)
	var opposite := -stride
	var speed_ratio := clamp(abs(velocity.x) / max(sprint_speed, 1.0), 0.0, 1.0)

	var head := Vector2(0.0, -31.0)
	var neck := Vector2(0.0, -18.5)
	var shoulder_l := Vector2(-10.0, -15.5)
	var shoulder_r := Vector2(10.0, -15.5)
	var hip_l := Vector2(-6.5, 17.0)
	var hip_r := Vector2(6.5, 17.0)
	var elbow_l := Vector2(-14.0, 1.0)
	var elbow_r := Vector2(14.0, 1.0)
	var hand_l := Vector2(-14.0, 12.0)
	var hand_r := Vector2(14.0, 12.0)
	var knee_l := Vector2(-7.0, 31.0)
	var knee_r := Vector2(7.0, 31.0)
	var ankle_l := Vector2(-7.0, 49.0)
	var ankle_r := Vector2(7.0, 49.0)
	var torso_lean := 0.0

	# Idle: breathing, weight shift, tiny head movement.
	var breath := sin(phase) * 0.8
	if animation_state == "idle":
		head.y = -31.0 + breath
		neck.y = -18.5 + breath * 0.6
		shoulder_l.y = -15.5 + breath * 0.6
		shoulder_r.y = -15.5 + breath * 0.6
		elbow_l = Vector2(-13.0, 0.0 + breath)
		elbow_r = Vector2(13.0, 1.5 - breath)
		hand_l = Vector2(-12.0, 11.0 + breath)
		hand_r = Vector2(12.0, 12.0 - breath)
		torso_lean = sin(phase * 0.5) * 0.7
	elif animation_state == "walk":
		var walk := phase
		var s := sin(walk)
		var c := cos(walk)
		var walk_bob := abs(s) * 1.1
		head.y = -31.0 + walk_bob
		neck.y = -18.0 + walk_bob
		shoulder_l.y = -15.0 + walk_bob
		shoulder_r.y = -15.0 + walk_bob
		elbow_l = Vector2(-12.0 + s * 6.0, 0.0 + c * 3.0)
		elbow_r = Vector2(12.0 - s * 6.0, 0.0 - c * 3.0)
		hand_l = Vector2(-13.0 + s * 7.0, 11.0 + c * 2.0)
		hand_r = Vector2(13.0 - s * 7.0, 11.0 - c * 2.0)
		knee_l = Vector2(-7.0 - s * 8.0, 31.0 - max(s, 0.0) * 2.0)
		knee_r = Vector2(7.0 + s * 8.0, 31.0 - max(-s, 0.0) * 2.0)
		ankle_l = Vector2(-7.0 - s * 7.0, 49.0 - max(s, 0.0) * 3.0)
		ankle_r = Vector2(7.0 + s * 7.0, 49.0 - max(-s, 0.0) * 3.0)
		torso_lean = -s * 1.2
	elif animation_state == "run":
		var run_phase := phase * 1.45
		var s := sin(run_phase)
		var c := cos(run_phase)
		var run_bob := abs(s) * 2.0
		head.y = -31.5 + run_bob
		neck.y = -18.5 + run_bob
		shoulder_l.y = -15.5 + run_bob
		shoulder_r.y = -15.5 + run_bob
		elbow_l = Vector2(-13.0 + s * 10.0, -1.0 + c * 6.0)
		elbow_r = Vector2(13.0 - s * 10.0, 1.0 - c * 6.0)
		hand_l = Vector2(-15.0 + s * 13.0, 10.0 + c * 7.0)
		hand_r = Vector2(15.0 - s * 13.0, 10.0 - c * 7.0)
		knee_l = Vector2(-7.0 - s * 12.0, 29.0 - max(s, 0.0) * 6.0)
		knee_r = Vector2(7.0 + s * 12.0, 29.0 - max(-s, 0.0) * 6.0)
		ankle_l = Vector2(-8.0 - s * 13.0, 48.0 - max(s, 0.0) * 7.0)
		ankle_r = Vector2(8.0 + s * 13.0, 48.0 - max(-s, 0.0) * 7.0)
		torso_lean = -4.0 - s * 1.5
	elif animation_state == "jump":
		var jump_float := sin(phase * 0.5)
		head.y = -32.0 + jump_float * 0.5
		shoulder_l = Vector2(-10.0, -16.0)
		shoulder_r = Vector2(10.0, -16.0)
		elbow_l = Vector2(-16.0, -6.0)
		elbow_r = Vector2(16.0, -6.0)
		hand_l = Vector2(-19.0, -14.0)
		hand_r = Vector2(19.0, -14.0)
		knee_l = Vector2(-12.0, 27.0)
		knee_r = Vector2(12.0, 27.0)
		ankle_l = Vector2(-17.0, 40.0)
		ankle_r = Vector2(17.0, 40.0)
		torso_lean = -1.5
	elif animation_state == "fall":
		head.y = -30.0
		elbow_l = Vector2(-17.0, 2.0)
		elbow_r = Vector2(17.0, 2.0)
		hand_l = Vector2(-22.0, 9.0)
		hand_r = Vector2(22.0, 9.0)
		knee_l = Vector2(-11.0, 32.0)
		knee_r = Vector2(11.0, 32.0)
		ankle_l = Vector2(-13.0, 47.0)
		ankle_r = Vector2(13.0, 47.0)
		torso_lean = 2.0
	elif animation_state == "crouch":
		var crouch_breath := sin(phase) * 0.4
		head = Vector2(1.5 * d, -20.0 + crouch_breath)
		neck = Vector2(0.5 * d, -10.0)
		shoulder_l = Vector2(-10.0, -8.0)
		shoulder_r = Vector2(10.0, -8.0)
		hip_l = Vector2(-7.0, 13.0)
		hip_r = Vector2(7.0, 13.0)
		elbow_l = Vector2(-15.0, 3.0)
		elbow_r = Vector2(15.0, 3.0)
		hand_l = Vector2(-16.0, 13.0)
		hand_r = Vector2(16.0, 13.0)
		knee_l = Vector2(-14.0, 24.0)
		knee_r = Vector2(14.0, 24.0)
		ankle_l = Vector2(-10.0, 43.0)
		ankle_r = Vector2(10.0, 43.0)
		torso_lean = 3.0

	# Mirror the entire pose according to movement direction.
	if d < 0.0:
		head.x *= -1.0
		neck.x *= -1.0
		shoulder_l.x *= -1.0
		shoulder_r.x *= -1.0
		elbow_l.x *= -1.0
		elbow_r.x *= -1.0
		hand_l.x *= -1.0
		hand_r.x *= -1.0
		hip_l.x *= -1.0
		hip_r.x *= -1.0
		knee_l.x *= -1.0
		knee_r.x *= -1.0
		ankle_l.x *= -1.0
		ankle_r.x *= -1.0

	var torso_top := Vector2(torso_lean, -14.0)
	var torso_bottom := Vector2(torso_lean * 0.45, 16.0)

	# Legs: thick outlined segments, knees, ankles and shoes.
	_limb(hip_l, knee_l, 7.0, outline, pants)
	_limb(knee_l, ankle_l, 6.0, outline, pants)
	_limb(hip_r, knee_r, 7.0, outline, pants)
	_limb(knee_r, ankle_r, 6.0, outline, pants)
	_joint(knee_l, 4.2, outline, pants)
	_joint(knee_r, 4.2, outline, pants)
	_foot(ankle_l, d, outline, shoe)
	_foot(ankle_r, d, outline, shoe)

	# Torso silhouette and clothing detail.
	_limb(torso_top, torso_bottom, 15.0, outline, shirt)
	_limb(Vector2(torso_lean - 4.0, -11.0), Vector2(torso_lean - 1.0, 10.0), 3.0, shirt_light, shirt_light)
	draw_line(Vector2(torso_lean - 5.0, 8.0), Vector2(torso_lean + 5.0, 8.0), shirt_light, 2.0, true)
	_joint(hip_l, 3.0, outline, pants)
	_joint(hip_r, 3.0, outline, pants)

	# Arms: shoulders, upper arms, forearms and hands.
	_limb(shoulder_l, elbow_l, 6.0, outline, shirt)
	_limb(elbow_l, hand_l, 5.0, outline, skin)
	_limb(shoulder_r, elbow_r, 6.0, outline, shirt)
	_limb(elbow_r, hand_r, 5.0, outline, skin)
	_joint(shoulder_l, 4.0, outline, shirt_light)
	_joint(shoulder_r, 4.0, outline, shirt_light)
	_joint(elbow_l, 3.2, outline, skin_shadow)
	_joint(elbow_r, 3.2, outline, skin_shadow)
	_joint(hand_l, 3.8, outline, skin)
	_joint(hand_r, 3.8, outline, skin)

	# Neck and head.
	_limb(neck, Vector2(neck.x, -24.0), 6.0, outline, skin)
	draw_circle(head, 16.0, outline)
	draw_circle(head + Vector2(0.0, 0.8), 13.0, skin)
	# Face shading gives the head more volume without external sprites.
	draw_circle(head + Vector2(-4.5 * d, 4.0), 4.0, skin_shadow)
	draw_circle(head + Vector2(5.0 * d, -2.5), 2.3, Color(1.0, 1.0, 1.0, 0.9))

	# Face: eye, brow and tiny mouth, always readable at game scale.
	var eye_pos := head + Vector2(5.0 * d, -2.0)
	draw_line(eye_pos + Vector2(-2.8 * d, -2.0), eye_pos + Vector2(2.5 * d, -2.0), outline, 1.8, true)
	draw_circle(eye_pos, 2.0, eye)
	draw_circle(eye_pos + Vector2(0.6 * d, -0.5), 0.55, Color.WHITE)
	if animation_state == "crouch":
		draw_line(head + Vector2(3.0 * d, 5.0), head + Vector2(7.0 * d, 5.0), outline, 1.6, true)
	else:
		draw_arc(head + Vector2(4.0 * d, 4.0), 4.0, 0.2, 1.8, 8, outline, 1.4, true)

	# Small motion/accent mark while sprinting.
	if is_sprinting and abs(velocity.x) > 80.0:
		draw_line(Vector2(-8.0 * d, -45.0), Vector2(7.0 * d, -45.0), accent, 2.5, true)
		draw_line(Vector2(-5.0 * d, -41.0), Vector2(4.0 * d, -41.0), accent, 1.5, true)
