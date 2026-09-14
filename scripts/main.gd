extends Node2D
## TRY HACKING ME NOW — project foundation.
## This file intentionally stays small in Star 1.
## Later milestones will add the runtime registry, Python bridge,
## terminal, player controller, world systems, missions and anomalies.

const GAME_TITLE := "TRY HACKING ME NOW"
const VERSION := "0.1.0-beta"

func _ready() -> void:
	print("========================================")
	print(GAME_TITLE)
	print("Version: ", VERSION)
	print("Project foundation loaded.")
	print("Python runtime: pending Star 7")
	print("========================================")
