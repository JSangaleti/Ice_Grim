extends CanvasLayer

@onready var _tentativas: Label = %Tentativas
@onready var _tempo: Label = %Tempo
@onready var _chaves_restantes: Label = %ChavesRestantes
@onready var _objetivo_titulo: Label = %ObjetivoTitulo
@onready var _contador_chaves: HBoxContainer = %ContadorChaves
@onready var _indicador_saida: HBoxContainer = %IndicadorSaida


func _ready() -> void:
	GerenciadorPartida.dados_alterados.connect(_atualizar_contadores)
	GerenciadorPartida.tempo_alterado.connect(_atualizar_tempo)
	_atualizar_contadores()
	_atualizar_tempo(int(GerenciadorPartida.tempo_decorrido))
	_iniciar_fase.call_deferred()


func _iniciar_fase() -> void:
	GerenciadorPartida.iniciar_fase(get_tree().current_scene)


func _atualizar_contadores() -> void:
	_tentativas.text = str(GerenciadorPartida.tentativas)
	_chaves_restantes.text = str(GerenciadorPartida.chaves_restantes)
	var saida_liberada := GerenciadorPartida.pode_sair()
	_contador_chaves.visible = not saida_liberada
	_indicador_saida.visible = saida_liberada
	_objetivo_titulo.text = "HORA DE IR EMBORA" if saida_liberada else "CHAVES RESTANTES"


func _atualizar_tempo(segundos: int) -> void:
	var minutos := floori(float(segundos) / 60.0)
	_tempo.text = "%02d:%02d" % [minutos, segundos % 60]
