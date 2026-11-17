extends SceneTree
## Execute: godot --headless --path . --script res://tests/test_hud.gd
## Sem --headless, acrescente -- --capturas para salvar prévias em /tmp/ice-grim-hud.

var _partida: Node
var _falhas: int = 0


func _initialize() -> void:
	_executar.call_deferred()


func _executar() -> void:
	_partida = root.get_node("GerenciadorPartida")
	# O tempo avança explicitamente nos testes para evitar depender da velocidade da máquina.
	_partida.set_process(false)
	await _testar_fases_e_mortes()
	await _testar_coletas_e_saida()
	await _testar_fase_sem_chaves()
	current_scene.free()
	await _aguardar_cena()
	if _falhas == 0:
		print("HUD OK: contadores, chaves falsas, múltiplas chaves, saída, mortes, pausa e câmera.")
	else:
		push_error("HUD: %d verificações falharam." % _falhas)
	quit(0 if _falhas == 0 else 1)


func _testar_fases_e_mortes() -> void:
	_verificar(change_scene_to_file("res://scenes/levels/level_01.tscn") == OK, "Carregar fase 1")
	await _aguardar_cena()
	current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	var hud := current_scene.get_node("Player/HUD")
	_verificar(_partida.get("tentativas") == 1, "A primeira tentativa começa em 1")
	_verificar(_partida.get("chaves_restantes") == 1, "A chave da fase 1 é contada")
	_verificar(hud.get_node("%Tentativas").text == "1", "Tentativas aparecem no HUD")
	_verificar(not hud.get_node("%IndicadorSaida").visible, "A saída começa escondida")
	_partida.call("_process", 65.9)
	_verificar(hud.get_node("%Tempo").text == "01:05", "O tempo usa minutos e segundos")
	await _capturar("hud-chaves.png")

	var tempo_antes: float = _partida.get("tempo_decorrido")
	paused = true
	_partida.set_process(true)
	await create_timer(0.05).timeout
	paused = false
	_partida.set_process(false)
	_verificar(_partida.get("tempo_decorrido") == tempo_antes, "Pausar o jogo pausa o cronômetro")

	var jogador := current_scene.get_node("Player")
	current_scene.get_node("Key").call("_ao_corpo_entrar", jogador)
	_verificar(_partida.get("chaves_restantes") == 0, "Coletar a chave atualiza o objetivo")
	_verificar(hud.get_node("%IndicadorSaida").visible, "A coleta final mostra a saída")
	await _capturar("hud-saida.png")
	current_scene.get_node("Door").call("_ao_corpo_entrar", jogador)
	await _aguardar_cena()
	_verificar(current_scene.scene_file_path.ends_with("level_02.tscn"), "A porta leva à fase 2")
	_verificar(_partida.get("tentativas") == 1, "Trocar de fase preserva as tentativas")
	_verificar(_partida.get("tempo_decorrido") == 0.0, "Trocar de fase reinicia o tempo")
	_verificar(_partida.get("chaves_restantes") == 1, "A fase 2 reconta suas próprias chaves")

	for perigo in ["EspinhoFixo", "EspinhoPegadinha", "Enemy01", "Player/MortePorQueda"]:
		current_scene.process_mode = Node.PROCESS_MODE_DISABLED
		jogador = current_scene.get_node("Player")
		var tentativas_antes: int = _partida.get("tentativas")
		_partida.call("_process", 12.0)
		var origem := current_scene.get_node(perigo)
		if perigo == "Player/MortePorQueda":
			jogador.position.y = origem.get("limite_y") + 1.0
			origem.call("_physics_process", 0.0)
		else:
			if perigo == "EspinhoPegadinha":
				origem.call("_definir_letal", true)
			origem.call("_ao_encostar", jogador)
		# Outro perigo no mesmo quadro deve respeitar a proteção contra mortes duplicadas.
		current_scene.get_node("Enemy07").call("_ao_encostar", jogador)
		await _aguardar_cena()
		_verificar(_partida.get("tentativas") == tentativas_antes + 1, "Uma tentativa por morte: " + perigo)
		_verificar(_partida.get("tempo_decorrido") == 0.0, "O tempo reinicia após: " + perigo)
		_verificar(_partida.get("chaves_restantes") == 1, "As chaves reaparecem após: " + perigo)
		var texto: String = current_scene.get_node("Player/HUD/%Tentativas").text
		_verificar(texto == str(tentativas_antes + 1), "O HUD acompanha a nova tentativa")

	var tentativas_antes: int = _partida.get("tentativas")
	change_scene_to_file("res://scenes/levels/level_01.tscn")
	await _aguardar_cena()
	current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	current_scene.get_node("Enemy01").call("_ao_encostar", current_scene.get_node("Player"))
	await _aguardar_cena()
	_verificar(_partida.get("tentativas") == tentativas_antes + 1, "O slime da fase 1 também registra a morte")


func _testar_coletas_e_saida() -> void:
	var fase := _criar_cenario(2)
	await _aguardar_cena()
	var jogador := fase.get_node("Player")
	var hud := jogador.get_node("HUD")
	var chave_a := fase.get_node("Chave0")
	var chave_b := fase.get_node("Chave1")
	var porta := fase.get_node("Door")
	_verificar(_partida.get("chaves_totais") == 2, "Duas chaves com o mesmo ID contam separadamente")
	_verificar(not porta.call("_pode_abrir", jogador), "A porta fica trancada com chaves pendentes")
	fase.get_node("FakeKey").call("_ao_corpo_entrar", jogador)
	_verificar(_partida.get("chaves_restantes") == 2, "A chave falsa não altera o contador")
	_verificar(not jogador.has_meta(&"chaves_coletadas"), "A chave falsa não concede posse")

	var outro_corpo := CharacterBody2D.new()
	chave_a.call("_ao_corpo_entrar", outro_corpo)
	_verificar(_partida.get("chaves_restantes") == 2, "Outros corpos não coletam chaves")
	outro_corpo.free()
	chave_a.call("_ao_corpo_entrar", jogador)
	chave_a.call("_ao_corpo_entrar", jogador)
	_verificar(_partida.get("chaves_restantes") == 1, "Uma chave conta apenas uma vez")
	_verificar(hud.get_node("%ChavesRestantes").text == "1", "O HUD exibe a quantidade restante")
	_verificar(not porta.call("_pode_abrir", jogador), "Uma chave não libera a porta quando ainda falta outra")
	chave_b.call("_ao_corpo_entrar", jogador)
	_verificar(_partida.call("pode_sair"), "Todas as chaves liberam o objetivo")
	_verificar(porta.call("_pode_abrir", jogador), "Todas as chaves liberam a porta")
	_verificar(hud.get_node("%IndicadorSaida").visible, "O símbolo de saída aparece")
	_verificar(not hud.get_node("%ContadorChaves").visible, "O símbolo substitui o contador")

	fase.get_node("FakeDoor").call("_ao_corpo_entrar", jogador)
	_partida.call("_process", 2.0)
	_verificar(_partida.get("tempo_decorrido") == 2.0, "A porta falsa não encerra o tempo")
	var layout := hud.get_node("Layout") as Control
	var posicao_hud := layout.get_global_transform_with_canvas().origin
	jogador.position += Vector2(100, 100)
	jogador.get_node("Camera2D").force_update_scroll()
	await process_frame
	_verificar(layout.get_global_transform_with_canvas().origin == posicao_hud, "O HUD fica fixo ao mover a câmera")
	porta.call("_ao_corpo_entrar", jogador)
	await _aguardar_cena()
	_partida.call("_process", 10.0)
	_verificar(_partida.get("tempo_decorrido") == 2.0, "Concluir a fase congela o cronômetro")


func _testar_fase_sem_chaves() -> void:
	var fase := _criar_cenario(0)
	await _aguardar_cena()
	var jogador := fase.get_node("Player")
	_verificar(_partida.get("chaves_totais") == 0, "Uma fase só com chave falsa tem zero chaves reais")
	_verificar(jogador.get_node("HUD/%IndicadorSaida").visible, "Sem chaves, a saída já aparece")
	_verificar(fase.get_node("Door").call("_pode_abrir", jogador), "Sem chaves, a porta dispensa inventário")


func _criar_cenario(quantidade_chaves: int) -> Node2D:
	if is_instance_valid(current_scene):
		current_scene.free()
	var fase := Node2D.new()
	fase.name = "CenarioHUD"
	fase.process_mode = Node.PROCESS_MODE_DISABLED
	_adicionar(fase, "res://scenes/player/player.tscn", "Player")
	for indice in quantidade_chaves:
		_adicionar(fase, "res://scenes/objects/key.tscn", "Chave%d" % indice)
	_adicionar(fase, "res://scenes/objects/fake_key.tscn", "FakeKey")
	_adicionar(fase, "res://scenes/objects/door.tscn", "Door")
	_adicionar(fase, "res://scenes/objects/fake_door.tscn", "FakeDoor")
	root.add_child(fase)
	current_scene = fase
	return fase


func _adicionar(fase: Node, caminho: String, nome: String) -> void:
	var cena := load(caminho) as PackedScene
	var instancia := cena.instantiate()
	instancia.name = nome
	fase.add_child(instancia)


func _aguardar_cena() -> void:
	for quadro in 3:
		await process_frame


func _capturar(nome: String) -> void:
	if not "--capturas" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("/tmp/ice-grim-hud")
	root.get_texture().get_image().save_png("/tmp/ice-grim-hud/" + nome)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		_falhas += 1
		push_error(mensagem)
