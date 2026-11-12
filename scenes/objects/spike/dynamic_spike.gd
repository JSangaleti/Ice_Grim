extends "espinho.gd"

signal ativado

## Aproximação horizontal, em pixels do mundo, para disparar a armadilha.
@export var distancia_ativacao: float = 64.0
## Evita disparar só porque alguém passou muito acima ou abaixo do espinho.
@export var alcance_vertical: float = 56.0
@export var tempo_subida: float = 0.12

var _disparado: bool = false
var _tempo: float = 0.0
var _sprite: Sprite2D
var _posicao_base: Vector2
var _escala_base: Vector2
var _borda_inferior: float = 0.0


func _ready() -> void:
	_definir_letal(false)
	super._ready()
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null or _sprite.texture == null:
		push_error("Espinho de pegadinha precisa de um filho Sprite2D com textura.")
		set_physics_process(false)
		return
	_posicao_base = _sprite.position
	_escala_base = _sprite.scale
	_borda_inferior = _sprite.get_rect().end.y * _escala_base.y
	_mostrar_subida(0.0)


func _physics_process(delta: float) -> void:
	if not _disparado:
		_verificar_aproximacao()
	if _disparado:
		_tempo += delta
		var progresso := clampf(_tempo / maxf(tempo_subida, 0.01), 0.0, 1.0)
		_mostrar_subida(progresso)
		# Não mata enquanto escondido ou parcialmente erguido.
		_definir_letal(progresso >= 1.0)
	super._physics_process(delta)


func _verificar_aproximacao() -> void:
	if is_instance_valid(personagem):
		if _esta_perto(personagem):
			_disparar()
		return
	for corpo in get_tree().get_nodes_in_group(grupo_personagem):
		if corpo is CharacterBody2D and _esta_perto(corpo):
			_disparar()
			break


func _esta_perto(corpo: Node2D) -> bool:
	var diferenca := corpo.global_position - global_position
	return absf(diferenca.x) <= maxf(distancia_ativacao, 0.0) and absf(diferenca.y) <= maxf(alcance_vertical, 0.0)


func _disparar() -> void:
	_disparado = true
	ativado.emit()


func _mostrar_subida(progresso: float) -> void:
	_sprite.visible = progresso > 0.0
	# A base permanece no chão: somente a imagem cresce de baixo para cima.
	_sprite.scale = Vector2(_escala_base.x, _escala_base.y * maxf(progresso, 0.001))
	_sprite.position = _posicao_base + Vector2(0.0, _borda_inferior * (1.0 - progresso))
