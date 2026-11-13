extends Area2D

signal trancada

@export var id_chave: StringName = &"principal"
@export var grupo_personagem: StringName = &"jogador"
## Arraste o mesmo CharacterBody2D indicado na chave. Vazio: usa o grupo.
@export var personagem: CharacterBody2D

@export_group("Efeitos sonoros")
@export var som_trancada: AudioStream = preload("res://assets/sfx/locked.mp3")

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

func _ao_corpo_entrar(corpo: Node2D) -> void:
	if _e_personagem(corpo):
		if som_trancada != null:
			AudioManager.play_sfx(som_trancada)
		trancada.emit()
	return


func _e_personagem(corpo: Node2D) -> bool:
	if is_instance_valid(personagem):
		return corpo == personagem
	return corpo is CharacterBody2D and corpo.is_in_group(grupo_personagem)
