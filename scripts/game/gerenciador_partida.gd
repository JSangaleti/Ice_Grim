extends Node
## Mantém as tentativas entre reinícios e acompanha os objetivos da fase atual.

signal dados_alterados
signal tempo_alterado(segundos: int)

var tentativas: int = 1
var tempo_decorrido: float = 0.0
var chaves_totais: int = 0
var chaves_restantes: int = 0
var fase_pronta: bool = false

var _fase: Node
var _chaves_pendentes: Dictionary = {}
var _em_andamento: bool = false
var _reinicio_pendente: bool = false
var _ultimo_segundo: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _process(delta: float) -> void:
	if not _em_andamento:
		return
	if not is_instance_valid(_fase):
		_em_andamento = false
		fase_pronta = false
		return
	tempo_decorrido += delta
	var segundos := int(tempo_decorrido)
	if segundos != _ultimo_segundo:
		_ultimo_segundo = segundos
		tempo_alterado.emit(segundos)


func iniciar_fase(fase: Node) -> void:
	if not is_instance_valid(fase):
		return
	if is_instance_valid(_fase) and _fase == fase:
		return
	_fase = fase
	fase_pronta = false
	_chaves_pendentes.clear()
	for chave in get_tree().get_nodes_in_group(&"chaves_reais"):
		if not fase.is_ancestor_of(chave) or not chave.has_signal(&"coletada"):
			continue
		var identificador := chave.get_instance_id()
		_chaves_pendentes[identificador] = true
		chave.connect(&"coletada", _ao_coletar_chave.bind(identificador), CONNECT_ONE_SHOT)
	chaves_totais = _chaves_pendentes.size()
	chaves_restantes = chaves_totais
	tempo_decorrido = 0.0
	_ultimo_segundo = 0
	_reinicio_pendente = false
	fase_pronta = true
	_em_andamento = true
	dados_alterados.emit()
	tempo_alterado.emit(0)


func pode_sair() -> bool:
	return (
		fase_pronta
		and is_instance_valid(_fase)
		and _fase == get_tree().current_scene
		and not _reinicio_pendente
		and chaves_restantes == 0
	)


func concluir_fase() -> void:
	_em_andamento = false


func reiniciar_fase() -> Error:
	if _reinicio_pendente:
		return ERR_BUSY
	_reinicio_pendente = true
	var erro := get_tree().reload_current_scene()
	if erro != OK:
		_reinicio_pendente = false
		return erro
	tentativas += 1
	_em_andamento = false
	fase_pronta = false
	dados_alterados.emit()
	return OK


func _ao_coletar_chave(identificador: int) -> void:
	# Cada objeto conta uma vez, mesmo quando várias chaves usam o mesmo Id Chave.
	if not _chaves_pendentes.has(identificador):
		return
	_chaves_pendentes.erase(identificador)
	chaves_restantes = _chaves_pendentes.size()
	dados_alterados.emit()
