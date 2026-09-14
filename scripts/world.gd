extends Node2D
## TRY HACKING ME NOW — Star 3 world foundation.
## Level 01: assets visuais ficam definidos diretamente na cena.

var level_01_completed := false
var pole_path := NodePath("Level01/Environment/StreetPole_07")
const LEVEL_01_RIGHT_EXIT_X := 1040.0

func _ready() -> void:
	# As imagens já estão vinculadas aos Sprite2D da main.tscn.
	# Aqui apenas garantimos que os nós estejam visíveis e em frente/atrás na ordem correta.
	_setup_image_background()
	_setup_pole_image()
	_setup_left_boundary()

func _process(_delta: float) -> void:
	if level_01_completed:
		return
	var player := get_parent().get_node_or_null("Player")
	if player == null:
		return
	if player.global_position.x < LEVEL_01_RIGHT_EXIT_X:
		return
	if _pole_still_blocks_path():
		return
	level_01_completed = true
	var game := get_parent()
	if game and game.has_method("complete_level_01"):
		game.complete_level_01()

func _setup_image_background() -> void:
	var background := get_node_or_null("PaperBackground") as Sprite2D
	if background == null:
		push_error("[ASSET] PaperBackground não existe na cena.")
		return
	if background.texture == null:
		push_error("[ASSET] PaperBackground existe, mas está sem Texture2D.")
		return

	background.visible = true
	background.modulate = Color.WHITE
	background.z_as_relative = false
	background.z_index = -10
	print("[ASSET OK] PAPEL NA CENA: ", background.texture.get_size())

func _setup_pole_image() -> void:
	var pole := get_node_or_null(pole_path)
	if pole == null:
		push_error("[ASSET] StreetPole_07 não existe na cena.")
		return
	var sprite := pole.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		push_error("[ASSET] Sprite2D do poste não existe.")
		return
	if sprite.texture == null:
		push_error("[ASSET] Sprite2D do poste existe, mas está sem Texture2D.")
		return

	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.z_as_relative = false
	sprite.z_index = 20
	print("[ASSET OK] POSTE NA CENA: ", sprite.texture.get_size())

func _setup_left_boundary() -> void:
	var boundary := get_node_or_null("Level01/LeftBoundary") as StaticBody2D
	if boundary == null:
		push_error("[COLLISION] LeftBoundary não existe na cena.")
		return
	boundary.position = Vector2(25.0, 360.0)
	var shape := boundary.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = false
	print("[COLLISION OK] Barreira esquerda ativa em X=25")

func _pole_still_blocks_path() -> bool:
	var pole := get_node_or_null(pole_path)
	if pole == null:
		return false
	var shape := pole.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return shape != null and not shape.disabled
