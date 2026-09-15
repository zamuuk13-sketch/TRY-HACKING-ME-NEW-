extends CharacterBody2D
## TRY HACKING ME NOW — lightweight 2D cutout character with authored keyframe walk.
## Movement/physics stay on CharacterBody2D. Visual animation is a real
## transform hierarchy driven by AnimationPlayer keyframes.

@export_category("Movement")
@export var move_speed: float = 260.0
@export var sprint_speed: float = 390.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_power: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

@export_category("Animation")
@export var walk_cycle_fps: float = 12.0

var facing_direction: float = 1.0
var is_sprinting: bool = false
var is_crouching: bool = false
var animation_state: String = "idle"
var landing_punch: float = 0.0

var rig: Node2D
var animation_player: AnimationPlayer
var visual_root: Node2D
var head: Node2D
var torso: Line2D
var torso_highlight: Line2D
var left_upper_arm: Node2D
var left_forearm: Node2D
var right_upper_arm: Node2D
var right_forearm: Node2D
var left_thigh: Node2D
var left_shin: Node2D
var right_thigh: Node2D
var right_shin: Node2D

const OUTLINE := Color(0.025, 0.028, 0.035, 1.0)
const SHIRT := Color(0.12, 0.15, 0.19, 1.0)
const SHIRT_LIGHT := Color(0.20, 0.24, 0.29, 1.0)
const PANTS := Color(0.065, 0.075, 0.095, 1.0)
const SKIN := Color(0.96, 0.96, 0.96, 1.0)
const SKIN_SHADOW := Color(0.70, 0.72, 0.76, 1.0)
const SHOE := Color(0.02, 0.022, 0.028, 1.0)

func _ready() -> void:
	visible = true
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	z_index = 100
	_build_rig()
	_build_animations()
	_play_state("idle")

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
	_update_animation_state()
	_update_facing()

func _update_animation_state() -> void:
	var next_state: String = "idle"
	if not is_on_floor():
		next_state = "jump" if velocity.y < 0.0 else "fall"
	elif is_crouching:
		next_state = "crouch"
	elif abs(velocity.x) > 15.0:
		next_state = "run" if is_sprinting else "walk"

	if next_state != animation_state:
		_play_state(next_state)

func _update_facing() -> void:
	if visual_root == null:
		return
	visual_root.scale.x = abs(visual_root.scale.x) * facing_direction

func _play_state(state: String) -> void:
	animation_state = state
	if animation_player == null:
		return
	var clip: String = state
	if not animation_player.has_animation(clip):
		clip = "idle"
	animation_player.play(clip, 0.10)
	animation_player.speed_scale = 1.0
	if state == "run":
		animation_player.speed_scale = 1.35

func _build_rig() -> void:
	rig = Node2D.new()
	rig.name = "Rig"
	add_child(rig)

	visual_root = Node2D.new()
	visual_root.name = "VisualRoot"
	rig.add_child(visual_root)

	# Torso.
	torso = _line("Torso", visual_root, 19.0, OUTLINE)
	torso.points = PackedVector2Array([Vector2(0, -14), Vector2(0, 17)])
	var shirt_line: Line2D = _line("Shirt", visual_root, 14.0, SHIRT)
	shirt_line.points = PackedVector2Array([Vector2(0, -14), Vector2(0, 17)])
	torso_highlight = _line("TorsoHighlight", visual_root, 3.0, SHIRT_LIGHT)
	torso_highlight.points = PackedVector2Array([Vector2(-3, -11), Vector2(-1, 13)])

	# Head.
	head = Node2D.new()
	head.name = "Head"
	head.position = Vector2(0, -31)
	visual_root.add_child(head)
	_circle("HeadOutline", head, 12.5, OUTLINE)
	_circle("HeadFill", head, 10.2, SKIN)
	var neck_line: Line2D = _line("Neck", visual_root, 5.0, SKIN_SHADOW)
	neck_line.points = PackedVector2Array([Vector2(0, -20), Vector2(0, -23)])
	var eye: Polygon2D = _circle("Eye", head, 2.2, OUTLINE)
	eye.position = Vector2(4.2, -1.3)
	var eye_glint: Polygon2D = _circle("EyeGlint", head, 0.65, Color.WHITE)
	eye_glint.position = Vector2(4.75, -1.8)

	# Limbs are transform nodes; every child rotates around its own joint.
	left_upper_arm = _segment("UpperArmL", visual_root, Vector2(-9.5, -13), 16.0, SHIRT, 6.0)
	left_forearm = _segment("ForearmL", left_upper_arm, Vector2(0, 16), 15.0, SKIN, 4.8)
	right_upper_arm = _segment("UpperArmR", visual_root, Vector2(9.5, -13), 16.0, SHIRT, 6.0)
	right_forearm = _segment("ForearmR", right_upper_arm, Vector2(0, 16), 15.0, SKIN, 4.8)

	left_thigh = _segment("ThighL", visual_root, Vector2(-6.5, 17), 21.0, PANTS, 7.0)
	left_shin = _segment("ShinL", left_thigh, Vector2(0, 21), 21.0, PANTS, 6.0)
	right_thigh = _segment("ThighR", visual_root, Vector2(6.5, 17), 21.0, PANTS, 7.0)
	right_shin = _segment("ShinR", right_thigh, Vector2(0, 21), 21.0, PANTS, 6.0)

	_add_foot(left_shin, "FootL")
	_add_foot(right_shin, "FootR")

func _segment(node_name: String, parent: Node, local_pos: Vector2, length: float, color: Color, width: float) -> Node2D:
	var joint: Node2D = Node2D.new()
	joint.name = node_name
	joint.position = local_pos
	parent.add_child(joint)
	var outline_line: Line2D = _line("Outline", joint, width + 3.0, OUTLINE)
	outline_line.points = PackedVector2Array([Vector2.ZERO, Vector2(0, length)])
	var fill_line: Line2D = _line("Fill", joint, width, color)
	fill_line.points = PackedVector2Array([Vector2.ZERO, Vector2(0, length)])
	_circle("Joint", joint, width * 0.56, color)
	return joint

func _add_foot(parent: Node2D, node_name: String) -> void:
	var foot: Node2D = Node2D.new()
	foot.name = node_name
	foot.position = Vector2(0, 21)
	parent.add_child(foot)
	var outline_line: Line2D = _line("Outline", foot, 7.0, OUTLINE)
	outline_line.points = PackedVector2Array([Vector2.ZERO, Vector2(8, 0)])
	var fill_line: Line2D = _line("Fill", foot, 4.0, SHOE)
	fill_line.points = PackedVector2Array([Vector2.ZERO, Vector2(8, 0)])

func _line(node_name: String, parent: Node, width: float, color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.name = node_name
	line.width = width
	line.default_color = color
	line.antialiased = true
	parent.add_child(line)
	return line

func _circle(node_name: String, parent: Node, radius: float, color: Color) -> Polygon2D:
	var poly: Polygon2D = Polygon2D.new()
	poly.name = node_name
	poly.color = color
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(24):
		var a: float = TAU * float(i) / 24.0
		points.append(Vector2(cos(a), sin(a)) * radius)
	poly.polygon = points
	parent.add_child(poly)
	return poly

func _build_animations() -> void:
	animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	add_child(animation_player)
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation("idle", _make_idle())
	library.add_animation("walk", _make_walk())
	library.add_animation("run", _make_walk())
	library.add_animation("jump", _make_jump())
	library.add_animation("fall", _make_fall())
	library.add_animation("crouch", _make_crouch())
	animation_player.add_animation_library("", library)

func _track(animation: Animation, path: NodePath, values: Array, times: Array[float]) -> void:
	var track: int = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, path)
	animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
	for i in range(times.size()):
		animation.track_insert_key(track, times[i], values[i])

func _make_walk() -> Animation:
	var a: Animation = Animation.new()
	var duration: float = 8.0 / walk_cycle_fps
	a.length = duration
	a.loop_mode = Animation.LOOP_LINEAR
	var t: Array[float] = [0.0, 1.0 / 12.0, 2.0 / 12.0, 3.0 / 12.0, 4.0 / 12.0, 5.0 / 12.0, 6.0 / 12.0, 7.0 / 12.0, 8.0 / 12.0]
	for i in range(t.size()):
		t[i] *= duration

	# Authored 8-pose cycle: Contact, Down, Passing, Up, then the mirrored half.
	var thigh_l: Array[float] = [deg_to_rad(-25), deg_to_rad(-15), deg_to_rad(4), deg_to_rad(18), deg_to_rad(25), deg_to_rad(15), deg_to_rad(-4), deg_to_rad(-18), deg_to_rad(-25)]
	var shin_l: Array[float] = [deg_to_rad(9), deg_to_rad(24), deg_to_rad(7), deg_to_rad(-2), deg_to_rad(-9), deg_to_rad(-24), deg_to_rad(-7), deg_to_rad(2), deg_to_rad(9)]
	var thigh_r: Array[float] = [deg_to_rad(25), deg_to_rad(15), deg_to_rad(-4), deg_to_rad(-18), deg_to_rad(-25), deg_to_rad(-15), deg_to_rad(4), deg_to_rad(18), deg_to_rad(25)]
	var shin_r: Array[float] = [deg_to_rad(-9), deg_to_rad(-24), deg_to_rad(-7), deg_to_rad(2), deg_to_rad(9), deg_to_rad(24), deg_to_rad(7), deg_to_rad(-2), deg_to_rad(-9)]
	var arm_l: Array[float] = [deg_to_rad(22), deg_to_rad(14), deg_to_rad(-2), deg_to_rad(-16), deg_to_rad(-22), deg_to_rad(-14), deg_to_rad(2), deg_to_rad(16), deg_to_rad(22)]
	var fore_l: Array[float] = [deg_to_rad(-10), deg_to_rad(-18), deg_to_rad(-12), deg_to_rad(-5), deg_to_rad(10), deg_to_rad(18), deg_to_rad(12), deg_to_rad(5), deg_to_rad(-10)]
	var arm_r: Array[float] = [deg_to_rad(-22), deg_to_rad(-14), deg_to_rad(2), deg_to_rad(16), deg_to_rad(22), deg_to_rad(14), deg_to_rad(-2), deg_to_rad(-16), deg_to_rad(-22)]
	var fore_r: Array[float] = [deg_to_rad(10), deg_to_rad(18), deg_to_rad(12), deg_to_rad(5), deg_to_rad(-10), deg_to_rad(-18), deg_to_rad(-12), deg_to_rad(-5), deg_to_rad(10)]
	var torso_rot: Array[float] = [deg_to_rad(1), deg_to_rad(1.5), deg_to_rad(1), deg_to_rad(0), deg_to_rad(-1), deg_to_rad(-1.5), deg_to_rad(-1), deg_to_rad(0), deg_to_rad(1)]
	var bob: Array[Vector2] = [Vector2(0,0), Vector2(0,1.2), Vector2(0,0.5), Vector2(0,-0.8), Vector2(0,0), Vector2(0,1.2), Vector2(0,0.5), Vector2(0,-0.8), Vector2(0,0)]

	_track(a, NodePath("Rig/VisualRoot/ThighL:rotation"), thigh_l, t)
	_track(a, NodePath("Rig/VisualRoot/ThighL/ShinL:rotation"), shin_l, t)
	_track(a, NodePath("Rig/VisualRoot/ThighR:rotation"), thigh_r, t)
	_track(a, NodePath("Rig/VisualRoot/ThighR/ShinR:rotation"), shin_r, t)
	_track(a, NodePath("Rig/VisualRoot/UpperArmL:rotation"), arm_l, t)
	_track(a, NodePath("Rig/VisualRoot/UpperArmL/ForearmL:rotation"), fore_l, t)
	_track(a, NodePath("Rig/VisualRoot/UpperArmR:rotation"), arm_r, t)
	_track(a, NodePath("Rig/VisualRoot/UpperArmR/ForearmR:rotation"), fore_r, t)
	_track(a, NodePath("Rig/VisualRoot:rotation"), torso_rot, t)
	_track(a, NodePath("Rig/VisualRoot:position"), bob, t)
	return a

func _make_idle() -> Animation:
	var a: Animation = Animation.new()
	a.length = 1.8
	a.loop_mode = Animation.LOOP_LINEAR
	var times: Array[float] = [0.0, 0.9, 1.8]
	_track(a, NodePath("Rig/VisualRoot:position"), [Vector2.ZERO, Vector2(0, -0.45), Vector2.ZERO], times)
	_track(a, NodePath("Rig/VisualRoot:rotation"), [0.0, deg_to_rad(0.4), 0.0], times)
	return a

func _make_jump() -> Animation:
	var a: Animation = Animation.new()
	a.length = 0.35
	a.loop_mode = Animation.LOOP_NONE
	_track(a, NodePath("Rig/VisualRoot:rotation"), [deg_to_rad(-2), deg_to_rad(3)], [0.0, 0.35])
	_track(a, NodePath("Rig/VisualRoot:position"), [Vector2(0,-2), Vector2(0,0)], [0.0, 0.35])
	return a

func _make_fall() -> Animation:
	var a: Animation = Animation.new()
	a.length = 0.45
	a.loop_mode = Animation.LOOP_LINEAR
	_track(a, NodePath("Rig/VisualRoot:rotation"), [deg_to_rad(2), deg_to_rad(-2)], [0.0, 0.45])
	return a

func _make_crouch() -> Animation:
	var a: Animation = Animation.new()
	a.length = 0.18
	a.loop_mode = Animation.LOOP_LINEAR
	_track(a, NodePath("Rig/VisualRoot:position"), [Vector2.ZERO, Vector2(0, 5)], [0.0, 0.18])
	return a
