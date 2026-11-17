---
name: editor-de-videos-pro
description: Edita no Palmier Pro aulas e vídeos gravados no celular (pessoa explicando e demonstrando, em 4K/HDR, horizontal ou vertical). Puxa o original da fototeca ou de uma pasta, trata o áudio (eco, ruído, volume), corta trechos mortos, falhas e frases corrigidas, acelera demonstrações sem fala, tira pausas sem comer palavras, junta continuações gravadas em outro arquivo (inclusive vertical com fundo desfocado), corrige câmera frontal espelhada, legenda na marca configurada, abre com vinheta e marca mudanças de bloco com transições feitas no HyperFrames, e exporta a versão final (Hotmart, Kiwify, YouTube) para a pasta de entrega. Use quando o usuário pedir para editar, cortar, legendar ou exportar aula, vídeo de curso, módulo, tutorial ou gravação, ou disser /editor-de-videos-pro.
---

# Editor de vídeos pro (Palmier Pro + Claude)

Edita, vídeo por vídeo, no padrão abaixo: o Claude monta, corta, legenda e coloca vinheta e transições; o usuário assiste, ajusta e aprova; só então sai a versão final.

Ferramentas: MCP `palmier-pro` (edição), ffmpeg + DeepFilterNet (áudio), plugin HyperFrames (vinheta e transição), app Fotos via AppleScript ou pasta (brutos), Whisper local (conferência).

Antes de editar, ler:
- `references/decisoes-de-corte.md`: o que cortar, acelerar, manter, quando pôr transição, como medir as emendas.
- `references/padrao-visual.md`: parâmetros exatos de legenda, vinheta, vertical, transição e trilha.

Responder no idioma do usuário. Nunca usar travessão nem hífen como pausa nos textos do vídeo, das legendas ou do relatório.

## Configuração

Tudo o que é da pessoa (pastas e marca) fica em `~/.config/editor-de-videos-pro/config.env`, fora da skill, para que atualizar a skill não apague nada. Os padrões estão em `config.env.exemplo`. Rodar `scripts/config.sh` no começo de toda sessão: mostra os valores em uso e o que falta instalar. Nos comandos abaixo, `$PASTA_TRABALHO`, `$COR_DESTAQUE` etc. são esses valores: usar o valor real que o `config.sh` mostrou. Se algo aparecer como FALTA, pedir para rodar o instalador de novo.

### Primeira vez nesta máquina
Se o `config.sh` disser que o config ainda não existe:
1. Copiar `config.env.exemplo` para `~/.config/editor-de-videos-pro/config.env`.
2. Perguntar ao usuário, numa conversa curta:
   - **de onde vêm os brutos**: app Fotos deste Mac (`ORIGEM_BRUTOS="fototeca"`) ou uma pasta, por exemplo do iCloud Drive compartilhada por quem grava (`"pasta"` + `PASTA_BRUTOS`);
   - **onde entregar** a versão final (`PASTA_ENTREGA`);
   - **marca**: nome do curso ou canal (`MARCA_NOME`, prefixo dos projetos), assinatura da vinheta (`ASSINATURA`, ex.: "Fulana de Tal · Mentoria"), três cores (escura, clara e destaque) e fonte. Se a pessoa não tiver marca definida, oferecer o tema padrão (escuro café, off-white e dourado com Bricolage Grotesque). Se ela mandar site, logo ou post, tirar as cores de lá e confirmar. Fonte própria: pedir o arquivo .ttf/.otf, gravar em `FONTE_ARQUIVO`, instalar em `~/Library/Fonts` e descobrir o nome PostScript do negrito (`FONTE_PALMIER`) com `mdls -name com_apple_ats_name_postscript <arquivo da fonte>` (lista os estilos; usar o Bold) ou pelo Catálogo de Fontes; avisar que o Palmier precisa ser reaberto para ver a fonte nova;
   - **trilha** para as demonstrações sem fala: um mp3 instrumental da pessoa (`TRILHA_DEMONSTRACAO`) ou nenhuma.
3. Gravar o config, criar `$PASTA_CONTROLE/CONTROLE.md` (tabela: slug, título, brutos, duração final, transições, status, data) e `$PASTA_CONTROLE/glossario.md` (tabela "como a pessoa fala x como a transcrição erra", começa vazia).
4. Gerar uma vinheta de teste (`scripts/gerar_vinheta.sh`) e mostrar o `_prova.png` para a pessoa aprovar as cores antes da primeira edição.
5. Lembrar: abrir o Palmier Pro e entrar na conta se ele pedir (a transcrição roda na nuvem do Palmier).

## Onde ficam as coisas

| O quê | Onde |
|---|---|
| Brutos | Conforme `ORIGEM_BRUTOS`. **fototeca**: listar com `scripts/puxar_da_fototeca.sh --listar` e exportar o original com `scripts/puxar_da_fototeca.sh IMG_1234.MOV "$PASTA_TRABALHO/<pasta>/bruto"`; na primeira vez o macOS pede permissão para controlar o Fotos. **pasta**: usar o arquivo direto de `PASTA_BRUTOS`; o `preparar_video.sh` baixa do iCloud se estiver só na nuvem. **Nunca editar a partir de Álbum Compartilhado do Fotos**: a Apple entrega em até 720p e no máximo 15 min. Se o bruto vier com altura ≤ 720, parar e pedir o original |
| Mídia de trabalho (áudio tratado, vinheta, transições, exports) | `$PASTA_TRABALHO/<slug>/` (fora de qualquer repositório git) |
| Projeto Palmier | `~/Documents/Palmier Pro/<MARCA_NOME> - <slug> <Título>.palmier` |
| Controle, relatórios e glossário | `$PASTA_CONTROLE/` (`CONTROLE.md`, `glossario.md`, `relatorios/<slug>.md`) |

**Nome pelo assunto, não pelo arquivo.** Slug `aNN-<assunto-curto>` (ex.: `a02-bancada-por-baixo`) e projeto `<MARCA_NOME> - aNN <Título da vinheta>`. Se houver grade de módulos, `mX-aNN-...`. Para nomear direito:
1. Preparar o bruto numa pasta provisória `$PASTA_TRABALHO/aNN/`.
2. Ler o conteúdo (passo 2), escolher o título e **renomear a pasta antes de importar no Palmier**. O Palmier referencia os arquivos pelo caminho: se renomear depois, deixar um link simbólico com o nome antigo (`ln -s novo antigo`).

**Disco:** cada bruto 4K tem 2 a 4 GB e o `_tratado.mov` tem o mesmo tamanho. Um vídeo por vez. Apagar o bruto exportado da fototeca logo depois do preparo (o original continua lá). O `preparar_video.sh` recusa rodar sem espaço.

## Fluxo

### 0. Checagem rápida
- `scripts/config.sh`: configuração, ferramentas, fonte, HyperFrames, disco.
- `mcp__palmier-pro__manage_project action=list` responde. O app Palmier Pro precisa estar **aberto** (o MCP só existe com ele aberto). Se não responder: pedir para abrir o Palmier e rodar `/mcp` → palmier-pro → Reconnect.
- O Palmier só aceita edição no projeto **ativo na tela**. Se o usuário estiver com outro projeto aberto, as edições são recusadas: avisar e esperar, não trocar de projeto por cima do trabalho dele.
- Ler `CONTROLE.md` (o que já foi feito, próximo número) e `glossario.md`.

### 1. Puxar e preparar o bruto
```bash
S=~/.claude/skills/editor-de-videos-pro/scripts
T="<PASTA_TRABALHO>"
# fototeca:
$S/puxar_da_fototeca.sh IMG_1234.MOV "$T/a03/bruto"
$S/preparar_video.sh "$T/a03/bruto/IMG_1234.MOV" a03 && rm -rf "$T/a03/bruto"
# pasta (iCloud Drive): --liberar tira o bruto do disco depois de tratar (continua na nuvem)
$S/preparar_video.sh "<PASTA_BRUTOS>/IMG_1234.MOV" a03 --liberar
```
O segundo argumento é o **nome da pasta do vídeo**: a saída vai para `$PASTA_TRABALHO/<nome>/`. O script trata o áudio (DeepFilterNet para ruído e eco, EQ, gate, compressor, -16 LUFS), remonta o vídeo sem recodificar (HDR preservado), mede a sincronia (tem que dar 0 ms com fala real) e grava `<nome do bruto>_tratado.mov`. **Nunca sobrescreve** um tratado existente, porque o Palmier referencia o arquivo no lugar. O áudio é tratado antes de editar porque a transcrição do áudio limpo é mais precisa.

**Um vídeo pode juntar vários brutos.** Comparar o fim de um bruto com o horário do seguinte (`--listar` mostra a data). Se o próximo começa segundos depois, é continuação. É comum a pessoa repetir a última frase no começo do novo arquivo: tirar a versão do primeiro e manter a do segundo.

Vídeo **vertical** (2160x3840) dentro de vídeo horizontal: fundo desfocado (padrao-visual.md, seção Vertical).

**Câmera frontal grava espelhado** (texto aparece ao contrário). O `preparar_video.sh` lê a lente com o ExifTool e avisa "CÂMERA FRONTAL". Nesse caso, depois da montagem e dos cortes, aplicar `set_clip_properties transform {flipHorizontal: true}` em **todos** os clipes daquele bruto (a cena inteira está invertida, não só onde há texto). Não espelhar vinheta nem legendas. Conferir num quadro com texto. Câmera traseira não se mexe.

### 2. Projeto e leitura do material
- `manage_project create` (`name: "<MARCA_NOME> - aNN <Título>"`, `fps: 30`, `aspectRatio: "16:9"`), `import_media` com o `_tratado.mov`.
- `inspect_media` com `overview: true` + `language: <IDIOMA>`: storyboard e transcrição.
- Janelas sem fala: `inspect_media` com `startSeconds/endSeconds` e `maxFrames` 8 a 12 para ver o que acontece ali.
- Classificar cada trecho (decisoes-de-corte.md, seção 1). Procurar também **autocorreção** ("eixo X... eixo Z"): fica só a versão certa.

### 3. Montagem
`add_clips` trecho por trecho, em sequência, com `source` em segundos do bruto. **Começo e fim de cada trecho medidos no som**, não pelo horário da transcrição: `"$PY" scripts/medir_emendas.py <tratado.mov> <ini>:<dur>:<rótulo> ...` dá o primeiro e o último som de cada janela; começo = primeiro som - 0,3s, fim = último som + 0,2s. Quando a fala é contínua entre duas palavras, olhar o perfil em 50 ms (decisoes-de-corte.md, seção 3) para achar o vale; se não houver vale, não cortar no meio. Conferir que todo áudio ficou na mesma trilha (A1): uma sobra de 1 frame joga o áudio do trecho seguinte para A2 e o `remove_silence` recusa; corrigir com `set_clip_properties durationFrames` e recolocar o trecho. Demonstrações sem fala: `edit_speed` 2x + `volumeDb -60` no áudio + trilha por baixo, se houver (padrao-visual.md, seção Trilha).

### 4. Pausas
`get_transcript` (gera o cache) → `remove_silence` só nos clipes de fala, 0,9s / 0,3s → conferir palavra por palavra contra o bruto. A transcrição da timeline às vezes não mostra palavras que estão lá: antes de concluir que faltou palavra, conferir com `inspect_media` + `clipId` no trecho. Faltou de verdade: `undo` e refazer.

### 5. Checagem fina
Seção 3 de decisoes-de-corte.md: fragmento no início, hesitação no meio da frase (olhar o quadro antes de cortar), frase abandonada, ajuste de câmera, buracos sem legenda e **medição do som em toda emenda**. A transcrição na nuvem do Palmier às vezes falha com erro de TLS ou "staged upload not found": repetir a chamada.

### 6. Legenda
`add_captions` com o estilo de padrao-visual.md (cores, fonte e idioma do config). Depois:
- Maiúscula no início de frase; ponto final na última legenda.
- Termos que a transcrição erra: corrigir pelo `glossario.md`. Quando o usuário corrigir um termo novo, acrescentar no glossário.
- Tirar travessão ("não é—" vira "não é,").
- Legenda com menos de ~20 frames: esticar até a seguinte (`set_clip_properties durationFrames`).
- Bloco dividido em dois iguais por um corte: apagar a cópia e esticar o original.

### 7. Vinheta e transições
- **Vinheta de abertura, sempre** (padrao-visual.md): `scripts/gerar_vinheta.sh "<selo>" "<título>" "<destaque>" "<o que o vídeo cobre>" <saida.mov>`, fundo `COR_ESCURA` de 93 frames inserido no início com `insert_clips` e a vinheta por cima. Nada de título por cima do vídeo: cai na cabeça de quem fala.
- **Transições** pelos critérios da seção 4 de decisoes-de-corte.md: `scripts/gerar_transicao.sh ...`, olhar o `_prova.png`, `add_clips` com `includeAudio: false` numa trilha acima da legenda, ~15 frames antes do corte.
- `insert_clips` **corta ao meio** qualquer vinheta ou transição que atravesse o ponto de inserção. Depois de inserir: apagar o pedaço empurrado, `trimEndFrame 0` e `durationFrames` original no pedaço que ficou, e reposicionar com `move_clips` se preciso.
- Conferir com `capture_frame` + `inspect_media` na entrada, no meio e na saída.

### 8. Relatório e revisão do usuário
Salvar `$PASTA_CONTROLE/relatorios/<slug>.md` e resumir no chat:
- duração dos brutos e do vídeo final;
- trechos cortados e acelerados, com motivo;
- vinheta e transições (timecode `HH:MM:SS:FF` + frame + motivo + texto);
- pontos para conferir (emendas justas, fala que recomeça por baixo de transição, pausas mantidas por dúvida, legendas corrigidas à mão, termos técnicos incertos).

**Não exportar sem pedido.** O usuário assiste e faz ajustes finos. Se ele disser que ajustou, comparar a timeline e descrever; não virar regra sem perguntar o motivo (seção 6 de decisoes-de-corte.md). Quando aprovar, renomear se ainda estiver com nome provisório e atualizar o `CONTROLE.md`.

### 9. Exportar, entregar e liberar espaço
Quando o usuário pedir:
- `export_project` `H.264`, `resolution: "1080p"`, `outputPath: <PASTA_TRABALHO>/<slug>/<slug>_1080p.mp4` (intermediário, alta taxa). Esperar terminar com um loop em background que confere a duração com `ffprobe`.
- `scripts/exportar_final.sh <master> "<pasta>/aNN <Título>.mp4"`: **esta é a entrega**. 1080p H.264 CRF 20, teto 8 Mbps, AAC 192k: um vídeo de 5min45 fica com uns 200 MB a 4,9 Mbps. Serve para Hotmart, Kiwify, YouTube e áreas de membros.
- Versão para aprovação no WhatsApp (`scripts/exportar_whatsapp.sh`, 720p até 90 MB) **só se pedir**.
- Conferir a versão final com uma grade de quadros (vinheta, legenda, transição, vertical, final) antes de entregar.

**Entrega e limpeza, ao fim de cada vídeo:**
1. Copiar a versão final para `$PASTA_ENTREGA/` (criar a pasta se não existir). Compartilhar a pasta com o cliente é com o usuário, pelo Finder.
2. Se a entrega for no iCloud Drive, esperar o envio terminar: `scripts/icloud_status <arquivos>` tem que dizer ENVIADO.
3. **Perguntar antes de apagar.** Com o ok: apagar a versão final local, o export do Palmier e liberar a cópia do iCloud no disco (`brctl evict <arquivo>`; o arquivo continua na nuvem).
4. Apagar também os brutos locais e os `_tratado.mov` (o original segue na fototeca ou na pasta de brutos e o tratado pode ser refeito idêntico pelo `preparar_video.sh`; o projeto do Palmier fica sem o vídeo até refazer). Vinheta e transições ficam (são pequenas). Se o espaço não voltar, `lsof +L1` mostra quem segura o arquivo apagado (em geral o Palmier com o projeto aberto).
5. Atualizar o `CONTROLE.md` com status e local do arquivo.

## Armadilhas conhecidas
- `remove_silence` roda sem proteção de palavras: sempre conferir depois.
- A transcrição do Palmier marca o início das palavras até ~0,25s depois do som real: medir o som nas emendas.
- O tratamento de áudio zera som ambiente baixo; para saber se havia fala baixa num trecho "mudo", medir e transcrever o bruto com Whisper local (`$PY` com `faster_whisper`; o primeiro uso baixa o modelo).
- `insert_clips` corta overlays que atravessam o ponto de inserção.
- Duas legendas ou textos na mesma trilha e no mesmo intervalo: um apaga o outro.
- `update_text` numa legenda tira o destaque palavra a palavra daquele bloco (aceitável).
- Trims (`trimStartFrame`) são em frames do projeto (30fps), não do arquivo de 60fps.
- Vídeo de iPhone vem em HDR (HLG). O export H.264 do Palmier já sai SDR bt709 com a cor certa; não converter antes.
