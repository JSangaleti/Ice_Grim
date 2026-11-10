# Áudio

O `AudioManager` está registrado como Autoload em `project.godot` e fica disponível em qualquer cena. Inicia em silêncio: os arquivos e os momentos de reprodução são definidos pelo código que chamar seus métodos.

## Reprodução

Passe um `AudioStream` importado pela Godot, carregado com `preload`, `load` ou atribuído pelo Inspector. Não há associação automática entre músicas, efeitos, fases ou eventos.

```gdscript
const MINHA_MUSICA = preload("res://assets/music/musica1.mp3")
const MEU_EFEITO = preload("res://assets/sfx/jump.wav")

# Exemplos para colocar nos eventos que você escolher:
AudioManager.play_music(MINHA_MUSICA)
AudioManager.play_sfx(MEU_EFEITO)
```

| Método                                                 | Comportamento                                                                                                                                                   |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `play_music(stream, looped = true, restart = false)`   | Toca uma música por vez. Uma faixa diferente substitui a atual imediatamente. Repetir a chamada para a mesma faixa mantém a posição; `restart = true` reinicia. |
| `pause_music()` / `resume_music()`                     | Pausa e retoma a música na mesma posição.                                                                                                                       |
| `stop_music()`                                         | Para e libera a música atual.                                                                                                                                   |
| `play_sfx(stream, volume_db = 0.0, pitch_scale = 1.0)` | Toca um efeito uma vez, com volume em decibéis e multiplicador de tom/velocidade opcionais.                                                                     |
| `stop_all_sfx()`                                       | Interrompe todos os efeitos.                                                                                                                                    |
| `stop_all()`                                           | Interrompe música e efeitos.                                                                                                                                    |

O loop é configurado em uma cópia do recurso para MP3, OGG Vorbis e WAV, preservando o arquivo importado. Os efeitos sempre tocam uma vez. Até 16 efeitos podem tocar simultaneamente; no limite, o mais antigo é substituído. Os players são reutilizados e liberam a referência ao som quando ele termina.

## Volume e mute

O arquivo `default_bus_layout.tres`, carregado automaticamente pela Godot, define os canais `Master`, `Music` e `SFX`. Música e efeitos passam pelo `Master`, que controla o volume geral.

```gdscript
AudioManager.set_volume(AudioManager.MASTER_BUS, 0.8)
AudioManager.set_volume(AudioManager.MUSIC_BUS, 0.5)
AudioManager.set_volume(AudioManager.SFX_BUS, 1.0)

var volume_atual = AudioManager.get_volume(AudioManager.MUSIC_BUS)
AudioManager.set_muted(AudioManager.MASTER_BUS, true)
AudioManager.set_muted(AudioManager.MASTER_BUS, false)
var silenciado = AudioManager.is_muted(AudioManager.MASTER_BUS)
```

O volume aceita valores de `0.0` (silêncio) a `1.0` (original). Mute preserva o volume configurado. Esses ajustes duram a sessão; o gerenciador não grava preferências em disco.

O áudio continua durante trocas de cena e quando `get_tree().paused` é ativado, permitindo música e sons de menus de pausa. Para pausar a música, chame `pause_music()` explicitamente; para interromper efeitos em andamento, use `stop_all_sfx()`.

Referências da Godot 4.4: [AudioStreamPlayer](https://docs.godotengine.org/en/4.4/classes/class_audiostreamplayer.html), [AudioServer](https://docs.godotengine.org/en/4.4/classes/class_audioserver.html) e [importação e loop de áudio](https://docs.godotengine.org/en/4.4/tutorials/assets_pipeline/importing_audio_samples.html).
