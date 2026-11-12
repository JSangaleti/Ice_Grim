extends Area2D

signal coletada

# Use o mesmo identificador na chave e na porta correspondente.
@export var id_chave: StringName = &"principal"
@export var grupo_personagem: StringName = &"jogador"
## Arraste o CharacterBody2D da fase. Vazio: usa o grupo jogador.
@export var personagem: CharacterBody2D
@export var amplitude_flutuacao: float = 6.0
@export var ciclos_por_segundo: float = 1.2
@export var inclinacao_graus: float = 6.0

var _foi_coletada: bool = false
var _tempo: float = 0.0
var _sprite: Sprite2D
var _posicao_base: Vector2
var _rotacao_base: float = 0.0


func _ready() -> void:
	# Detecta corpos em qualquer camada; a identidade é filtrada abaixo.
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 4294967295)
	set_deferred("monitoring", true)
	var colisao := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null:
		colisao = CollisionShape2D.new()
		colisao.name = "CollisionShape2D"
		add_child(colisao)
	if colisao.shape == null:
		var circulo := CircleShape2D.new()
		circulo.radius = 16.0
		colisao.set_deferred("shape", circulo)
	colisao.set_deferred("disabled", false)
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null:
		_posicao_base = _sprite.position
		_rotacao_base = _sprite.rotation
	if not body_entered.is_connected(_ao_corpo_entrar):
		body_entered.connect(_ao_corpo_entrar)


func _process(delta: float) -> void:
	if _sprite == null or _foi_coletada:
		return
	_tempo += delta
	var onda := sin(_tempo * TAU * ciclos_por_segundo)
	_sprite.position = _posicao_base + Vector2(0.0, onda * amplitude_flutuacao)
	_sprite.rotation = _rotacao_base + onda * deg_to_rad(inclinacao_graus)


func _e_personagem(corpo: Node2D) -> bool:
	if is_instance_valid(personagem):
		return corpo == personagem
	return corpo is CharacterBody2D and corpo.is_in_group(grupo_personagem)


func _ao_corpo_entrar(corpo: Node2D) -> void:
	if _foi_coletada or not _e_personagem(corpo):
		return

	_foi_coletada = true
	# Guarda a posse no próprio personagem, sem alterar seu script de movimento.
	var chaves: Dictionary = corpo.get_meta(&"chaves_coletadas", {})
	chaves[id_chave] = true
	corpo.set_meta(&"chaves_coletadas", chaves)
	hide()
	coletada.emit()
	queue_free()
