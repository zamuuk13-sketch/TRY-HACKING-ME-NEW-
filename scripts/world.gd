extends Node2D
## TRY HACKING ME NOW — Star 3 world foundation.
## Level 01: fase ainda mais compacta, câmera mais próxima e poste PNG sem fundo.

var level_01_completed := false
var pole_path := NodePath("Level01/Environment/StreetPole_07")
const LEVEL_01_RIGHT_EXIT_X := 1040.0
const PAPER_PATH := "res://imageens/papel.png"
const POLE_PATH := "res://imageens/poste sem fundo.png"
const LEVEL_WIDTH := 1100.0
const LEVEL_HEIGHT := 720.0

func _ready() -> void:
	_setup_image_background()
	_setup_pole_image()
	_setup_left_boundary()
	queue_redraw()

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

func _load_texture(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture != null:
		return texture
	var absolute_path := ProjectSettings.globalize_path(path)
	var image := Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		push_error("[ASSET] Falha ao carregar imagem: " + path)
		return null
	return ImageTexture.create_from_image(image)

func _setup_image_background() -> void:
	var background := get_node_or_null("PaperBackground") as Sprite2D
	if background == null:
		push_error("[ASSET] PaperBackground não existe na cena.")
		return
	var texture := _load_texture(PAPER_PATH)
	if texture == null:
		return
	background.texture = texture
	background.position = Vector2(550.0, 360.0)
	background.z_index = -100
	background.visible = true
	background.modulate = Color.WHITE
	var image_size := texture.get_size()
	if image_size.x > 0.0 and image_size.y > 0.0:
		background.scale = Vector2(LEVEL_WIDTH / image_size.x, LEVEL_HEIGHT / image_size.y)
	print("[ASSET OK] PAPEL: ", PAPER_PATH, " | ", image_size, " | escala ", background.scale)

func _setup_pole_image() -> void:
	var pole := get_node_or_null(pole_path)
	if pole == null:
		push_error("[ASSET] StreetPole_07 não existe na cena.")
		return
	var sprite := pole.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		push_error("[ASSET] Sprite2D do poste não existe.")
		return
	var texture := _load_texture(POLE_PATH)
	if texture == null:
		return
	sprite.texture = texture
	sprite.visible = true
	sprite.modulate = Color.WHITE
	sprite.z_index = 10
	var image_size := texture.get_size()
	if image_size.x > 0.0 and image_size.y > 0.0:
		# Altura visual aproximada do personagem, sem alterar a largura manualmente.
		var target_height := 84.0
		sprite.scale = Vector2.ONE * (target_height / image_size.y)
	print("[ASSET OK] POSTE: ", POLE_PATH, " | ", image_size, " | altura ", target_height, " | escala ", sprite.scale)

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

func _draw() -> void:
	pass
