extends Node2D
## TRY HACKING ME NOW — Star 3 world foundation.
## Level 01 is built around a real street pole that physically blocks the player.

var level_01_completed := false
var pole_path := NodePath("Level01/Environment/StreetPole_07")
var exit_path := NodePath("Level01/Level01Exit")

func _ready() -> void:
	queue_redraw()
	var exit_zone := get_node_or_null(exit_path) as Area2D
	if exit_zone:
		exit_zone.body_entered.connect(_on_level01_exit_body_entered)

func _process(_delta: float) -> void:
	# The player can only finish Level 01 after the blocking pole has been
	# removed or its collision has been disabled through the runtime.
	if level_01_completed:
		return
	var pole := get_node_or_null(pole_path)
	if pole == null:
		return
	var shape := pole.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape and not shape.disabled:
		return

func _on_level01_exit_body_entered(body: Node) -> void:
	if level_01_completed or not body.name == "Player":
		return
	if _pole_still_blocks_path():
		return
	level_01_completed = true
	var game := get_parent()
	if game and game.has_method("complete_level_01"):
		game.complete_level_01()

func _pole_still_blocks_path() -> bool:
	var pole := get_node_or_null(pole_path)
	if pole == null:
		return false
	var shape := pole.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return shape != null and not shape.disabled

func _draw() -> void:
	# Simple polished cartoon background — deliberately not cyberpunk/neon.
	draw_rect(Rect2(-5000, -1200, 10000, 1600), Color("#b9d8ee"))

	# Distant hills.
	for i in range(-8, 9):
		var x := float(i * 700)
		var pts := PackedVector2Array([
			Vector2(x - 450, 390), Vector2(x - 180, 170), Vector2(x + 80, 310),
			Vector2(x + 350, 120), Vector2(x + 620, 390)
		])
		draw_colored_polygon(pts, Color("#91b99c"))

	# Clouds at different depths.
	for i in range(-6, 7):
		var x := float(i * 900 + (i % 2) * 250)
		var y := float(80 + (abs(i) % 3) * 55)
		draw_circle(Vector2(x, y), 38, Color("#ffffffcc"))
		draw_circle(Vector2(x + 42, y + 5), 30, Color("#ffffffcc"))
		draw_circle(Vector2(x - 38, y + 8), 27, Color("#ffffffcc"))

	# Background city silhouettes.
	for i in range(-12, 13):
		var x := float(i * 420)
		var h := float(90 + (abs(i * 17) % 140))
		draw_rect(Rect2(x, 390 - h, 260, h), Color("#7893a5"))
		for row in range(3):
			for col in range(4):
				draw_rect(Rect2(x + 30 + col * 55, 420 - h + row * 45, 20, 25), Color("#dce8d6"))

	# Ground strip.
	draw_rect(Rect2(-5000, 390, 10000, 330), Color("#6f7d62"))
	draw_rect(Rect2(-5000, 390, 10000, 12), Color("#3f4a38"))

	# Road/sidewalk.
	draw_rect(Rect2(-5000, 402, 10000, 110), Color("#8f938b"))
	draw_line(Vector2(-5000, 457), Vector2(5000, 457), Color("#d8d2a8"), 4.0)

	# Background street lamps. The actual Level 01 blocking pole is a real node,
	# drawn separately below so Python can inspect and modify it.
	for i in range(-10, 11):
		var x := float(i * 620 + 100)
		if abs(x - 900.0) < 1.0:
			continue
		draw_line(Vector2(x, 390), Vector2(x, 260), Color("#3f4542"), 8.0)
		draw_line(Vector2(x, 265), Vector2(x + 28, 245), Color("#3f4542"), 6.0)
		draw_circle(Vector2(x + 35, 240), 12, Color("#f4e9b1"))

	# Level 01's actual blocking street pole at x=900.
	var pole_x := 900.0
	draw_line(Vector2(pole_x, 390), Vector2(pole_x, 245), Color("#303633"), 11.0)
	draw_line(Vector2(pole_x, 250), Vector2(pole_x + 38, 230), Color("#303633"), 8.0)
	draw_circle(Vector2(pole_x + 46, 225), 15.0, Color("#f6e7a6"))
	draw_line(Vector2(pole_x - 12, 390), Vector2(pole_x + 12, 390), Color("#242825"), 5.0)

	# A few foreground blocks.
	for i in range(-5, 6):
		var x := float(i * 1000 + 500)
		draw_rect(Rect2(x, 320, 180, 70), Color("#586b57"))
