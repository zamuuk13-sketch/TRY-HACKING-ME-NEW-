extends Node2D
## TRY HACKING ME NOW — Star 3 world foundation.
## Level 01 usa as PNGs do proprio projeto e garante tamanho/posição em runtime.

var level_01_completed := false
var pole_path := NodePath("Level01/Environment/StreetPole_07")
const LEVEL_01_RIGHT_EXIT_X := 1660.0

const PAPER_PATH := "res://imageens/papel.png"
const POLE_PATH := "res://imageens/poste (2).png"

func _ready() -> void:
	_setup_image_background()
	_setup_pole_image()
	queue_redraw()

func _process(_delta: float) -> void:
	if level_01_completed:
		return

	var player := get_parent().get_node_or_null("Player")
	if player == null:
		return

	# O jogador precisa realmente sair pelo lado direito.
	# O poste precisa ter sido removido ou ter a colisão desativada.
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
		push_error("PaperBackground não existe na cena.")
		return

	var texture := load(PAPER_PATH) as Texture2D
	if texture == null:
		push_error("Não foi possível carregar: " + PAPER_PATH)
		return

	background.texture = texture
	background.position = Vector2(800.0, 360.0)
	background.z_index = -100

	# Faz a folha ocupar praticamente toda a área da fase,
	# independentemente da resolução original do PNG.
	var image_size := texture.get_size()
	if image_size.x > 0.0 and image_size.y > 0.0:
		background.scale = Vector2(1800.0 / image_size.x, 720.0 / image_size.y)

	print("[ASSET] Papel carregado: ", PAPER_PATH, " | tamanho: ", image_size)

func _setup_pole_image() -> void:
	var pole := get_node_or_null(pole_path)
	if pole == null:
		push_error("StreetPole_07 não existe na cena.")
		return

	var sprite := pole.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		push_error("Sprite2D do StreetPole_07 não existe.")
		return

	var texture := load(POLE_PATH) as Texture2D
	if texture == null:
		push_error("Não foi possível carregar: " + POLE_PATH)
		return

	sprite.texture = texture
	sprite.position = Vector2.ZERO

	# Mantém o poste em um tamanho visível e proporcional.
	# O PNG pode ter qualquer resolução original.
	var image_size := texture.get_size()
	if image_size.x > 0.0 and image_size.y > 0.0:
		var target_height := 190.0
		var uniform_scale := target_height / image_size.y
		sprite.scale = Vector2(uniform_scale, uniform_scale)

	print("[ASSET] Poste carregado: ", POLE_PATH, " | tamanho: ", image_size, " | escala: ", sprite.scale)

func _pole_still_blocks_path() -> bool:
	var pole := get_node_or_null(pole_path)
	if pole == null:
		return false
	var shape := pole.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return shape != null and not shape.disabled

func _draw() -> void:
	# Os visuais principais são os PNGs carregados acima.
	pass
