extends CharacterBody2D
## TRY HACKING ME NOW — Player controller with modular PNG character.
## The Player remains the invisible gameplay body; Visual contains the PNG parts.

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

@onready var visual: Node2D = $Visual
@onready var head: Sprite2D = $Visual/Head
@onready var torso: Sprite2D = $Visual/Torso
@onready var arm_right: Sprite2D = $Visual/ArmRight
@onready var arm_left: Sprite2D = $Visual/ArmLeft
@onready var leg_right: Sprite2D = $Visual/LegRight
@onready var leg_left: Sprite2D = $Visual/LegLeft

var facing_direction := 1.0
var is_sprinting := false
var is_crouching := false
var animation_time := 0.0

func _ready() -> void:
	# Gameplay body stays invisible; only the modular PNG Visual is rendered.
	z_index = 100
	# Keep all visual parts together under one cheap Node2D transform.
	visual.visible = true
	visual.z_index = 100
	# Initial compact stickman layout.
	head.position = Vector2(0, -30)
	torso.position = Vector2(0, -1)
	arm_right.position = Vector2(12, -8)
	arm_left.position = Vector2(-12, -8)
	leg_right.position = Vector2(7, 27)
	leg_left.position = Vector2(-7, 27)
	for part in [head, torso, arm_right, arm_left, leg_right, leg_left]:
		part.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

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
	_update_png_animation(delta)

func _update_png_animation(delta: float) -> void:
	animation_time += delta
	var moving := abs(velocity.x) > 15.0 and is_on_floor()
	var phase := animation_time * (10.0 if is_sprinting else animation_fps)
	var swing := sin(phase) if moving else sin(animation_time * 2.0) * 0.15
	var opposite := -swing

	# Flip the complete visual without touching the gameplay body.
	visual.scale.x = facing_direction

	if is_crouching:
		visual.position.y = 9.0
		head.position = Vector2(0, -21)
		torso.position = Vector2(0, 5)
		arm_right.position = Vector2(12, 0)
		arm_left.position = Vector2(-12, 0)
		leg_right.position = Vector2(8, 24)
		leg_left.position = Vector2(-8, 24)
		arm_right.rotation = -0.15
		arm_left.rotation = 0.15
		leg_right.rotation = -0.12
		leg_left.rotation = 0.12
		return

	visual.position.y = 0.0

	if not is_on_floor():
		# Compact airborne pose.
		head.position = Vector2(0, -32)
		torso.position = Vector2(0, -2)
		arm_right.position = Vector2(13, -10)
		arm_left.position = Vector2(-13, -10)
		leg_right.position = Vector2(8, 27)
		leg_left.position = Vector2(-8, 27)
		arm_right.rotation = -0.25
		arm_left.rotation = 0.25
		leg_right.rotation = 0.12
		leg_left.rotation = -0.12
		return

	# Base pose.
	head.position = Vector2(0, -30 + (sin(animation_time * 4.0) * 0.6 if not moving else 0.0))
	torso.position = Vector2(0, -1)

	if moving:
		# Lightweight limb animation: only Sprite2D transforms are changed.
		arm_right.position = Vector2(12, -8)
		arm_left.position = Vector2(-12, -8)
		leg_right.position = Vector2(7, 27)
		leg_left.position = Vector2(-7, 27)
		arm_right.rotation = swing * 0.45
		arm_left.rotation = opposite * 0.45
		leg_right.rotation = opposite * 0.32
		leg_left.rotation = swing * 0.32
		visual.position.y = abs(swing) * 0.8
	else:
		arm_right.position = Vector2(12, -8)
		arm_left.position = Vector2(-12, -8)
		leg_right.position = Vector2(7, 27)
		leg_left.position = Vector2(-7, 27)
		arm_right.rotation = 0.0
		arm_left.rotation = 0.0
		leg_right.rotation = 0.0
		leg_left.rotation = 0.0
