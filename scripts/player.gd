extends CharacterBody2D
## TRY HACKING ME NOW — animated Player controller
## Four-frame procedural animations: idle, walk, run, jump, fall and crouch.

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
	var body := Color("f4f4f4")
	var outline := Color("171717")
	var accent := Color("e8b44d")
	var f := animation_frame
	var d := facing_direction
	var head_y := -30.0
	var top := -17.0
	var hip := 18.0
	var arm_a := Vector2(20, 2)
	var arm_b := Vector2(-17, 5)
	var leg_a := Vector2(12, 40)
	var leg_b := Vector2(-12, 40)

	match animation_state:
		"walk":
			var p := [[Vector2(20,4),Vector2(-18,3),Vector2(15,43),Vector2(-8,38)],[Vector2(18,1),Vector2(-18,1),Vector2(11,40),Vector2(-11,40)],[Vector2(8,3),Vector2(-21,5),Vector2(-8,38),Vector2(15,43)],[Vector2(18,1),Vector2(-18,1),Vector2(11,40),Vector2(-11,40)]][f]
			arm_a=p[0]; arm_b=p[1]; leg_a=p[2]; leg_b=p[3]
		"run":
			var p := [[Vector2(25,0),Vector2(-19,9),Vector2(20,44),Vector2(-15,34)],[Vector2(19,-5),Vector2(-24,7),Vector2(10,35),Vector2(-18,45)],[Vector2(8,5),Vector2(-25,-1),Vector2(-18,35),Vector2(22,45)],[Vector2(19,-5),Vector2(-24,7),Vector2(10,35),Vector2(-18,45)]][f]
			arm_a=p[0]; arm_b=p[1]; leg_a=p[2]; leg_b=p[3]
		"jump":
			arm_a=Vector2(18,-17); arm_b=Vector2(-18,-12); leg_a=Vector2(14,30); leg_b=Vector2(-14,30); head_y=-32.0-f%2
		"fall":
			arm_a=Vector2(24,8); arm_b=Vector2(-24,8); leg_a=Vector2(18,42); leg_b=Vector2(-18,42)
		"crouch":
			head_y=-18.0; top=-7.0; hip=15.0; arm_a=Vector2(21,12); arm_b=Vector2(-20,14)
			leg_a=[Vector2(14,28),Vector2(-10,25),Vector2(10,29),Vector2(-14,26)][f]; leg_b=Vector2(-leg_a.x,leg_a.y-2)
		"idle":
			var bob := [0.0,-1.0,0.0,1.0][f]
			head_y+=bob; top+=bob; arm_a=Vector2(20,2+bob); arm_b=Vector2(-17,5+bob)

	arm_a *= Vector2(d,1); arm_b *= Vector2(d,1); leg_a *= Vector2(d,1); leg_b *= Vector2(d,1)
	draw_circle(Vector2(0,head_y),13.0,outline)
	draw_circle(Vector2(0,head_y),10.0,body)
	draw_line(Vector2(0,top),Vector2(0,hip),outline,6.0,true)
	draw_line(Vector2(0,top+3),arm_a,outline,5.0,true)
	draw_line(Vector2(0,top+3),arm_b,outline,5.0,true)
	draw_line(Vector2(0,hip),leg_a,outline,6.0,true)
	draw_line(Vector2(0,hip),leg_b,outline,6.0,true)
	if is_sprinting:
		draw_line(Vector2(-7,-39),Vector2(7,-39),accent,3.0,true)
