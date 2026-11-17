# Padrão visual

Tudo usa a marca do `config.env`:

| Token | Variável | Uso |
|---|---|---|
| Escuro | `COR_ESCURA` | caixa da legenda, painel da vinheta e da transição, texto do selo |
| Claro | `COR_CLARA` | texto da legenda e dos títulos |
| Destaque | `COR_DESTAQUE` | palavra ativa da legenda, selo, destaque do título, traço |
| Fonte | `FONTE_ARQUIVO` (vinheta/transição) e `FONTE_PALMIER` (legenda) | tudo, em negrito e extranegrito |

Tema padrão (sem marca definida): `#1A1714`, `#FAF8F5`, `#C9A882`, Bricolage Grotesque. A fonte da legenda precisa estar instalada no Mac (o instalador põe a Bricolage em `~/Library/Fonts`). Depois de instalar uma fonte nova, reabrir o Palmier.

## Projeto no Palmier

- `manage_project create` com `fps: 30`, `aspectRatio: "16:9"`. Ao colocar o primeiro clipe 4K o canvas vira 3840x2160, e os tamanhos abaixo são para esse canvas. Em bruto 1080p, dividir os tamanhos por 2.
- Nome: `<MARCA_NOME> - <slug> <Título>`.

## Legenda (`add_captions`)

```json
{
  "language": "<IDIOMA>",
  "maxWords": 6,
  "maxCharacters": 38,
  "animation": "highlightPop",
  "highlightColor": "<COR_DESTAQUE>",
  "style": {
    "fontName": "<FONTE_PALMIER>", "bold": true, "fontSize": 64,
    "color": "<COR_CLARA>", "alignment": "center",
    "background": { "enabled": true, "color": "<COR_ESCURA>", "opacity": 0.82,
                    "cornerRadius": 22, "padding": { "x": 34, "y": 16 } }
  },
  "transform": { "x": 0.5, "y": 0.86 }
}
```

Depois de gerar:
- A primeira legenda de cada frase começa com maiúscula. Corrigir com `update_text` (perde o destaque palavra a palavra só naquele bloco, é aceitável).
- A pontuação da transcrição fica, vírgulas inclusive.
- Legenda que caiu em trecho mudo (demonstração acelerada) ou texto sem sentido (a transcrição às vezes inventa frases em outra língua no silêncio) sai com `remove_clips`, ou é reescrita com o que foi dito de verdade.

## Vinheta de abertura

Título por cima do vídeo cai na cabeça de quem fala, porque cada gravação tem um enquadramento. Por isso todo vídeo abre com uma vinheta antes da imagem.

`scripts/gerar_vinheta.sh "<selo>" "<titulo>" "<destaque>" "<sub>" <saida.mov>`

- 3,6s, 4K, ProRes 4444 com alpha. O painel `COR_ESCURA` cobre a tela desde o primeiro frame. Entram o selo (tipo de vídeo), o título em `COR_CLARA` com o destaque **sempre numa linha própria**, o traço, o subtítulo (o que o vídeo cobre) e a `ASSINATURA` no rodapé. Aos 3,1s o painel sai pela direita revelando o vídeo.
- Aplicação no Palmier:
  1. `import_media` com `matte {hex: "<COR_ESCURA>"}` e `insert_clips` desse fundo na trilha do vídeo principal, `atFrame 0`, `durationFrames 93`. Isso empurra vídeo, áudio, legenda e transições 93 frames juntos.
  2. `add_clips` da vinheta com `startFrame 0`, `includeAudio false`, numa trilha acima da legenda. Ela ocupa 108 frames: os 15 finais saem por cima do começo do vídeo.
- Exemplo: selo "Aula prática", título "Bancada se mede", destaque "por baixo.", sub "Vão, altura, nível e cuba". Título em até ~16 caracteres por linha.

## Vertical em vídeo horizontal (fundo desfocado)

Para trecho gravado em pé (câmera na mão) dentro de um vídeo horizontal:
1. `add_clips` do trecho vertical na trilha do vídeo principal (com áudio). Essa camada vira o **fundo**: `set_clip_properties transform {width: 1, height: 3.164, centerX: 0.5, centerY: 0.5}`, `apply_effect blur.gaussian radius 60`, `apply_color exposure -0.8, saturation 0.8`.
2. `add_clips` do mesmo trecho, mesmo `source`, `includeAudio: false`, sem `trackIndex` (cria trilha no topo; fica no ajuste automático, largura 0.316). `manage_tracks reorder` para essa trilha ficar logo acima do vídeo principal e **abaixo da legenda**.
3. `manage_clip_links link` com a camada nítida + o áudio do fundo, para os cortes de pausa (`remove_silence` no áudio) cortarem as três camadas juntas. Sem isso, a nítida dessincroniza.
4. Legenda do trecho: `add_captions` com `startFrame` no início do trecho e `trackIndex` do áudio; sai num grupo novo, com o mesmo estilo.

## Transição de bloco

`scripts/gerar_transicao.sh "<selo>" "<titulo>" "<destaque>" "<sub>" <saida.mov>`

- 2,4s. A faixa `COR_DESTAQUE` entra pela esquerda e puxa o painel escuro. Depois vêm o selo, o título com a última palavra em destaque, o traço e o subtítulo. O painel sai pela direita.
- O painel cobre a tela inteira de 0,44s a ~2,0s. Colocar o clipe começando **~15 frames antes do corte** que ele esconde, assim o corte cai no meio da cobertura.
- `add_clips` com `includeAudio: false` numa trilha **acima da legenda** (índice menor que o da trilha de legenda).
- Se a fala recomeça logo depois do corte, as primeiras palavras tocam por baixo do painel. Avisar no relatório.
- Título + destaque cabem em uma linha até ~20 caracteres. Mais que isso, encurtar; subtítulo até ~40 caracteres.
- Exemplo: selo "Na prática", título "Hora da", destaque "medição.", sub "Cotas gerais do ambiente".
- Sai ProRes 4444 com alpha, e o Palmier respeita a transparência. O script também gera um PNG de prova do meio da animação para conferir o texto antes de colocar na timeline.

## Trilha nas demonstrações sem fala

Só se `TRILHA_DEMONSTRACAO` estiver configurada. Todo trecho de demonstração em 2x com áudio mudo leva a trilha:
- `import_media` do mp3 e `add_clips` sem `trackIndex` (cria a trilha A2) com `startFrame` e `endFrame` exatos do trecho mudo.
- `set_clip_properties`: `volumeDb -3` (com a voz em torno de -17 LUFS, a trilha fica em -23 LUFS, 6 dB abaixo; com -9 fica fraca demais). Conferir no export com `ebur128`. `fadeInFrames 12`, `fadeOutFrames 60` com `fadeOutInterpolation smooth`. Se o trecho mudo termina e a fala volta, fade-out de 20 frames terminando antes da primeira palavra.
- Trechos mudos curtos (< 4s) entre falas: sem trilha.
- Para não repetir sempre o mesmo começo em vídeos seguidos, variar o ponto de entrada (`source` em 0s, 40s, 80s ou 120s).
- A mesma trilha em todos os vídeos de um curso dá identidade. Para criar uma, gerar uma música instrumental de 2 a 3 minutos, energia constante, sem voz (ex.: chill house com Rhodes, violão dedilhado e shaker, ~100 BPM). Em geradores com política de conteúdo, descrever só a música, não pessoas.
