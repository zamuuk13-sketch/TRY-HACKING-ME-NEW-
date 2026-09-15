extends CharacterBody2D
## TRY HACKING ME NOW — detailed procedural stickman controller.
## The character is drawn as one optimized CanvasItem: no PNG body parts,
## no per-limb physics, and no visual nodes following the Player.

@export_category("Movement")
@export var move_speed: float = 260.0
@export var sprint_speed: float = 390.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_power: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

@export_category("Animation")
@export var animation_speed: float = 9.0
@export var idle_breath_speed: float = 2.2
@export var show_motion_details: bool = true

var facing_direction := 1.0
var is_sprinting := false
var is_crouching := false
var animation_clock := 0.0
var step_clock := 0.0
var previous_velocity_x := 0.0
var landing_punch := 0.0
var jump_punch := 0.0

const OUTLINE := Color(0.055, 0.055, 0.065, 1.0)
const BODY := Color(0.94, 0.94, 0.92, 1.0)
const BODY_LIGHT := Color(1.0, 1.0, 0.98, 1.0)
const SHADOW := Color(0.04, 0.04, 0.045, 0.24)
const DETAIL := Color(0.18, 0.18, 0.19, 1.0)
const ACCENT := Color(0.91, 0.71, 0.29, 1.0)
const EYE := Color(0.025, 0.025, 0.03, 1.0)

func _ready() -> void:
	# The Player itself is the renderer now. Keep the collision body as the
	# single gameplay object and draw the complete character in _draw().
	z_index = 100
	queue_redraw()

func _physics_process(delta: float) -> void:
	animation_clock += delta

	var input_axis := Input.get_axis("move_left", "move_right")
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	is_sprinting = Input.is_key_pressed(KEY_SHIFT) and not is_crouching and abs(input_axis) > 0.0

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
			landing_punch = min(landing_punch + velocity.y / 900.0, 1.0)
			velocity.y = 0.0
		if Input.is_action_just_pressed("jump") and not is_crouching:
			velocity.y = -jump_power
			jump_punch = 1.0

	var horizontal_accel := abs(velocity.x - previous_velocity_x)
	if horizontal_accel > 500.0:
		jump_punch = max(jump_punch, 0.18)
	previous_velocity_x = velocity.x

	move_and_slide()

	landing_punch = move_toward(landing_punch, 0.0, delta * 5.5)
	jump_punch = move_toward(jump_punch, 0.0, delta * 6.0)

	if abs(velocity.x) > 20.0 and is_on_floor():
		step_clock += delta * (11.0 if is_sprinting else 7.5)
	else:
		step_clock = move_toward(step_clock, 0.0, delta * 8.0)

	queue_redraw()

func _draw() -> void:
	var d := facing_direction
	var moving := abs(velocity.x) > 15.0 and is_on_floor()
	var airborne := not is_on_floor()
	var speed_ratio := clamp(abs(velocity.x) / sprint_speed, 0.0, 1.0)

	# Animation curves. These are continuous rather than frame-stepped so the
	# character remains smooth even when the game runs above 60 FPS.
	var walk := sin(step_clock)
	var walk_opposite := sin(step_clock + PI)
	var idle := sin(animation_clock * idle_breath_speed)
	var run_bob := sin(step_clock * 2.0)

	var squash := 1.0
	var stretch := 1.0
	var body_y := 0.0

	if moving:
		body_y = abs(run_bob) * (-1.0 if is_sprinting else -0.55)
		squash = 1.0 + abs(run_bob) * 0.018
		stretch = 1.0 - abs(run_bob) * 0.014
	else:
		body_y = idle * 0.7
		squash = 1.0 + idle * 0.012
		stretch = 1.0 - idle * 0.009

	if airborne:
		body_y = -jump_punch * 2.0
		squash = 1.0 - jump_punch * 0.04
		stretch = 1.0 + jump_punch * 0.08

	if landing_punch > 0.0:
		squash += landing_punch * 0.075
		stretch -= landing_punch * 0.055

	# Ground shadow. It is deliberately simple and cheap.
	var shadow_width := 13.0 + speed_ratio * 7.0
	draw_ellipse(Vector2(0, 46), Vector2(shadow_width, 3.2), SHADOW)

	if is_crouching:
		_draw_crouched(d, animation_clock)
		return

	var hip := Vector2(0, 15 + body_y)
	var chest := Vector2(0, -15 + body_y)
	var neck := Vector2(0, -25 + body_y)
	var head := Vector2(0, -37 + body_y)

	# Legs are drawn behind the torso, with knees and shoes giving the old
	# stickman a much stronger silhouette.
	var leg_stride := 0.0
	if moving:
		leg_stride = (13.0 if is_sprinting else 8.0)

	var back_hip := hip + Vector2(-d * 4.5, 1)
	var front_hip := hip + Vector2(d * 4.5, 1)
	var back_knee := hip + Vector2(-d * (5.0 + walk_opposite * leg_stride), 19)
	var front_knee := hip + Vector2(d * (5.0 + walk * leg_stride), 19)
	var back_foot := hip + Vector2(-d * (7.0 + walk * leg_stride * 0.65), 38)
	var front_foot := hip + Vector2(d * (7.0 + walk_opposite * leg_stride * 0.65), 38)

	if airborne:
		back_knee = hip + Vector2(-d * 11, 13)
		front_knee = hip + Vector2(d * 11, 12)
		back_foot = hip + Vector2(-d * 14, 27)
		front_foot = hip + Vector2(d * 14, 28)

	_draw_limb(back_hip, back_knee, 5.8)
	_draw_limb(back_knee, back_foot, 5.2)
	_draw_shoe(back_foot, d, -0.05)
	_draw_joint(back_knee, 3.7)

	_draw_limb(front_hip, front_knee, 6.2)
	_draw_limb(front_knee, front_foot, 5.6)
	_draw_shoe(front_foot, d, 0.04)
	_draw_joint(front_knee, 4.0)

	# Torso: thick outlined silhouette, subtle inner shirt panel and waist.
	_draw_capsule(chest, hip, 12.0, OUTLINE)
	_draw_capsule(chest, hip, 8.6, BODY)
	_draw_torso_details(chest, hip, d)

	# Neck and collar.
	draw_line(Vector2(-5, -24 + body_y), Vector2(-4, -28 + body_y), OUTLINE, 5.0, true)
	draw_line(Vector2(5, -24 + body_y), Vector2(4, -28 + body_y), OUTLINE, 5.0, true)
	draw_line(Vector2(-5, -25 + body_y), Vector2(5, -25 + body_y), DETAIL, 2.0, true)

	# Arms. Shoulder -> elbow -> hand gives much more believable posing than
	# a single diagonal line.
	var arm_swing := 0.0
	if moving:
		arm_swing = walk * (18.0 if is_sprinting else 11.0)

	var front_shoulder := Vector2(d * 9.0, -17 + body_y)
	var back_shoulder := Vector2(-d * 9.0, -17 + body_y)
	var front_elbow := Vector2(d * (14.0 + arm_swing * 0.45), -3 + body_y)
	var back_elbow := Vector2(-d * (13.0 - arm_swing * 0.4), 1 + body_y)
	var front_hand := Vector2(d * (15.0 + arm_swing * 0.8), 10 + body_y)
	var back_hand := Vector2(-d * (15.0 - arm_swing * 0.7), 12 + body_y)

	if is_sprinting:
		front_elbow = Vector2(d * 18, -6 + body_y)
		front_hand = Vector2(d * 18, 8 + body_y)
		back_elbow = Vector2(-d * 16, 2 + body_y)
		back_hand = Vector2(-d * 17, 13 + body_y)

	if airborne:
		front_elbow = Vector2(d * 17, -12 + body_y)
		front_hand = Vector2(d * 19, -21 + body_y)
		back_elbow = Vector2(-d * 17, -11 + body_y)
		back_hand = Vector2(-d * 19, -20 + body_y)

	_draw_limb(back_shoulder, back_elbow, 5.5)
	_draw_limb(back_elbow, back_hand, 5.0)
	_draw_joint(back_elbow, 3.6)
	_draw_hand(back_hand, d * -1.0)

	_draw_limb(front_shoulder, front_elbow, 6.0)
	_draw_limb(front_elbow, front_hand, 5.4)
	_draw_joint(front_elbow, 3.9)
	_draw_hand(front_hand, d)

	# Head: outline, face, ears, tiny expression details and hair contour.
	_draw_head(head, d, stretch)

	# Speed lines are restrained and only appear at high speed.
	if show_motion_details and is_sprinting and abs(velocity.x) > sprint_speed * 0.72:
		var trail_x := -d * 17.0
		draw_line(Vector2(trail_x, -7), Vector2(trail_x - d * 10, -7), Color(0.15, 0.15, 0.16, 0.32), 2.0, true)
		draw_line(Vector2(trail_x, 2), Vector2(trail_x - d * 7, 2), Color(0.15, 0.15, 0.16, 0.22), 1.5, true)

func _draw_crouched(d: float, t: float) -> void:
	var breathe := sin(t * 2.0) * 0.5
	var hip := Vector2(0, 14)
	var chest := Vector2(0, -5 + breathe)
	var head := Vector2(0, -24 + breathe)

	# Folded legs.
	var knee_back := Vector2(-d * 13, 18)
	var knee_front := Vector2(d * 13, 17)
	var foot_back := Vector2(-d * 17, 29)
	var foot_front := Vector2(d * 17, 28)
	_draw_limb(hip + Vector2(-d * 4, 0), knee_back, 6.0)
	_draw_limb(knee_back, foot_back, 5.3)
	_draw_shoe(foot_back, -d, -0.08)
	_draw_limb(hip + Vector2(d * 4, 0), knee_front, 6.3)
	_draw_limb(knee_front, foot_front, 5.6)
	_draw_shoe(foot_front, d, 0.08)
	_draw_joint(knee_back, 3.5)
	_draw_joint(knee_front, 3.8)

	_draw_capsule(chest, hip, 12.0, OUTLINE)
	_draw_capsule(chest, hip, 8.6, BODY)
	_draw_torso_details(chest, hip, d)

	var shoulder := Vector2(d * 9, -7 + breathe)
	var elbow := Vector2(d * 14, 3)
	var hand := Vector2(d * 12, 10)
	_draw_limb(shoulder, elbow, 5.8)
	_draw_limb(elbow, hand, 5.2)
	_draw_joint(elbow, 3.6)
	_draw_hand(hand, d)
	_draw_limb(Vector2(-d * 9, -7 + breathe), Vector2(-d * 14, 3), 5.4)
	_draw_limb(Vector2(-d * 14, 3), Vector2(-d * 12, 10), 4.9)
	_draw_hand(Vector2(-d * 12, 10), -d)

	_draw_head(head, d, 1.0)

func _draw_head(center: Vector2, d: float, stretch: float) -> void:
	var head_scale := Vector2(1.0, stretch)
	# Outline and face.
	draw_set_transform(center, 0.0, head_scale)
	draw_circle(Vector2.ZERO, 14.0, OUTLINE)
	draw_circle(Vector2.ZERO, 11.0, BODY_LIGHT)
	# Ears.
	draw_circle(Vector2(-10, 1), 3.3, OUTLINE)
	draw_circle(Vector2(10, 1), 3.3, OUTLINE)
	draw_circle(Vector2(-10, 1), 1.7, BODY)
	draw_circle(Vector2(10, 1), 1.7, BODY)
	# Hair/top contour.
	draw_arc(Vector2(0, 0), 11.5, PI + 0.25, TAU - 0.25, 18, OUTLINE, 2.8, true)
	# Eyes follow facing direction; tiny brow makes the face expressive.
	var eye_x := 4.0 * d
	draw_circle(Vector2(eye_x, -1), 2.2, EYE)
	draw_circle(Vector2(eye_x + d * 0.65, -1.6), 0.65, BODY_LIGHT)
	draw_line(Vector2(eye_x - d * 2.4, -4.0), Vector2(eye_x + d * 1.5, -4.8), OUTLINE, 1.4, true)
	# Nose and mouth.
	draw_line(Vector2(d * 4.5, 1.5), Vector2(d * 6.0, 3.0), DETAIL, 1.2, true)
	draw_arc(Vector2(d * 2.5, 4), 3.0, 0.15, 1.0, 8, DETAIL, 1.2, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_torso_details(chest: Vector2, hip: Vector2, d: float) -> void:
	# Collar and center seam.
	draw_line(Vector2(-5, chest.y + 2), Vector2(0, chest.y + 7), DETAIL, 1.6, true)
	draw_line(Vector2(5, chest.y + 2), Vector2(0, chest.y + 7), DETAIL, 1.6, true)
	draw_line(Vector2(0, chest.y + 7), Vector2(0, hip.y - 2), Color(0.35, 0.35, 0.36, 0.5), 1.2, true)
	# Two small chest marks and belt.
	draw_line(Vector2(-6, -8), Vector2(-2, -8), DETAIL, 1.5, true)
	draw_line(Vector2(2, -8), Vector2(6, -8), DETAIL, 1.5, true)
	draw_line(Vector2(-8, 10), Vector2(8, 10), OUTLINE, 2.0, true)
	draw_circle(Vector2(d * 4, 10), 1.5, ACCENT)

func _draw_limb(a: Vector2, b: Vector2, width: float) -> void:
	draw_line(a, b, OUTLINE, width + 3.0, true)
	draw_line(a, b, BODY, width, true)
	# Narrow highlight gives the limb volume without turning it into a sprite.
	var mid := a.lerp(b, 0.5)
	var tangent := (b - a).normalized()
	var normal := Vector2(-tangent.y, tangent.x)
	draw_line(mid - normal * (width * 0.22), mid + normal * (width * 0.22), BODY_LIGHT, 1.1, true)

func _draw_joint(point: Vector2, radius: float) -> void:
	draw_circle(point, radius + 1.8, OUTLINE)
	draw_circle(point, radius, BODY_LIGHT)
	draw_circle(point + Vector2(-0.7, -0.8), radius * 0.35, Color(1, 1, 1, 0.7))

func _draw_hand(point: Vector2, direction: float) -> void:
	draw_circle(point, 4.0, OUTLINE)
	draw_circle(point, 2.9, BODY_LIGHT)
	for i in range(3):
		var y := -1.8 + float(i) * 1.7
		draw_line(point + Vector2(direction * 1.0, y), point + Vector2(direction * 4.0, y - 0.5), DETAIL, 0.8, true)

func _draw_shoe(point: Vector2, direction: float, tilt: float) -> void:
	var toe := point + Vector2(direction * 6.0, 1.0)
	draw_line(point + Vector2(-direction * 2.0, -2.0), toe, OUTLINE, 7.0, true)
	draw_line(point + Vector2(-direction * 2.0, -2.0), toe, DETAIL, 4.2, true)
	draw_line(point + Vector2(direction * 1.0, 0.5), toe + Vector2(0, -0.5), BODY_LIGHT, 1.1, true)

func _draw_capsule(a: Vector2, b: Vector2, radius: float, color: Color) -> void:
	draw_line(a, b, color, radius * 2.0, true)
	draw_circle(a, radius, color)
	draw_circle(b, radius, color)

func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
