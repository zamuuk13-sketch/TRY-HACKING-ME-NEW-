extends CanvasLayer
## TRY HACKING ME NOW — startup/runtime diagnostics.
## This script observes the game. It does not change player physics, input or camera.

const PANEL_SIZE := Vector2(560, 430)
const MARGIN := 18.0

var panel: ColorRect
var text: Label
var status: Label
var visible_debug := true
var elapsed := 0.0
var last_report := ""

func _ready() -> void:
	layer = 900
	_build_ui()
	_run_diagnostics()
	print("[DEBUG] Startup diagnostics initialized.")
	print("[DEBUG] Press F9 to toggle the diagnostics panel.")

func _process(delta: float) -> void:
	elapsed += delta
	if Input.is_key_pressed(KEY_F9):
		# Debounce using a small timer instead of reacting every frame.
		if elapsed > 0.25:
			visible_debug = not visible_debug
			panel.visible = visible_debug
			elapsed = 0.0
	if visible_debug and Engine.get_process_frames() % 30 == 0:
		_run_diagnostics()

func _build_ui() -> void:
	panel = ColorRect.new()
	panel.name = "DiagnosticsPanel"
	panel.position = Vector2(MARGIN, MARGIN)
	panel.size = PANEL_SIZE
	panel.color = Color(0.015, 0.015, 0.02, 0.94)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	var title := Label.new()
	title.position = Vector2(18, 12)
	title.text = "TRY HACKING ME NOW — DEBUG DIAGNOSTICS"
	title.add_theme_font_size_override("font_size", 18)
	panel.add_child(title)

	status = Label.new()
	status.position = Vector2(18, 42)
	status.add_theme_font_size_override("font_size", 14)
	panel.add_child(status)

	text = Label.new()
	text.position = Vector2(18, 76)
	text.size = Vector2(PANEL_SIZE.x - 36, PANEL_SIZE.y - 92)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 13)
	panel.add_child(text)

func _find_player() -> Node:
	var game := get_parent()
	if game == null:
		return null
	return game.get_node_or_null("Player")

func _run_diagnostics() -> void:
	var lines: Array[String] = []
	var errors := 0
	var warnings := 0

	var game := get_parent()
	_check(lines, "Main scene root", game != null, "Game root was not found.", errors, warnings)

	var player := _find_player()
	_check(lines, "Player node", player != null, "Game/Player does not exist.", errors, warnings)

	if player != null:
		_check(lines, "Player visible", player.visible, "Player.visible is false.", errors, warnings)
		_check(lines, "Player modulate", player.modulate.a > 0.01 and player.self_modulate.a > 0.01, "Player alpha/modulate is transparent.", errors, warnings)
		_check(lines, "Player z-index", player.z_index > -100, "Player z-index is extremely low and may be behind the world.", errors, warnings)
		_check(lines, "Player position", is_finite(player.position.x) and is_finite(player.position.y), "Player position contains NaN/Infinity.", errors, warnings)
		_check(lines, "Player script", player.get_script() != null, "Player has no attached script.", errors, warnings)

		var collision := player.get_node_or_null("CollisionShape2D")
		_check(lines, "Player collision", collision != null and collision.shape != null, "Player collision shape is missing.", errors, warnings)

		var camera := player.get_node_or_null("Camera")
		if camera == null:
			camera = player.get_node_or_null("Camera2D")
		_check(lines, "Camera", camera != null, "No Camera/Camera2D child found under Player.", errors, warnings)
		if camera != null:
			_check(lines, "Camera enabled", camera.enabled, "Camera exists but is disabled.", errors, warnings)

		var renderer_info := "Renderer: CharacterBody2D + _draw()"
		lines.append("[INFO] " + renderer_info)
		lines.append("[INFO] Player position: " + str(player.position))
		lines.append("[INFO] Player velocity: " + str(player.velocity))
		lines.append("[INFO] Player script: " + str(player.get_script()))

	# Confirm the main world objects expected by Level 01.
	_check(lines, "World", game.get_node_or_null("World") != null, "World node is missing.", errors, warnings)
	_check(lines, "Ground", game.get_node_or_null("World/Ground") != null, "World/Ground is missing.", errors, warnings)
	_check(lines, "Street pole", game.get_node_or_null("World/Level01/Environment/StreetPole_07") != null, "Street pole is missing.", errors, warnings)

	var ok := errors == 0
	status.text = ("STATUS: OK" if ok else "STATUS: ERRORS FOUND") + "    Errors: %d    Warnings: %d    [F9 = hide/show]" % [errors, warnings]
	text.text = "\n".join(lines)

	var report := status.text + "\n" + text.text
	if report != last_report:
		last_report = report
		print("\n========== DEBUG DIAGNOSTICS ==========")
		print(report)
		print("=======================================\n")

func _check(lines: Array[String], label: String, condition: bool, message: String, errors: int, warnings: int) -> void:
	# GDScript passes integers by value, so this helper intentionally only formats output.
	if condition:
		lines.append("[OK]    " + label)
	else:
		lines.append("[ERROR] " + label + " — " + message)

func is_finite(value: float) -> bool:
	return not is_nan(value) and not is_inf(value)
