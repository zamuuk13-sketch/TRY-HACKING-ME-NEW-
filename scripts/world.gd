extends Node2D
## TRY HACKING ME NOW — Star 3 world foundation.
## Level 01 is a small stickman scene built around a real PNG street pole.

var level_01_completed := false
var pole_path := NodePath("Level01/Environment/StreetPole_07")
const LEVEL_01_RIGHT_EXIT_X := 1660.0

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	if level_01_completed:
		return

	var player := get_parent().get_node_or_null("Player")
	if player == null:
		return

	# The player must actually reach the far right side of the small level.
	# The pole has to be removed or have its collision disabled first.
	if player.global_position.x < LEVEL_01_RIGHT_EXIT_X:
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
	# The visual background is now the PNG in imageens/papel.png.
	# No procedural city/background is drawn here so the paper aesthetic stays clean.
	pass
