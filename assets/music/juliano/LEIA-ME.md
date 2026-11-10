# Trilha autoral — Juliano Rubio Sangaleti

Todas as músicas já incluídas no jogo são autorais de Juliano Rubio Sangaleti. Os três MP3 em `assets/music/` formam a trilha atual. Esta subpasta é opcional e serve apenas para substituir faixas por grupo de fases, sem editar GDScript.

Se quiser substituir alguma faixa, adicione músicas `.ogg` (Vorbis) ou `.mp3` nesta pasta, usando estes nomes, e deixe a Godot importar:

| Arquivo sem extensão | Onde toca |
| --- | --- |
| `menu` | Menu e tutorial |
| `fases_1_2` | Fases 1 e 2 |
| `fases_3_4` | Fases 3 e 4 |
| `fase_5` | Fase 5 |
| `boss` | Fase 6 inteira, incluindo a arena |

Exemplo: `assets/music/juliano/boss.ogg`. Não é preciso editar GDScript. O jogo usa automaticamente cada faixa disponível; se não houver substituição, mantém a faixa original correspondente de Juliano. Se houver OGG e MP3 com o mesmo nome, prefere OGG. Os créditos de autoria são exibidos independentemente dos arquivos desta pasta. Cada faixa toca até o fim. Havendo uma troca solicitada pela fase ou menu atual, a próxima começa apenas após o término; caso contrário, a mesma faixa repete inteira.

Para publicar na Web, importe os arquivos e exporte novamente. Use apenas gravações cuja distribuição esteja autorizada pelos autores.
