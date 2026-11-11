extends Area2D

signal atingiu_personagem(corpo: Node2D)

## Arraste o CharacterBody2D principal na instância colocada na fase.
## Se ficar vazio, procura corpos pertencentes ao grupo jogador.
@export var personagem: CharacterBody2D
@export var grupo_personagem: StringName = &"jogador"
## Desative para tratar vidas/game over pelo sinal atingiu_personagem.
@export var reiniciar_fase_ao_tocar: bool = true

var _letal: bool = true
var _contato_processado: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 4294967295)
	set_deferred("monitoring", true)
	var colisao := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colisao == null:
		colisao = CollisionShape2D.new()
		colisao.name = "CollisionShape2D"
		add_child(colisao)
	if colisao.shape == null:
		var triangulo := ConvexPolygonShape2D.new()
		triangulo.points = PackedVector2Array([
			Vector2(-9, 9), Vector2(0, -9), Vector2(9, 9)
		])
		colisao.set_deferred("shape", triangulo)
	colisao.set_deferred("disabled", false)
	if not body_entered.is_connected(_ao_encostar):
		body_entered.connect(_ao_encostar)
	if not body_exited.is_connected(_ao_afastar):
		body_exited.connect(_ao_afastar)


func _physics_process(_delta: float) -> void:
	if not _letal or _contato_processado:
		return
	# Também detecta quem já estava dentro quando a pegadinha ficou letal.
	for corpo in get_overlapping_bodies():
		_ao_encostar(corpo)
		if _contato_processado:
			break


func _e_personagem(corpo: Node2D) -> bool:
	if is_instance_valid(personagem):
		return corpo == personagem
	return corpo is CharacterBody2D and corpo.is_in_group(grupo_personagem)


func _definir_letal(valor: bool) -> void:
	if _letal == valor:
		return
	_letal = valor
	if not valor:
		_contato_processado = false


func _ao_encostar(corpo: Node2D) -> void:
	if not _letal or _contato_processado or not _e_personagem(corpo):
		return
	# Vários espinhos lado a lado não devem reiniciar a mesma fase várias vezes.
	if bool(corpo.get_meta(&"ice_grim_reinicio_pendente", false)):
		return
	_contato_processado = true
	if reiniciar_fase_ao_tocar:
		corpo.set_meta(&"ice_grim_reinicio_pendente", true)
	atingiu_personagem.emit(corpo)
	if reiniciar_fase_ao_tocar:
		_reiniciar_fase.call_deferred(corpo)


func _ao_afastar(corpo: Node2D) -> void:
	if not reiniciar_fase_ao_tocar and _e_personagem(corpo):
		_contato_processado = false


func _reiniciar_fase(corpo: Node2D) -> void:
	var erro := get_tree().reload_current_scene()
	if erro != OK:
		_contato_processado = false
		if is_instance_valid(corpo):
			corpo.remove_meta(&"ice_grim_reinicio_pendente")
		push_error("Não foi possível reiniciar a fase. Execute uma cena salva. Código: %d" % erro)
