extends Area2D

signal aberta
signal trancada

@export var id_chave: StringName = &"principal"
@export var grupo_personagem: StringName = &"jogador"
@export var consumir_chave: bool = true
# Arraste a cena da próxima fase para este campo no Inspetor.
# Se ficar vazio, a porta emite "aberta" sem trocar a cena.
@export var proxima_fase: PackedScene

var _foi_aberta: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_ao_corpo_entrar):
		body_entered.connect(_ao_corpo_entrar)


func _physics_process(_delta: float) -> void:
	if _foi_aberta:
		return
	# Também funciona se a chave for coletada com o personagem já na porta.
	for corpo in get_overlapping_bodies():
		_tentar_abrir(corpo)
		if _foi_aberta:
			break


func _ao_corpo_entrar(corpo: Node2D) -> void:
	if _foi_aberta or not corpo.is_in_group(grupo_personagem):
		return
	if not _possui_chave(corpo):
		trancada.emit()
		return
	_tentar_abrir(corpo)


func _possui_chave(corpo: Node2D) -> bool:
	var chaves: Dictionary = corpo.get_meta(&"chaves_coletadas", {})
	return bool(chaves.get(id_chave, false))


func _tentar_abrir(corpo: Node2D) -> void:
	if _foi_aberta or not corpo.is_in_group(grupo_personagem) or not _possui_chave(corpo):
		return
	_foi_aberta = true
	# A troca de cena acontece fora da atualização das colisões.
	_abrir.call_deferred(corpo)


func _abrir(corpo: Node2D) -> void:
	if not is_instance_valid(corpo) or not _possui_chave(corpo):
		_foi_aberta = false
		return

	if proxima_fase != null:
		var erro := get_tree().change_scene_to_packed(proxima_fase)
		if erro != OK:
			_foi_aberta = false
			push_error("Não foi possível abrir a próxima fase. Código: %d" % erro)
			return

	if consumir_chave:
		var chaves: Dictionary = corpo.get_meta(&"chaves_coletadas", {})
		chaves.erase(id_chave)
		corpo.set_meta(&"chaves_coletadas", chaves)
	aberta.emit()
