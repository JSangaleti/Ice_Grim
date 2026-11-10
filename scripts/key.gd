extends Area2D

signal coletada

# Use o mesmo identificador na chave e na porta correspondente.
@export var id_chave: StringName = &"principal"
@export var grupo_personagem: StringName = &"jogador"

var _foi_coletada: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_ao_corpo_entrar):
		body_entered.connect(_ao_corpo_entrar)


func _ao_corpo_entrar(corpo: Node2D) -> void:
	if _foi_coletada or not corpo.is_in_group(grupo_personagem):
		return

	_foi_coletada = true
	# Guarda a posse no próprio personagem, sem alterar seu script de movimento.
	var chaves: Dictionary = corpo.get_meta(&"chaves_coletadas", {})
	chaves[id_chave] = true
	corpo.set_meta(&"chaves_coletadas", chaves)
	hide()
	coletada.emit()
	queue_free()
