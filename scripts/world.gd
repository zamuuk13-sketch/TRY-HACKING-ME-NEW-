extends Node2D
## Star 3 — 2D lateral world, large playable space and visual environment.

func _ready() -> void:
	queue_redraw()

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
	# Street lamps and trees create recognizable landmarks.
	for i in range(-10, 11):
		var x := float(i * 620 + 100)
		draw_line(Vector2(x, 390), Vector2(x, 260), Color("#3f4542"), 8.0)
		draw_line(Vector2(x, 265), Vector2(x + 28, 245), Color("#3f4542"), 6.0)
		draw_circle(Vector2(x + 35, 240), 12, Color("#f4e9b1"))
	# A few foreground blocks.
	for i in range(-5, 6):
		var x := float(i * 1000 + 500)
		draw_rect(Rect2(x, 320, 180, 70), Color("#586b57"))
