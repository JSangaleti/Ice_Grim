extends Area2D

signal aberta
signal trancada

@export var id_chave: StringName = &"principal"
@export var grupo_personagem: StringName = &"jogador"
## Arraste o mesmo CharacterBody2D indicado na chave. Vazio: usa o grupo.
@export var personagem: CharacterBody2D
@export var consumir_chave: bool = true
# Arraste a cena da próxima fase para este campo no Inspetor.
# Se ficar vazio, a porta emite "aberta" sem trocar a cena.
@export var proxima_fase: PackedScene

var _foi_aberta: bool = false


func _ready() -> void:
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 4294967295)
	set_deferred("monitoring", true)
	var colisao := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null:
		colisao = CollisionShape2D.new()
		colisao.name = "CollisionShape2D"
		add_child(colisao)
	if colisao.shape == null:
		var retangulo := RectangleShape2D.new()
		retangulo.size = Vector2(32.0, 44.0)
		colisao.set_deferred("shape", retangulo)
	colisao.set_deferred("disabled", false)
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
	if _foi_aberta or not _e_personagem(corpo):
		return
	if not _possui_chave(corpo):
		trancada.emit()
		return
	_tentar_abrir(corpo)


func _e_personagem(corpo: Node2D) -> bool:
	if is_instance_valid(personagem):
		return corpo == personagem
	return corpo is CharacterBody2D and corpo.is_in_group(grupo_personagem)


func _possui_chave(corpo: Node2D) -> bool:
	var chaves: Dictionary = corpo.get_meta(&"chaves_coletadas", {})
	return bool(chaves.get(id_chave, false))


func _tentar_abrir(corpo: Node2D) -> void:
	if _foi_aberta or not _e_personagem(corpo) or not _possui_chave(corpo):
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
	var imagem := get_node_or_null("Sprite2D") as Sprite2D
	if imagem != null:
		imagem.self_modulate = Color("a9ffd3")
	aberta.emit()
