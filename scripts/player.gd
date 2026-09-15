extends CharacterBody2D
## TRY HACKING ME NOW — Player controller + PNG stickman animation rig
## Usa as peças reais do stickman em imageens/ e mantém a física independente da animação.

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
@export var visual_scale: float = 0.62
@export var animation_smoothing: float = 14.0

var facing_direction := 1.0
var is_sprinting := false
var is_crouching := false
var animation_time := 0.0
var animation_frame := 0
var animation_state := "idle"
var animation_phase := 0.0

var visual_root: Node2D
var head_sprite: Sprite2D
var torso_sprite: Sprite2D
var right_arm_sprite: Sprite2D
var left_arm_sprite: Sprite2D
var right_leg_sprite: Sprite2D
var left_leg_sprite: Sprite2D
var sprites_ready := false
var base_positions: Dictionary = {}

const HEAD_PATH := "res://imageens/CABEÇA DO STICKMAN.png"
const TORSO_PATH := "res://imageens/TORÇO DO STICKMAN.png"
const RIGHT_ARM_PATH := "res://imageens/BRAÇO_DIREITO.png"
const LEFT_ARM_PATH := "res://imageens/BRAÇO_ESQUERDO.png"
const RIGHT_LEG_PATH := "res://imageens/PERNA_DIREITA.png"
const LEFT_LEG_PATH := "res://imageens/PERNA ESQUERDA.png"

func _ready() -> void:
	z_index = 100
	_build_visual_rig()
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
	_update_visual_rig(delta)

func _build_visual_rig() -> void:
	visual_root = Node2D.new()
	visual_root.name = "StickmanVisual"
	visual_root.position = Vector2(0, 1)
	add_child(visual_root)

	head_sprite = _make_sprite("Head", HEAD_PATH, 30)
	torso_sprite = _make_sprite("Torso", TORSO_PATH, 20)
	right_arm_sprite = _make_sprite("RightArm", RIGHT_ARM_PATH, 30)
	left_arm_sprite = _make_sprite("LeftArm", LEFT_ARM_PATH, 30)
	right_leg_sprite = _make_sprite("RightLeg", RIGHT_LEG_PATH, 25)
	left_leg_sprite = _make_sprite("LeftLeg", LEFT_LEG_PATH, 25)

	# As peças são separadas, mas ficam organizadas como um verdadeiro rig.
	# Os pontos iniciais são relativos ao centro do personagem e podem ser
	# refinados sem tocar na física.
	base_positions = {
		"head": Vector2(0, -30),
		"torso": Vector2(0, 0),
		"right_arm": Vector2(11, -10),
		"left_arm": Vector2(-11, -10),
		"right_leg": Vector2(7, 27),
		"left_leg": Vector2(-7, 27)
	}

	_set_base_positions()
	sprites_ready = true

func _make_sprite(sprite_name: String, path: String, layer: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = load(path)
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = layer
	sprite.scale = Vector2.ONE * visual_scale
	sprite.modulate = Color.WHITE
	visual_root.add_child(sprite)
	return sprite

func _set_base_positions() -> void:
	if not sprites_ready and visual_root == null:
		return
	head_sprite.position = base_positions["head"]
	torso_sprite.position = base_positions["torso"]
	right_arm_sprite.position = base_positions["right_arm"]
	left_arm_sprite.position = base_positions["left_arm"]
	right_leg_sprite.position = base_positions["right_leg"]
	left_leg_sprite.position = base_positions["left_leg"]

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
		animation_phase = 0.0
	else:
		animation_time += delta

	var animation_speed := animation_fps
	match animation_state:
		"idle": animation_speed *= 0.35
		"walk": animation_speed *= 0.95
		"run": animation_speed *= 1.28
		"jump", "fall": animation_speed *= 0.7
		"crouch": animation_speed *= 0.55

	animation_phase = fmod(animation_phase + delta * animation_speed / float(animation_frames), 1.0)
	animation_frame = int(animation_phase * float(animation_frames)) % animation_frames

func _update_visual_rig(delta: float) -> void:
	if not sprites_ready:
		return

	var t := min(delta * animation_smoothing, 1.0)
	var phase := animation_phase * TAU
	var stride := sin(phase)
	var opposite := -stride
	var fast_phase := phase * 1.28
	var fast_stride := sin(fast_phase)
	var fast_opposite := -fast_stride
	var bob := 0.0
	var torso_angle := 0.0
	var head_angle := 0.0

	var target_head := base_positions["head"]
	var target_torso := base_positions["torso"]
	var target_ra := base_positions["right_arm"]
	var target_la := base_positions["left_arm"]
	var target_rl := base_positions["right_leg"]
	var target_ll := base_positions["left_leg"]
	var target_ra_rot := 0.0
	var target_la_rot := 0.0
	var target_rl_rot := 0.0
	var target_ll_rot := 0.0

	match animation_state:
		"idle":
			var breathe := sin(phase) * 1.2
			bob = breathe
			target_head += Vector2(0, bob)
			target_torso += Vector2(0, bob * 0.45)
			target_ra += Vector2(0, bob * 0.6)
			target_la += Vector2(0, bob * 0.6)
			target_ra_rot = sin(phase) * 0.035
			target_la_rot = -sin(phase) * 0.035
			head_angle = sin(phase) * 0.025

		"walk":
			bob = abs(sin(phase * 2.0)) * -1.8
			target_head += Vector2(0, bob)
			target_torso += Vector2(0, bob * 0.55)
			target_ra += Vector2(opposite * 3.0, bob * 0.35)
			target_la += Vector2(stride * 3.0, bob * 0.35)
			target_rl += Vector2(stride * 5.0, -abs(stride) * 1.8)
			target_ll += Vector2(opposite * 5.0, -abs(opposite) * 1.8)
			target_ra_rot = opposite * 0.20
			target_la_rot = stride * 0.20
			target_rl_rot = opposite * 0.22
			target_ll_rot = stride * 0.22
			torso_angle = stride * 0.025

		"run":
			bob = abs(sin(fast_phase * 2.0)) * -2.8
			target_head += Vector2(0, bob)
			target_torso += Vector2(fast_stride * 1.4, bob * 0.5)
			target_ra += Vector2(fast_opposite * 5.0, bob * 0.3)
			target_la += Vector2(fast_stride * 5.0, bob * 0.3)
			target_rl += Vector2(fast_stride * 8.0, -abs(fast_stride) * 2.6)
			target_ll += Vector2(fast_opposite * 8.0, -abs(fast_opposite) * 2.6)
			target_ra_rot = fast_opposite * 0.34
			target_la_rot = fast_stride * 0.34
			target_rl_rot = fast_opposite * 0.34
			target_ll_rot = fast_stride * 0.34
			torso_angle = fast_stride * 0.055
			head_angle = -fast_stride * 0.035

		"jump":
			var lift := clamp(-velocity.y / jump_power, 0.0, 1.0)
			target_head += Vector2(0, -lift * 2.0)
			target_ra += Vector2(4.0 * facing_direction, -7.0 * lift)
			target_la += Vector2(-4.0 * facing_direction, -7.0 * lift)
			target_rl += Vector2(8.0 * facing_direction, 5.0)
			target_ll += Vector2(-8.0 * facing_direction, 5.0)
			target_ra_rot = -0.55 * facing_direction
			target_la_rot = 0.55 * facing_direction
			target_rl_rot = 0.20 * facing_direction
			target_ll_rot = -0.20 * facing_direction
			torso_angle = -0.04 * facing_direction

		"fall":
			target_ra += Vector2(5.0 * facing_direction, 2.0)
			target_la += Vector2(-5.0 * facing_direction, 2.0)
			target_rl += Vector2(8.0 * facing_direction, 3.0)
			target_ll += Vector2(-8.0 * facing_direction, 3.0)
			target_ra_rot = -0.35 * facing_direction
			target_la_rot = 0.35 * facing_direction
			target_rl_rot = 0.18 * facing_direction
			target_ll_rot = -0.18 * facing_direction
			torso_angle = -0.025 * facing_direction

		"crouch":
			var crouch_breathe := sin(phase) * 0.7
			target_head = Vector2(0, -20 + crouch_breathe)
			target_torso = Vector2(0, 5)
			target_ra = Vector2(12, 2)
			target_la = Vector2(-12, 2)
			target_rl = Vector2(10, 23)
			target_ll = Vector2(-10, 23)
			target_ra_rot = 0.18
			target_la_rot = -0.18
			target_rl_rot = -0.28
			target_ll_rot = 0.28

	# Espelhamento horizontal sem alterar a ordem das peças.
	var mirror := facing_direction
	var ra_pos := target_ra
	var la_pos := target_la
	if mirror < 0.0:
		ra_pos.x = -target_ra.x
		la_pos.x = -target_la.x

	# Rotação suave evita qualquer troca seca de pose.
	_head_set(target_head, head_angle, t)
	_smooth_transform(torso_sprite, target_torso, torso_angle, t)
	_smooth_transform(right_arm_sprite, ra_pos, target_ra_rot * mirror, t)
	_smooth_transform(left_arm_sprite, la_pos, target_la_rot * mirror, t)
	_smooth_transform(right_leg_sprite, target_rl * Vector2(mirror, 1), target_rl_rot * mirror, t)
	_smooth_transform(left_leg_sprite, target_ll * Vector2(mirror, 1), target_ll_rot * mirror, t)

	visual_root.scale.x = lerp(visual_root.scale.x, mirror, min(delta * 18.0, 1.0))
	visual_root.scale.y = lerp(visual_root.scale.y, 1.0, min(delta * 18.0, 1.0))

func _head_set(target: Vector2, target_rotation: float, weight: float) -> void:
	head_sprite.position = head_sprite.position.lerp(target, weight)
	head_sprite.rotation = lerp_angle(head_sprite.rotation, target_rotation, weight)

func _smooth_transform(sprite: Sprite2D, target: Vector2, target_rotation: float, weight: float) -> void:
	sprite.position = sprite.position.lerp(target, weight)
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, weight)

func _draw() -> void:
	# Pequena sombra elíptica desenhada atrás do rig para dar sensação de peso.
	if animation_state != "jump" and animation_state != "fall":
		draw_ellipse(Vector2(0, 36), Vector2(13, 3), Color(0, 0, 0, 0.18))

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)
