extends Node2D
## TRY HACKING ME NOW — project controller.
## Star 2 adds the first playable character and physics foundation.

const GAME_TITLE := "TRY HACKING ME NOW"
const VERSION := "0.2.0-beta"

func _ready() -> void:
	print("========================================")
	print(GAME_TITLE)
	print("Version: ", VERSION)
	print("Player controller loaded.")
	print("Movement: A/D or Left/Right")
	print("Jump: Space")
	print("Sprint: Shift")
	print("========================================")
