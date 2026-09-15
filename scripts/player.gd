extends CharacterBody2D

const STICKMAN_TEXTURE: Texture2D = preload("res://imageens/stickman foda 3 sem fundo.png")

@export var move_speed := 260.0
@export var sprint_speed := 390.0
@export var acceleration := 1800.0
@export var friction := 2200.0
@export var jump_power := 560.0
@export var gravity := 1500.0
@export var max_fall_speed := 1100.0

@onready var player_sprite: Sprite2D = $StickmanSprite

var facing_direction := 1.0
var is_sprinting := false
var is_crouching := false
var animation_time := 0.0
var base_position := Vector2(0, -78)
var base_scale := Vector2(0.20, 0.20)
var use_png := true

func _ready() -> void:
	z_index = 1000
	player_sprite.texture = STICKMAN_TEXTURE
	player_sprite.visible = true
	player_sprite.modulate = Color.WHITE
	player_sprite.self_modulate = Color.WHITE
	player_sprite.centered = true
	player_sprite.position = base_position
	player_sprite.scale = base_scale
	player_sprite.rotation = 0.0
	player_sprite.z_index = 10
	player_sprite.z_as_relative = false
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	# Verify that the PNG actually contains visible pixels.
	var img := STICKMAN_TEXTURE.get_image()
	var visible_pixels := 0
	if img != null and not img.is_empty():
		var step_x := max(1, img.get_width() / 24)
		var step_y := max(1, img.get_height() / 24)
		for y in range(0, img.get_height(), step_y):
			for x in range(0, img.get_width(), step_x):
				if img.get_pixel(x, y).a > 0.05:
					visible_pixels += 1
					break
			if visible_pixels > 0:
				break

	use_png = visible_pixels > 0
	print("[PLAYER] texture=", STICKMAN_TEXTURE.get_width(), "x", STICKMAN_TEXTURE.get_height(), " visible_pixels=", visible_pixels)
	print("[PLAYER] visible_in_tree=", is_visible_in_tree(), " global_position=", global_position)

	if not use_png:
		print("[PLAYER] PNG has no visible alpha pixels. Using procedural fallback.")

	queue_redraw()

func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	is_crouching = Input.is_action_pressed("crouch") and is_on_floor()
	is_sprinting = Input.is_key_pressed(KEY_SHIFT) and not is_crouching
	var speed := sprint_speed if is_sprinting else move_speed
	if is_crouching:
		speed *= 0.45

	if axis != 0.0:
		velocity.x = move_toward(velocity.x, axis * speed, acceleration * delta)
		facing_direction = sign(axis)
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
	_update_visual(delta)

func _update_visual(delta: float) -> void:
	animation_time += delta
	var moving := abs(velocity.x) > 15.0
	var phase_speed := 11.0 if is_sprinting else 8.0
	var wave := sin(animation_time * phase_speed)
	var bob := abs(sin(animation_time * phase_speed * 2.0))

	var target_pos := base_position
	var target_rot := 0.0
	var target_scale := base_scale

	if not is_on_floor():
		if velocity.y < 0.0:
			target_pos.y -= 4.0
			target_rot = -0.035 * facing_direction
		else:
			target_rot = 0.025 * facing_direction
	elif is_crouching:
		target_pos.y += 12.0
		target_scale *= Vector2(1.04, 0.88)
	elif moving:
		target_pos.y -= bob * (3.0 if is_sprinting else 2.0)
		target_rot = wave * (0.055 if is_sprinting else 0.025)
	else:
		target_pos.y += sin(animation_time * 2.0) * 0.8
		target_rot = sin(animation_time * 1.4) * 0.008

	target_scale.x = abs(target_scale.x) * facing_direction
	var smooth := min(delta * 14.0, 1.0)
	player_sprite.position = player_sprite.position.lerp(target_pos, smooth)
	player_sprite.rotation = lerp_angle(player_sprite.rotation, target_rot, smooth)
	player_sprite.scale = player_sprite.scale.lerp(target_scale, smooth)
	player_sprite.visible = use_png

	queue_redraw()

func _draw() -> void:
	# Shadow under the character.
	if is_on_floor():
		var shadow := PackedVector2Array()
		for i in range(24):
			var a := TAU * float(i) / 24.0
			shadow.append(Vector2(cos(a) * 15.0, 3.0 + sin(a) * 3.2))
		draw_colored_polygon(shadow, Color(0, 0, 0, 0.16))

	# Guaranteed visible fallback if the PNG itself is empty/transparent.
	if not use_png:
		var s := facing_direction
		var bob := 1.5 * sin(animation_time * 2.0)
		var head := Vector2(0, -142 + bob)
		var neck := Vector2(0, -123 + bob)
		var hip := Vector2(0, -65 + bob)
		var left_hand := Vector2(-30 * s, -94 + bob)
		var right_hand := Vector2(30 * s, -94 + bob)
		var left_foot := Vector2(-16 * s, 0)
		var right_foot := Vector2(16 * s, 0)

		# Body and limbs.
		draw_line(neck, hip, Color.BLACK, 9.0, true)
		draw_line(neck, left_hand, Color.BLACK, 7.0, true)
		draw_line(neck, right_hand, Color.BLACK, 7.0, true)
		draw_line(hip, left_foot, Color.BLACK, 8.0, true)
		draw_line(hip, right_foot, Color.BLACK, 8.0, true)
		draw_circle(head, 22.0, Color.BLACK)

		# Small white face area so the fallback is clearly visible on the paper background.
		draw_circle(head, 15.0, Color.WHITE)
		draw_circle(head + Vector2(-5 * s, -2), 2.5, Color.BLACK)
		draw_circle(head + Vector2(5 * s, -2), 2.5, Color.BLACK)
