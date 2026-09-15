extends CharacterBody2D

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

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visual_root: Node2D = $Rig/VisualRoot

var facing_direction: float = 1.0
var is_sprinting := false
var is_crouching := false
var animation_state := "idle"

func _ready() -> void:
	visible = true
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	z_index = 100
	_sanitize_rotation_tracks()
	_reset_pose()
	_play_state("idle")

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
	_update_animation_state()
	_update_facing()

func _update_animation_state() -> void:
	var next_state := "idle"
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
	# The character must never rotate as a whole. Facing is handled only by X scale.
	visual_root.rotation = 0.0
	visual_root.scale.x = abs(visual_root.scale.x) * facing_direction

func _sanitize_rotation_tracks() -> void:
	# Remove whole-body rotation tracks from the authored animations.
	# Those tracks were making the character spin/tumble when AnimationPlayer
	# looped or blended between states. Limbs keep their own rotation tracks.
	for animation_name in [&"walk", &"jump", &"fall"]:
		if not animation_player.has_animation(animation_name):
			continue
		var animation := animation_player.get_animation(animation_name)
		for track_index in range(animation.get_track_count() - 1, -1, -1):
			var path := animation.track_get_path(track_index)
			if path == NodePath("Rig/VisualRoot:rotation"):
				animation.remove_track(track_index)

func _reset_pose() -> void:
	visual_root.position = Vector2.ZERO
	visual_root.rotation = 0.0
	$Rig/VisualRoot/ThighL.rotation = 0.0
	$Rig/VisualRoot/ThighL/ShinL.rotation = 0.0
	$Rig/VisualRoot/ThighR.rotation = 0.0
	$Rig/VisualRoot/ThighR/ShinR.rotation = 0.0
	$Rig/VisualRoot/UpperArmL.rotation = 0.0
	$Rig/VisualRoot/UpperArmL/ForearmL.rotation = 0.0
	$Rig/VisualRoot/UpperArmR.rotation = 0.0
	$Rig/VisualRoot/UpperArmR/ForearmR.rotation = 0.0

func _play_state(state: String) -> void:
	animation_state = state

	# Sprint uses the authored walk cycle at a higher playback speed. The old
	# run animation only keyed VisualRoot.scale and could overwrite facing.
	var clip := "walk" if state == "run" else state
	if not animation_player.has_animation(clip):
		clip = "idle"

	animation_player.stop()

	# Only walk/run key every limb. Reset first when entering idle, jump, fall,
	# or crouch so a previous walk pose can never remain stuck on the character.
	if clip != "walk":
		_reset_pose()

	animation_player.play(clip, 0.10 if state != "idle" else 0.16)
	animation_player.speed_scale = 1.0
	if state == "walk":
		animation_player.speed_scale = max(walk_cycle_fps / 12.0, 0.01)
	elif state == "run":
		animation_player.speed_scale = max((walk_cycle_fps / 12.0) * 1.35, 0.01)
