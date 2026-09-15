extends CharacterBody2D
## TRY HACKING ME NOW — detailed procedural Player controller.
## Movement/physics stay intentionally unchanged; the character is rendered entirely with _draw().
## Animation uses classic 2D locomotion principles: contact, down, passing, up,
## clear weight shifts, opposite arm/leg motion, anticipation and readable silhouettes.

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
var landing_punch := 0.0

func _ready() -> void:
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

	var was_on_floor := is_on_floor()
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
		if animation_time >= 1.0 / maxf(animation_fps, 1.0):
			animation_time -= 1.0 / maxf(animation_fps, 1.0)
			animation_frame = (animation_frame + 1) % max(animation_frames, 1)

func _limb(a: Vector2, b: Vector2, width: float, outer: Color, inner: Color) -> void:
	draw_line(a, b, outer, width + 3.0, true)
	draw_line(a, b, inner, width, true)

func _joint(p: Vector2, radius: float, outer: Color, inner: Color) -> void:
	draw_circle(p, radius + 2.0, outer)
	draw_circle(p, radius, inner)

func _foot(p: Vector2, direction: float, outer: Color, inner: Color, size: float = 1.0) -> void:
	var heel := p + Vector2(-3.0 * direction, 0.0)
	var toe := p + Vector2(11.0 * direction * size, -1.5 * size)
	draw_line(heel, toe, outer, 9.0 * size, true)
	draw_line(heel, toe, inner, 5.4 * size, true)
	draw_circle(toe, 2.5 * size, inner)

func _draw() -> void:
	var skin := Color(0.97, 0.97, 0.97, 1.0)
	var skin_shadow := Color(0.72, 0.74, 0.78, 1.0)
	var outline := Color(0.02, 0.02, 0.025, 1.0)
	var shirt := Color(0.13, 0.15, 0.18, 1.0)
	var shirt_light := Color(0.27, 0.30, 0.35, 1.0)
	var pants := Color(0.075, 0.085, 0.105, 1.0)
	var pants_light := Color(0.15, 0.16, 0.19, 1.0)
	var shoe := Color(0.035, 0.035, 0.045, 1.0)
	var eye := Color(0.025, 0.025, 0.03, 1.0)
	var accent := Color(0.91, 0.71, 0.29, 1.0)

	var d := facing_direction
	var speed_ratio: float = clampf(abs(velocity.x) / maxf(sprint_speed, 1.0), 0.0, 1.0)
	var t := animation_time
	var cycle := (float(animation_frame) + t * animation_fps) / float(max(animation_frames, 1))
	var phase := cycle * TAU

	var head := Vector2(0.0, -31.0)
	var neck := Vector2(0.0, -18.5)
	var shoulder_l := Vector2(-10.0, -15.0)
	var shoulder_r := Vector2(10.0, -15.0)
	var hip_l := Vector2(-6.5, 16.0)
	var hip_r := Vector2(6.5, 16.0)
	var elbow_l := Vector2(-13.0, -1.0)
	var elbow_r := Vector2(13.0, -1.0)
	var hand_l := Vector2(-13.0, 11.0)
	var hand_r := Vector2(13.0, 11.0)
	var knee_l := Vector2(-7.0, 31.0)
	var knee_r := Vector2(7.0, 31.0)
	var ankle_l := Vector2(-7.0, 49.0)
	var ankle_r := Vector2(7.0, 49.0)
	var torso_lean := 0.0
	var body_y := 0.0

	if animation_state == "idle":
		var breath := sin(t * TAU * 0.85)
		var sway := sin(t * TAU * 0.42)
		body_y = breath * 0.55
		head = Vector2(sway * 0.7, -31.0 + body_y)
		neck = Vector2(sway * 0.35, -18.4 + body_y * 0.6)
		shoulder_l = Vector2(-10.0 + sway * 0.4, -15.2 + body_y)
		shoulder_r = Vector2(10.0 + sway * 0.4, -15.2 + body_y)
		elbow_l = Vector2(-13.0 - sway * 0.7, 0.5 + breath * 0.8)
		elbow_r = Vector2(13.0 - sway * 0.5, 1.0 - breath * 0.6)
		hand_l = Vector2(-12.0 - sway, 11.0 + breath * 0.5)
		hand_r = Vector2(12.0 - sway * 0.7, 11.5 - breath * 0.4)

	elif animation_state == "walk":
		var w := phase
		var s := sin(w)
		var c := cos(w)
		var stride := 8.5
		var lift := maxf(0.0, c)
		var down := maxf(0.0, -c)
		body_y = down * 1.35 - lift * 0.35
		head = Vector2(-s * 0.9, -31.0 + body_y)
		neck = Vector2(-s * 0.45, -18.4 + body_y)
		shoulder_l = Vector2(-10.0 - s * 0.45, -15.0 + body_y)
		shoulder_r = Vector2(10.0 - s * 0.45, -15.0 + body_y)
		elbow_l = Vector2(-13.0 - s * 6.0, -0.5 + c * 1.8)
		elbow_r = Vector2(13.0 + s * 6.0, -0.5 - c * 1.8)
		hand_l = Vector2(-13.0 - s * 7.0, 10.5 + c * 1.5)
		hand_r = Vector2(13.0 + s * 7.0, 10.5 - c * 1.5)
		knee_l = Vector2(-7.0 - s * stride, 30.5 - lift * 2.0)
		knee_r = Vector2(7.0 + s * stride, 30.5 - lift * 2.0)
		ankle_l = Vector2(-7.0 - s * stride * 1.28, 49.0 - lift * 2.2)
		ankle_r = Vector2(7.0 + s * stride * 1.28, 49.0 - lift * 2.2)
		torso_lean = -s * 0.9

	elif animation_state == "run":
		var r := phase * 1.18
		var s := sin(r)
		var c := cos(r)
		var flight := maxf(0.0, -c)
		var compression := maxf(0.0, c)
		body_y = compression * 1.2 - flight * 1.7
		head = Vector2(-s * 0.65, -31.7 + body_y)
		neck = Vector2(-s * 0.3, -18.6 + body_y)
		shoulder_l = Vector2(-10.0, -15.4 + body_y)
		shoulder_r = Vector2(10.0, -15.4 + body_y)
		elbow_l = Vector2(-13.0 - s * 9.5, -1.5 + c * 4.0)
		elbow_r = Vector2(13.0 + s * 9.5, -1.5 - c * 4.0)
		hand_l = Vector2(-14.0 - s * 13.0, 8.0 + c * 6.5)
		hand_r = Vector2(14.0 + s * 13.0, 8.0 - c * 6.5)
		knee_l = Vector2(-7.0 - s * 13.0, 28.0 - maxf(s, 0.0) * 8.0 + flight * 4.0)
		knee_r = Vector2(7.0 + s * 13.0, 28.0 - maxf(-s, 0.0) * 8.0 + flight * 4.0)
		ankle_l = Vector2(-8.0 - s * 15.0, 48.5 - maxf(s, 0.0) * 7.0 + flight * 4.5)
		ankle_r = Vector2(8.0 + s * 15.0, 48.5 - maxf(-s, 0.0) * 7.0 + flight * 4.5)
		torso_lean = -5.0 - speed_ratio * 2.0

	elif animation_state == "jump":
		var j: float = clampf(-velocity.y / maxf(jump_power, 1.0), 0.0, 1.0)
		head = Vector2(0.0, -32.0 - j * 0.6)
		neck = Vector2(0.0, -19.0)
		shoulder_l = Vector2(-10.5, -16.0)
		shoulder_r = Vector2(10.5, -16.0)
		elbow_l = Vector2(-15.0 - j * 3.0, -5.0 - j * 2.0)
		elbow_r = Vector2(15.0 + j * 3.0, -5.0 - j * 2.0)
		hand_l = Vector2(-19.0 - j * 3.0, -12.0 - j * 3.0)
		hand_r = Vector2(19.0 + j * 3.0, -12.0 - j * 3.0)
		knee_l = Vector2(-11.0 - j * 2.0, 27.0 - j * 2.0)
		knee_r = Vector2(11.0 + j * 2.0, 27.0 - j * 2.0)
		ankle_l = Vector2(-16.0 - j * 6.0, 41.0 - j * 2.0)
		ankle_r = Vector2(16.0 + j * 6.0, 41.0 - j * 2.0)
		torso_lean = -1.5

	elif animation_state == "fall":
		var fall_ratio: float = clampf(velocity.y / maxf(max_fall_speed, 1.0), 0.0, 1.0)
		head = Vector2(0.5 * d, -30.5 + fall_ratio * 0.5)
		neck = Vector2(0.0, -18.2)
		elbow_l = Vector2(-16.0 - fall_ratio * 3.0, 2.0 + fall_ratio * 3.0)
		elbow_r = Vector2(16.0 + fall_ratio * 3.0, 2.0 + fall_ratio * 3.0)
		hand_l = Vector2(-21.0 - fall_ratio * 4.0, 10.0 + fall_ratio * 3.0)
		hand_r = Vector2(21.0 + fall_ratio * 4.0, 10.0 + fall_ratio * 3.0)
		knee_l = Vector2(-10.0, 31.0 + fall_ratio)
		knee_r = Vector2(10.0, 31.0 + fall_ratio)
		ankle_l = Vector2(-14.0 - fall_ratio * 3.0, 48.0)
		ankle_r = Vector2(14.0 + fall_ratio * 3.0, 48.0)
		torso_lean = 1.5 + fall_ratio * 2.0

	elif animation_state == "crouch":
		var q := sin(t * TAU * 0.75)
		head = Vector2(1.0 * d, -21.0 + q * 0.35)
		neck = Vector2(0.5 * d, -10.5)
		shoulder_l = Vector2(-10.0, -8.0)
		shoulder_r = Vector2(10.0, -8.0)
		elbow_l = Vector2(-15.0, 2.0 + q * 0.4)
		elbow_r = Vector2(15.0, 2.0 - q * 0.4)
		hand_l = Vector2(-16.0, 12.5 + q * 0.4)
		hand_r = Vector2(16.0, 12.5 - q * 0.4)
		hip_l = Vector2(-7.0, 12.0)
		hip_r = Vector2(7.0, 12.0)
		knee_l = Vector2(-14.0, 24.0)
		knee_r = Vector2(14.0, 24.0)
		ankle_l = Vector2(-10.0, 43.5)
		ankle_r = Vector2(10.0, 43.5)
		torso_lean = 3.5

	var squash := landing_punch
	body_y += squash * 1.2
	head.y += squash * 2.0
	torso_lean += squash * 0.8

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
		torso_lean *= -1.0

	head.y += body_y
	neck.y += body_y
	shoulder_l.y += body_y
	shoulder_r.y += body_y
	hip_l.y += body_y
	hip_r.y += body_y
	elbow_l.y += body_y
	elbow_r.y += body_y
	hand_l.y += body_y
	hand_r.y += body_y
	knee_l.y += body_y
	knee_r.y += body_y
	ankle_l.y += body_y
	ankle_r.y += body_y

	var torso_top := Vector2(torso_lean, -14.0)
	var torso_bottom := Vector2(torso_lean * 0.42, 15.0)
	var torso_width := 15.5 if animation_state != "crouch" else 16.5

	_limb(hip_l, knee_l, 7.0, outline, pants)
	_limb(knee_l, ankle_l, 6.0, outline, pants)
	_joint(knee_l, 4.2, outline, pants)
	_foot(ankle_l, d, outline, shoe)
	_limb(shoulder_l, elbow_l, 5.8, outline, shirt)
	_limb(elbow_l, hand_l, 4.8, outline, skin)
	_joint(elbow_l, 3.0, outline, shirt)
	_joint(hand_l, 3.3, outline, skin)
	_limb(torso_top, torso_bottom, torso_width, outline, shirt)
	_limb(Vector2(torso_lean - 4.0, -10.5), Vector2(torso_lean - 1.5, 9.0), 3.0, shirt_light, shirt_light)
	draw_line(Vector2(torso_lean - 5.0, 7.0), Vector2(torso_lean + 5.0, 7.0), shirt_light, 2.0, true)
	draw_circle(Vector2(torso_lean + 4.0 * d, -4.0), 1.8, accent)
	_limb(hip_r, knee_r, 7.0, outline, pants)
	_limb(knee_r, ankle_r, 6.0, outline, pants)
	_joint(knee_r, 4.2, outline, pants)
	_foot(ankle_r, d, outline, shoe)
	_limb(shoulder_r, elbow_r, 5.8, outline, shirt)
	_limb(elbow_r, hand_r, 4.8, outline, skin)
	_joint(elbow_r, 3.0, outline, shirt)
	_joint(hand_r, 3.3, outline, skin)
	_limb(neck, head + Vector2(0.0, 7.0), 5.0, outline, skin_shadow)
	draw_circle(head, 12.0, outline)
	draw_circle(head + Vector2(0.0, 0.5), 9.7, skin)
	draw_arc(head + Vector2(-0.5, 0.5), 8.7, 0.25, 2.5, 14, skin_shadow, 1.7, true)
	var face_x := 4.0 * d
	var eye_y := head.y - 1.0
	draw_circle(Vector2(head.x + face_x, eye_y), 2.0, eye)
	draw_line(Vector2(head.x + face_x - 1.8 * d, eye_y - 3.0), Vector2(head.x + face_x + 1.5 * d, eye_y - 3.4), outline, 1.5, true)
	if animation_state == "run":
		draw_line(Vector2(head.x + face_x - 1.0 * d, eye_y + 4.0), Vector2(head.x + face_x + 3.0 * d, eye_y + 3.0), outline, 1.3, true)
	elif animation_state == "crouch":
		draw_line(Vector2(head.x + face_x - 1.0 * d, eye_y + 3.5), Vector2(head.x + face_x + 1.5 * d, eye_y + 3.5), outline, 1.2, true)
	draw_arc(head + Vector2(0.0, -1.5), 10.0, PI + 0.2, TAU - 0.2, 16, outline, 2.0, true)
	if animation_state == "run" and speed_ratio > 0.75:
		var trail_x := head.x - d * 15.0
		draw_line(Vector2(trail_x, head.y - 4.0), Vector2(trail_x - d * 7.0, head.y - 5.0), accent, 1.5, true)
		draw_line(Vector2(trail_x, head.y + 1.0), Vector2(trail_x - d * 5.0, head.y + 1.0), accent, 1.2, true)
	var shadow_scale := 1.0 + landing_punch * 0.35
	var shadow_width := 22.0 * shadow_scale
	var shadow_points := PackedVector2Array()
	for i in range(20):
		var a := TAU * float(i) / 20.0
		shadow_points.append(Vector2(cos(a) * shadow_width, 54.0 + sin(a) * 4.0))
	draw_colored_polygon(shadow_points, Color(0.0, 0.0, 0.0, 0.20))
