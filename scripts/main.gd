extends Node2D
## TRY HACKING ME NOW — project controller.
## Star 3: Level 01 progression and fade transition foundation.

const GAME_TITLE := "TRY HACKING ME NOW"
const VERSION := "0.3.0-beta"

var transitioning := false
@onready var fade: ColorRect = $UI/Fade

func _ready() -> void:
	fade.color = Color(0, 0, 0, 0)
	print("========================================")
	print(GAME_TITLE)
	print("Version: ", VERSION)
	print("Level 01 loaded: THE POLE")
	print("Movement: A/D or Left/Right")
	print("Jump: Space")
	print("Sprint: Shift")
	print("The street pole is a real collision object.")
	print("========================================")

func complete_level_01() -> void:
	if transitioning:
		return
	transitioning = true
	print("LEVEL 01 COMPLETE — THE POLE")
	print("Starting fade transition to Level 02...")
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 0.55)
	tween.tween_callback(_load_next_level)

func _load_next_level() -> void:
	var next_scene := "res://levels/level02.tscn"
	if ResourceLoader.exists(next_scene):
		get_tree().change_scene_to_file(next_scene)
		return

	print("LEVEL 02: ainda não construído.")
	print("A próxima fase será conectada quando for criada.")
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.45)
	tween.tween_property(fade, "color", Color(0, 0, 0, 0), 0.55)
	tween.tween_callback(func(): transitioning = false)
