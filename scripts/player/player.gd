extends CharacterBody2D

@export var velocidade_andando: float = 175.0
@export var velocidade_correndo: float = 260.0
@export var forca_pulo: float = 470.0
@export var gravidade: float = 1250.0
@export var velocidade_maxima_queda: float = 760.0
@export var velocidade_dash: float = 520.0
@export var duracao_dash: float = 0.15
@export var intervalo_dash: float = 0.35

@export_group("Efeitos sonoros")
@export var som_pulo: AudioStream = preload("res://assets/sfx/jump.mp3")
@export var som_dash: AudioStream = preload("res://assets/sfx/dash.mp3")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direcao: float = 1.0
var _direcao_dash: float = 1.0
var _tempo_dash: float = 0.0
var _recarga_dash: float = 0.0
var _dash_disponivel: bool = true
var _pedido_dash: bool = false
var _espera_dash: float = 0.0


func _ready() -> void:
	# As animações direcionais já possuem os quadros para cada lado.
	sprite.flip_h = false
	sprite.play(&"default")


func _physics_process(delta: float) -> void:
	_recarga_dash = maxf(0.0, _recarga_dash - delta)
	var eixo := Input.get_axis(&"esquerda", &"direita")
	var correndo := Input.is_action_pressed(&"correr")
	if _tempo_dash <= 0.0:
		if is_on_floor():
			_dash_disponivel = true
		if eixo != 0.0:
			direcao = signf(eixo)

		var velocidade := velocidade_correndo if correndo else velocidade_andando
		velocity.x = eixo * velocidade
		if is_on_floor():
			velocity.y = 0.0
		else:
			velocity.y = minf(velocity.y + gravidade * delta, velocidade_maxima_queda)

		var pulou := Input.is_action_just_pressed(&"pular") and is_on_floor()
		if pulou:
			velocity.y = -forca_pulo
			if som_pulo != null:
				AudioManager.play_sfx(som_pulo)

		if Input.is_action_just_pressed(&"dash") and _dash_disponivel and _recarga_dash <= 0.0:
			_pedido_dash = true
			# Se pulo e dash forem apertados juntos, deixa o pulo sair do chão.
			_espera_dash = 0.05 if pulou else 0.0
		elif _pedido_dash:
			_espera_dash = maxf(0.0, _espera_dash - delta)

		if _pedido_dash and _espera_dash <= 0.0:
			_iniciar_dash()

	var em_dash := _tempo_dash > 0.0
	if em_dash:
		velocity = Vector2(_direcao_dash * velocidade_dash, 0.0)
		_tempo_dash = maxf(0.0, _tempo_dash - delta)

	move_and_slide()
	_atualizar_animacao(em_dash, correndo)


func _iniciar_dash() -> void:
	_pedido_dash = false
	_dash_disponivel = false
	_direcao_dash = direcao
	_tempo_dash = maxf(duracao_dash, 0.01)
	_recarga_dash = maxf(intervalo_dash, 0.0)
	if som_dash != null:
		AudioManager.play_sfx(som_dash)


func _atualizar_animacao(em_dash: bool, correndo: bool) -> void:
	var animacao: StringName
	var lado := "direita" if direcao > 0.0 else "esquerda"
	sprite.flip_h = false
	sprite.speed_scale = 1.0

	if em_dash:
		animacao = StringName("dash_" + lado)
	elif not is_on_floor():
		if velocity.y < 0.0:
			animacao = StringName("pulando_" + lado)
		else:
			animacao = &"caindo"
			sprite.flip_h = direcao < 0.0
	elif absf(velocity.x) > 0.1:
		animacao = StringName("andando_" + lado)
		# Correr usa os quadros de andar, reproduzidos mais rapidamente.
		if correndo:
			sprite.speed_scale = velocidade_correndo / maxf(velocidade_andando, 1.0)
	else:
		animacao = &"default"
		sprite.flip_h = direcao < 0.0

	if sprite.animation != animacao:
		sprite.play(animacao)
