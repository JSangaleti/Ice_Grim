extends Node

signal morreu_por_queda

## Coordenada Y global abaixo da qual o personagem morre.
## Na Godot, valores maiores de Y ficam mais para baixo.
@export var limite_y: float = 900.0
## Opcional: um Marker2D na fase substitui o valor Limite Y.
## O marcador deve ficar fora do Player, para não acompanhar sua queda.
@export var marcador_limite: Marker2D

@onready var _player: CharacterBody2D = get_parent() as CharacterBody2D

var _morreu: bool = false


func _ready() -> void:
	if _player == null:
		push_error("MortePorQueda deve ser um nó filho direto do CharacterBody2D do jogador.")
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if _morreu or not is_instance_valid(_player):
		return
	# Evita duplicar um reinício que já foi pedido por um espinho.
	if bool(_player.get_meta(&"ice_grim_reinicio_pendente", false)):
		return
	var altura_limite := marcador_limite.global_position.y if is_instance_valid(marcador_limite) else limite_y
	if _player.global_position.y > altura_limite:
		_morreu = true
		_player.set_meta(&"ice_grim_reinicio_pendente", true)
		_player.velocity = Vector2.ZERO
		_player.set_physics_process(false)
		morreu_por_queda.emit()
		_reiniciar_fase.call_deferred()


func _reiniciar_fase() -> void:
	var erro := get_tree().reload_current_scene()
	if erro != OK:
		# Impede tentativas e mensagens de erro repetidas a cada quadro.
		set_physics_process(false)
		_morreu = false
		if is_instance_valid(_player):
			_player.remove_meta(&"ice_grim_reinicio_pendente")
			_player.set_physics_process(true)
		push_error("Não foi possível reiniciar a fase. Execute uma cena salva (.tscn). Código: %d" % erro)
