extends CharacterBody2D

signal atingiu_personagem(corpo: Node2D)

@export var velocidade: float = 85.0
@export var forca_pulo: float = 260.0
@export var gravidade: float = 1000.0
## Distância máxima para CADA lado da posição inicial, em pixels.
@export var alcance_patrulha: float = 120.0
@export var pausa_entre_pulos: float = 0.25
@export var iniciar_para_direita: bool = true
## Camadas em que estão o chão e as paredes. Por padrão, camada 1.
@export_flags_2d_physics var camadas_cenario: int = 1
## Arraste o CharacterBody2D principal, na instância colocada na fase.
## Vazio: identifica o personagem pelo grupo jogador.
@export var personagem: CharacterBody2D
@export var grupo_personagem: StringName = &"jogador"
## Desative para tratar vidas/game over pelo sinal atingiu_personagem.
@export var reiniciar_fase_ao_tocar: bool = true
@export var animacao: StringName = &"default"

var _direcao: float = 1.0
var _limite_esquerdo: float
var _limite_direito: float
var _pausa: float = 0.0
var _estava_no_chao: bool = false
var _contato_processado: bool = false
var _sprite_animado: AnimatedSprite2D
var _sprite_simples: Sprite2D


func _ready() -> void:
	_direcao = 1.0 if iniciar_para_direita else -1.0
	_limite_esquerdo = global_position.x - maxf(alcance_patrulha, 0.0)
	_limite_direito = global_position.x + maxf(alcance_patrulha, 0.0)
	floor_snap_length = 4.0
	# A geleia ocupa a camada 3; chão e paredes são definidos acima.
	set_deferred("collision_layer", 4)
	set_deferred("collision_mask", camadas_cenario)
	var colisao := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null:
		colisao = CollisionShape2D.new()
		colisao.name = "CollisionShape2D"
		add_child(colisao)
	if colisao.shape == null:
		var retangulo := RectangleShape2D.new()
		retangulo.size = Vector2(24.0, 20.0)
		colisao.position = Vector2(0.0, -10.0)
		colisao.shape = retangulo
	colisao.set_deferred("disabled", false)
	_configurar_area_dano(colisao)
	_sprite_animado = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_sprite_simples = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite_animado != null and _sprite_animado.sprite_frames != null:
		if _sprite_animado.sprite_frames.has_animation(animacao):
			_sprite_animado.play(animacao)
	_atualizar_visual()


func _configurar_area_dano(colisao_corpo: CollisionShape2D) -> void:
	var area := get_node_or_null("AreaDano") as Area2D
	if area == null:
		area = Area2D.new()
		area.name = "AreaDano"
		add_child(area)
	area.set_deferred("collision_layer", 0)
	area.set_deferred("collision_mask", 4294967295)
	area.set_deferred("monitoring", true)
	var forma := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if forma == null:
		forma = CollisionShape2D.new()
		forma.name = "CollisionShape2D"
		area.add_child(forma)
	if forma.shape == null:
		forma.shape = colisao_corpo.shape.duplicate() as Shape2D
		forma.transform = colisao_corpo.transform
		# Um pouco maior para detectar o toque antes de virar apoio sólido.
		forma.scale *= 1.15
	forma.set_deferred("disabled", false)
	if not area.body_entered.is_connected(_ao_encostar):
		area.body_entered.connect(_ao_encostar)
	if not area.body_exited.is_connected(_ao_afastar):
		area.body_exited.connect(_ao_afastar)


func _physics_process(delta: float) -> void:
	if global_position.x <= _limite_esquerdo:
		_direcao = 1.0
	elif global_position.x >= _limite_direito:
		_direcao = -1.0

	var no_chao := is_on_floor()
	if no_chao:
		velocity = Vector2.ZERO
		if not _estava_no_chao:
			_pausa = maxf(pausa_entre_pulos, 0.0)
		_pausa = maxf(_pausa - delta, 0.0)
		if _pausa <= 0.0:
			velocity = Vector2(_direcao * velocidade, -maxf(forca_pulo, 1.0))
	else:
		velocity.x = _direcao * velocidade
		velocity.y = minf(velocity.y + gravidade * delta, 900.0)
	_estava_no_chao = no_chao
	move_and_slide()
	if is_on_wall():
		_direcao *= -1.0
	# Impede que a patrulha ultrapasse os limites, mesmo durante o salto.
	if global_position.x < _limite_esquerdo:
		global_position.x = _limite_esquerdo
		_direcao = 1.0
	elif global_position.x > _limite_direito:
		global_position.x = _limite_direito
		_direcao = -1.0
	_atualizar_visual()


func _atualizar_visual() -> void:
	if _sprite_animado != null:
		_sprite_animado.flip_h = _direcao < 0.0
	if _sprite_simples != null:
		_sprite_simples.flip_h = _direcao < 0.0


func _e_personagem(corpo: Node2D) -> bool:
	if is_instance_valid(personagem):
		return corpo == personagem
	return corpo is CharacterBody2D and corpo.is_in_group(grupo_personagem)


func _ao_encostar(corpo: Node2D) -> void:
	if _contato_processado or not _e_personagem(corpo):
		return
	_contato_processado = true
	atingiu_personagem.emit(corpo)
	if reiniciar_fase_ao_tocar:
		set_physics_process(false)
		_reiniciar_fase.call_deferred()


func _ao_afastar(corpo: Node2D) -> void:
	if not reiniciar_fase_ao_tocar and _e_personagem(corpo):
		_contato_processado = false


func _reiniciar_fase() -> void:
	var erro := get_tree().reload_current_scene()
	if erro != OK:
		_contato_processado = false
		set_physics_process(true)
		push_error("Não foi possível reiniciar a fase. Execute uma cena salva. Código: %d" % erro)
