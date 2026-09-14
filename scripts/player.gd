extends CharacterBody2D
## TRY HACKING ME NOW — animated Player controller
## 4-frame procedural stickman animation with guaranteed visible rendering.

@export_category("Movement")
@export var move_speed: float = 260.0
@export var sprint_speed: float = 390.0
@export var acceleration: float = 1800.0
@export var friction: float = 2200.0
@export var jump_power: float = 560.0
@export var gravity: float = 1500.0
@export var max_fall_speed: float = 1100.0

@export_category("Animation")
@export var animation_fps: float = 9.0

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
			animation_frame = (animation_frame + 1) % 4

func _draw() -> void:
	var body := Color(0.96, 0.96, 0.96, 1.0)
	var outline := Color(0.04, 0.04, 0.04, 1.0)
	var accent := Color(0.91, 0.71, 0.29, 1.0)
	var f := animation_frame
	var d := facing_direction

	var head_y := -30.0
	var shoulder_y := -17.0
	var hip_y := 18.0
	var arm_a := Vector2(20, 2)
	var arm_b := Vector2(-17, 5)
	var leg_a := Vector2(12, 40)
	var leg_b := Vector2(-12, 40)

	match animation_state:
		"walk":
			var frames = [[Vector2(20,4),Vector2(-18,3),Vector2(15,43),Vector2(-8,38)],[Vector2(18,1),Vector2(-18,1),Vector2(11,40),Vector2(-11,40)],[Vector2(8,3),Vector2(-21,5),Vector2(-8,38),Vector2(15,43)],[Vector2(18,1),Vector2(-18,1),Vector2(11,40),Vector2(-11,40)]]
			var p = frames[f]
			arm_a=p[0]; arm_b=p[1]; leg_a=p[2]; leg_b=p[3]
		"run":
			var frames = [[Vector2(25,0),Vector2(-19,9),Vector2(20,44),Vector2(-15,34)],[Vector2(19,-5),Vector2(-24,7),Vector2(10,35),Vector2(-18,45)],[Vector2(8,5),Vector2(-25,-1),Vector2(-18,35),Vector2(22,45)],[Vector2(19,-5),Vector2(-24,7),Vector2(10,35),Vector2(-18,45)]]
			var p = frames[f]
			arm_a=p[0]; arm_b=p[1]; leg_a=p[2]; leg_b=p[3]
		"jump":
			arm_a=Vector2(18,-17); arm_b=Vector2(-18,-12); leg_a=Vector2(14,30); leg_b=Vector2(-14,30); head_y=-32.0-float(f%2)
		"fall":
			arm_a=Vector2(24,8); arm_b=Vector2(-24,8); leg_a=Vector2(18,42); leg_b=Vector2(-18,42)
		"crouch":
			head_y=-18.0; shoulder_y=-7.0; hip_y=15.0; arm_a=Vector2(21,12); arm_b=Vector2(-20,14)
			var crouch_legs=[Vector2(14,28),Vector2(-10,25),Vector2(10,29),Vector2(-14,26)]
			leg_a=crouch_legs[f]; leg_b=Vector2(-leg_a.x,leg_a.y-2.0)
		"idle":
			var bob=[0.0,-1.0,0.0,1.0][f]
			head_y+=bob; shoulder_y+=bob; arm_a=Vector2(20,2+bob); arm_b=Vector2(-17,5+bob)

	arm_a.x*=d; arm_b.x*=d; leg_a.x*=d; leg_b.x*=d

	# Visible stickman: thick black outline + white body.
	draw_circle(Vector2(0,head_y),14.0,outline)
	draw_circle(Vector2(0,head_y),10.5,body)
	draw_line(Vector2(0,shoulder_y),Vector2(0,hip_y),outline,7.0,true)
	draw_line(Vector2(0,shoulder_y+3.0),arm_a,outline,6.0,true)
	draw_line(Vector2(0,shoulder_y+3.0),arm_b,outline,6.0,true)
	draw_line(Vector2(0,hip_y),leg_a,outline,7.0,true)
	draw_line(Vector2(0,hip_y),leg_b,outline,7.0,true)
	draw_circle(Vector2(4.0*d,head_y-1.0),2.2,outline)

	if is_sprinting:
		draw_line(Vector2(-7,-43),Vector2(7,-43),accent,3.0,true)
