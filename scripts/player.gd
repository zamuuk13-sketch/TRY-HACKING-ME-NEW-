extends CharacterBody2D
## TRY HACKING ME NOW — procedural 2D character.
## The player is drawn as a small cutout-style rig and the walk is built from
## explicit animation keyframes with interpolation between them.

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

# Explicit walk keyframes. Every entry is a complete pose for the right-facing
# character. The renderer mirrors the finished pose as one unit when facing left.
# 0 Contact, 1 Down, 2 Passing, 3 Up, 4 Contact opposite, 5 Down, 6 Passing, 7 Up.
var walk_knees_l: Array[Vector2] = [
	Vector2(-9.0, 31.0), Vector2(-8.0, 32.0), Vector2(-4.0, 30.0), Vector2(1.0, 29.0),
	Vector2(8.0, 31.0), Vector2(7.0, 32.0), Vector2(4.0, 30.0), Vector2(-1.0, 29.0)
]
var walk_knees_r: Array[Vector2] = [
	Vector2(7.0, 30.0), Vector2(6.0, 31.0), Vector2(5.0, 30.0), Vector2(4.0, 29.0),
	Vector2(-8.0, 31.0), Vector2(-7.0, 32.0), Vector2(-4.0, 30.0), Vector2(1.0, 29.0)
]
var walk_feet_l: Array[Vector2] = [
	Vector2(-13.0, 52.0), Vector2(-11.0, 52.0), Vector2(-3.0, 51.0), Vector2(5.0, 50.0),
	Vector2(4.0, 52.0), Vector2(2.0, 52.0), Vector2(-5.0, 51.0), Vector2(-8.0, 50.0)
]
var walk_feet_r: Array[Vector2] = [
	Vector2(4.0, 52.0), Vector2(1.0, 52.0), Vector2(6.0, 51.0), Vector2(7.0, 50.0),
	Vector2(13.0, 52.0), Vector2(11.0, 52.0), Vector2(3.0, 51.0), Vector2(-5.0, 50.0)
]
var walk_elbows_l: Array[Vector2] = [
	Vector2(-12.0, -1.0), Vector2(-13.0, 1.0), Vector2(-15.0, 0.0), Vector2(-16.0, -3.0),
	Vector2(-9.0, -2.0), Vector2(-10.0, 0.0), Vector2(-13.0, 0.0), Vector2(-15.0, -2.0)
]
var walk_elbows_r: Array[Vector2] = [
	Vector2(14.0, -2.0), Vector2(15.0, 0.0), Vector2(13.0, 0.0), Vector2(10.0, -2.0),
	Vector2(16.0, -3.0), Vector2(15.0, -1.0), Vector2(13.0, 0.0), Vector2(11.0, -2.0)
]
var walk_hands_l: Array[Vector2] = [
	Vector2(-14.0, 12.0), Vector2(-15.0, 14.0), Vector2(-15.0, 11.0), Vector2(-17.0, 7.0),
	Vector2(-7.0, 8.0), Vector2(-8.0, 10.0), Vector2(-12.0, 10.0), Vector2(-16.0, 8.0)
]
var walk_hands_r: Array[Vector2] = [
	Vector2(16.0, 9.0), Vector2(17.0, 11.0), Vector2(13.0, 11.0), Vector2(9.0, 7.0),
	Vector2(18.0, 8.0), Vector2(17.0, 10.0), Vector2(14.0, 11.0), Vector2(10.0, 8.0)
]

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
			while animation_time >= frame_duration:
				animation_time -= frame_duration
				animation_frame = (animation_frame + 1) % animation_frames

func _walk_pose_pair() -> Array[Vector2]:
	var next_frame: int = (animation_frame + 1) % animation_frames
	var duration: float = 1.0 / maxf(animation_fps, 1.0)
	var blend: float = clampf(animation_time / duration, 0.0, 1.0)
	# Smoothstep gives soft acceleration/deceleration between authored keys.
	blend = blend * blend * (3.0 - 2.0 * blend)
	return [Vector2(blend, 0.0), Vector2(float(next_frame), 0.0)]

func _lerp_pose(values: Array[Vector2], frame: int, blend: float) -> Vector2:
	var next_frame: int = (frame + 1) % animation_frames
	return values[frame].lerp(values[next_frame], blend)

func _draw() -> void:
	var skin: Color = Color(0.96, 0.96, 0.96, 1.0)
	var skin_shadow: Color = Color(0.70, 0.72, 0.76, 1.0)
	var outline: Color = Color(0.025, 0.028, 0.035, 1.0)
	var shirt: Color = Color(0.12, 0.15, 0.19, 1.0)
	var shirt_light: Color = Color(0.20, 0.24, 0.29, 1.0)
	var pants: Color = Color(0.065, 0.075, 0.095, 1.0)
	var shoe: Color = Color(0.02, 0.022, 0.028, 1.0)

	var d: float = facing_direction
	var body_y: float = 0.0
	var body_lean: float = 0.0
	var head_y: float = -31.0
	var shoulder_y: float = -14.0
	var hip_y: float = 16.0

	var knee_l: Vector2 = Vector2(-7.0, 31.0)
	var knee_r: Vector2 = Vector2(7.0, 31.0)
	var foot_l: Vector2 = Vector2(-7.0, 52.0)
	var foot_r: Vector2 = Vector2(7.0, 52.0)
	var elbow_l: Vector2 = Vector2(-13.0, -1.0)
	var elbow_r: Vector2 = Vector2(13.0, -1.0)
	var hand_l: Vector2 = Vector2(-14.0, 11.0)
	var hand_r: Vector2 = Vector2(14.0, 11.0)

	if animation_state == "walk":
		var frame_duration: float = 1.0 / maxf(animation_fps, 1.0)
		var blend: float = clampf(animation_time / frame_duration, 0.0, 1.0)
		blend = blend * blend * (3.0 - 2.0 * blend)
		knee_l = _lerp_pose(walk_knees_l, animation_frame, blend)
		knee_r = _lerp_pose(walk_knees_r, animation_frame, blend)
		foot_l = _lerp_pose(walk_feet_l, animation_frame, blend)
		foot_r = _lerp_pose(walk_feet_r, animation_frame, blend)
		elbow_l = _lerp_pose(walk_elbows_l, animation_frame, blend)
		elbow_r = _lerp_pose(walk_elbows_r, animation_frame, blend)
		hand_l = _lerp_pose(walk_hands_l, animation_frame, blend)
		hand_r = _lerp_pose(walk_hands_r, animation_frame, blend)
		var cycle_phase: float = (float(animation_frame) + blend) / 8.0
		body_y = sin(cycle_phase * TAU) * 1.35
		body_lean = 0.9 * d
	else:
		var breath: float = sin(idle_time * TAU * 0.85)
		body_y = breath * 0.45
		if animation_state == "run":
			body_y = -1.0
			body_lean = 2.0 * d
		elif animation_state == "crouch":
			body_y = 9.0
			head_y = -22.0
			shoulder_y = -7.0
			hip_y = 20.0
		elif animation_state == "jump":
			body_y = -2.0
			body_lean = 2.0 * d
		elif animation_state == "fall":
			body_y = 2.0
			body_lean = -1.5 * d

	# The entire rig is mirrored as a single coordinate system. This prevents
	# the old left-facing deformation where individual limbs were flipped twice.
	knee_l.x *= d
	knee_r.x *= d
	foot_l.x *= d
	foot_r.x *= d
	elbow_l.x *= d
	elbow_r.x *= d
	hand_l.x *= d
	hand_r.x *= d

	var torso_top: Vector2 = Vector2(body_lean, shoulder_y + body_y)
	var torso_bottom: Vector2 = Vector2(-body_lean * 0.35, hip_y + body_y)
	var head: Vector2 = Vector2(body_lean * 0.25, head_y + body_y)
	var neck: Vector2 = Vector2(body_lean * 0.05, -19.0 + body_y)
	var shoulder_l: Vector2 = torso_top + Vector2(-9.5 * d, 1.0)
	var shoulder_r: Vector2 = torso_top + Vector2(9.5 * d, 1.0)
	var hip_l: Vector2 = torso_bottom + Vector2(-6.5 * d, 0.0)
	var hip_r: Vector2 = torso_bottom + Vector2(6.5 * d, 0.0)

	# Hip-to-knee-to-foot chains read as actual articulated legs.
	_draw_limb(hip_l, knee_l + Vector2(0.0, body_y), 7.0, pants, outline)
	_draw_limb(knee_l + Vector2(0.0, body_y), foot_l + Vector2(0.0, body_y - 1.0), 6.0, pants, outline)
	_draw_limb(hip_r, knee_r + Vector2(0.0, body_y), 7.0, pants, outline)
	_draw_limb(knee_r + Vector2(0.0, body_y), foot_r + Vector2(0.0, body_y - 1.0), 6.0, pants, outline)

	# Counter-swinging arms with natural elbow arcs.
	_draw_limb(shoulder_l, elbow_l + Vector2(0.0, body_y), 6.0, shirt, outline)
	_draw_limb(elbow_l + Vector2(0.0, body_y), hand_l + Vector2(0.0, body_y), 4.8, skin, outline)
	_draw_limb(shoulder_r, elbow_r + Vector2(0.0, body_y), 6.0, shirt, outline)
	_draw_limb(elbow_r + Vector2(0.0, body_y), hand_r + Vector2(0.0, body_y), 4.8, skin, outline)

	# Feet: short shoes instead of a second long limb, keeping contact readable.
	_draw_foot(foot_l + Vector2(3.5 * d, body_y - 1.0), d, shoe, outline)
	_draw_foot(foot_r + Vector2(3.5 * d, body_y - 1.0), d, shoe, outline)

	_draw_limb(neck, head + Vector2(0.0, 8.0), 5.0, skin_shadow, outline)

	# Torso with a subtle highlight for depth.
	draw_line(torso_top, torso_bottom, outline, 19.0, true)
	draw_line(torso_top, torso_bottom, shirt, 14.0, true)
	draw_line(torso_top + Vector2(-3.0 * d, 2.0), torso_bottom + Vector2(-1.0 * d, -2.0), shirt_light, 3.0, true)

	# Head stays round and does not rotate with the walking cycle.
	draw_circle(head, 12.5, outline)
	draw_circle(head, 10.2, skin)
	var eye: Vector2 = head + Vector2(4.2 * d, -1.3)
	draw_circle(eye, 2.2, outline)
	draw_circle(eye + Vector2(0.55 * d, -0.5), 0.65, Color.WHITE)

	# Joints make the cutout character feel assembled rather than drawn as sticks.
	draw_circle(shoulder_l, 3.8, shirt)
	draw_circle(shoulder_r, 3.8, shirt)
	draw_circle(knee_l + Vector2(0.0, body_y), 3.1, pants)
	draw_circle(knee_r + Vector2(0.0, body_y), 3.1, pants)

func _draw_limb(a: Vector2, b: Vector2, width: float, fill_color: Color, outline_color: Color) -> void:
	draw_line(a, b, outline_color, width + 3.0, true)
	draw_line(a, b, fill_color, width, true)

func _draw_foot(position: Vector2, direction: float, fill_color: Color, outline_color: Color) -> void:
	var toe: Vector2 = position + Vector2(7.0 * direction, 0.0)
	draw_line(position, toe, outline_color, 7.0, true)
	draw_line(position, toe, fill_color, 4.0, true)
