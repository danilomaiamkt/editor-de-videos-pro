# Decisões de corte, pausa e transição

Critérios tirados de aulas práticas reais gravadas no celular (pessoa explicando e demonstrando). Referência: bruto de 3min26 virou aula de 2min12 sem perder conteúdo.

## 1. Classificar cada trecho antes de montar

Usar `inspect_media` com `overview: true` (storyboard) + transcrição por segmentos. Cada trecho do bruto cai em uma de quatro classes:

| Classe | Como reconhecer | O que fazer |
|---|---|---|
| **Fala** | a pessoa explicando, com áudio | entra em 1x; depois passa pelo corte de pausas |
| **Demonstração** | a pessoa executando a técnica sem falar (medindo, anotando, montando, mostrando na tela) | entra em **2x com áudio mudo** (`edit_speed uniform 2` + `volumeDb -60` no áudio). Não cortar: numa aula prática, a técnica é o conteúdo |
| **Morto** | câmera vazia, a pessoa arrumando o celular/tripé, andando para se posicionar, saindo e voltando | sai inteiro |
| **Falha de gravação** | frase abandonada, retake da mesma fala, risada ou tropeço, trecho que a pessoa repete melhor logo depois | sai. Na dúvida, não cortar sozinho: listar no relatório com timecode para o usuário decidir |
| **Ajuste de câmera** | a pessoa levanta, vai até o celular, muda o enquadramento ("deixa eu ver se consigo mostrar aqui pra vocês") | sai o movimento; a frase que anuncia pode ficar se a imagem seguinte mostra o que ela prometeu |
| **Autocorreção** | fala errado e corrige logo depois ("no eixo X... na verdade, o eixo Z") | sai a versão errada, fica a certa |
| **Frase abandonada** | começa e para no meio ("tem a interferência de uma...", "Pra medir...") e recomeça depois | sai a abandonada, inclusive o ajuste de câmera no meio |
| **Comentário solto** | piada ou reação fora da explicação ("Aja o joelho") durante deslocamento | sai junto com o deslocamento |

Exemplos reais: começo de 30s com a câmera no chão (morto); caminhada de um ponto ao outro com comentário solto e uma frase abandonada (morto + falha, coberto por transição); "eixo X" corrigido para "eixo Z" (autocorreção); "vê se tá dando pra vocês, deixa eu" + reenquadramento + a mesma frase repetida (ajuste de câmera + repetição).

Atenção: uma "demonstração" que é só a pessoa andando, se posicionando ou olhando para a parede sem medir nada é **morto**, não demonstração. Esse erro já aconteceu: o trecho ficou em 2x e saiu na revisão.

Montagem: um `add_clips` por trecho mantido, em sequência na mesma trilha (`trackIndex` 0 depois do primeiro), usando `source: [ini, fim]` em segundos do bruto.

## 2. Corte de pausas (só nos trechos de fala)

1. **Antes**, rodar `get_transcript` uma vez para gerar e guardar a transcrição. Sem isso, o `remove_silence` roda sem proteção de palavras e come sílabas.
2. `remove_silence` com `clipIds` = só os clipes de fala, `minimumPauseSeconds: 0.9`, `speechPaddingSeconds: 0.3`.
   - 0,6s/0,15s é agressivo demais: comeu palavras curtas ("uma" em "E tem uma coluna", um "Tá?" no fim da frase). Não usar.
3. O resultado sempre volta com `wordProtection: "unavailable"`, então **conferir sempre**: comparar a transcrição da timeline com a do bruto palavra por palavra. Se faltar palavra, dar `undo` e refazer com mais folga.

## 3. Checagem fina (repassar a aula inteira depois dos cortes)

Rodar `get_transcript` (palavras) e procurar:

- **Fragmento no começo**: sílaba solta antes da primeira palavra ("Bom, então" cortado pela metade). Tirar com `ripple_delete_ranges` na trilha do vídeo, passando `ignoreSyncLockedTracks` com as trilhas do título de abertura.
- **Palavra de abertura perdida** ("Então agora..." virou "agora..."). Se a frase fica boa sem ela, manter e só corrigir a maiúscula da legenda.
- **Pausa de hesitação no meio da frase** (>1s entre duas palavras da mesma frase). Olhar o quadro com `inspect_media` naquele intervalo:
  - olhos fechados, olhando para baixo, pensando, sem mexer a câmera → **cortar** a pausa;
  - virando a câmera para mostrar algo ("Do lado de cá, ...", "pedra, ... pia") → **manter**, faz parte da explicação.
- **Risada/pausa entre blocos sem legenda** (buraco na legenda com áudio): cortar.
- **Legenda errada** em trecho mudo ou texto sem sentido: ver padrao-visual.md.

### Início e fim de cada trecho: medir o som, não confiar no horário da transcrição

A transcrição do Palmier marca o início das palavras até ~0,25s **depois** do som real. Exemplo: o "E" de "E não se engane" estava em 30,0s na transcrição, mas o som começava em 29,75s; o corte em 29,9s comeu o ataque da palavra e a aula entrava abrupta (percebido na revisão). Regra:
- Começo de trecho: medir o volume do bruto em janelas de 50 ms (ffmpeg + python, como no exemplo abaixo) e começar **0,3s antes** do salto de volume.
- Fim de trecho: terminar 0,2s depois da queda de volume.
- Medir no bruto original, não no `_tratado.mov`: o tratamento zera o som ambiente baixo e esconde o contexto.

```bash
"$PY" ~/.claude/skills/editor-de-videos-pro/scripts/medir_emendas.py aula_tratado.mov 1.5:3:inicio 64.5:2:fim-bloco 68.5:2:ini-bloco
```
Para ver o perfil completo (vale entre palavras), `LIMIAR_DB=-60` mostra também os trechos baixos.

Se o bruto já foi apagado, a mesma medida no `_tratado.mov` serve para achar o salto da fala (o silêncio antes vira -100 dB).

### Cuidado nas emendas

Antes de qualquer `ripple_delete_ranges` perto do fim de um clipe, conferir onde a **próxima palavra** começa no clipe seguinte. Já aconteceu: um corte que invadiu 7 frames do clipe seguinte comeu o começo de "Vamos", e foi preciso devolver com `set_clip_properties trimStartFrame`. Regra: o fim do corte fica pelo menos 3 frames antes da próxima palavra e 2 frames depois do fim da anterior.

`remove_clips` em legenda não faz ripple (só apaga). `ripple_delete_ranges` na trilha do vídeo desloca a legenda junto; se o corte dividir um bloco de legenda em dois iguais, apagar a cópia e esticar o original com `set_clip_properties durationFrames`.

## 4. Quando colocar transição

A transição é um capítulo, não um enfeite. Colocar **só** quando as duas condições valem ao mesmo tempo:

1. **Muda o bloco da aula**: da explicação para a execução ("vou começar pelas medidas gerais..." → a pessoa executando), de um ambiente para outro, de uma etapa do método para a próxima (cotas gerais → subdivididas → detalhes), ou da gravação no tripé para a selfie com outro enquadramento; e
2. **Existe um corte seco para esconder** nesse ponto (fim de um clipe e começo de outro, com salto de posição ou de enquadramento).

Limites: **no máximo 1 transição a cada ~2 minutos de aula**, e nunca duas seguidas sem pelo menos 30s de fala entre elas. Uma mudança pequena de assunto dentro do mesmo plano não leva transição.

Texto: o selo diz o tipo de bloco ("Na prática", "Próxima etapa", "Atenção", "Erro comum"), o título + destaque diz a ação em 2 a 4 palavras com a palavra-chave na cor de destaque ("Hora da **medição.**", "Cotas **subdivididas.**", "O que **não fazer.**") e o sub dá o detalhe tirado da própria fala ("Cotas gerais do ambiente"). Usar o vocabulário de quem ensina, não o da IA (o glossário ajuda).

Referência: transição logo depois do fim da explicação ("...foi pedido aqui."), antes da primeira demonstração.

Toda transição que a skill decidir colocar vai no relatório com o motivo, para o usuário aprovar.

## 5. Timecodes

O usuário aponta tempos no formato do Palmier `HH:MM:SS:FF` a 30fps. Conversão: `frame = ((HH*60 + MM)*60 + SS)*30 + FF`. Ex.: `00:01:12:19` = 2179. No relatório, dar sempre os dois (timecode e frame).

## 6. Ajustes finos do usuário

Depois da checagem, o usuário assiste e corta falhas de gravação que a transcrição não mostra. Quando ele disser "fiz ajustes, entenda", comparar a timeline atual com a anterior (clipes, trims, durações, legendas) e **descrever** o que mudou. **Não transformar em regra nova sem perguntar o motivo**: muitas vezes o motivo é uma falha de gravação daquele trecho, não uma mudança de padrão.

## 7. Glossário

Termos técnicos de cada área a transcrição erra sempre do mesmo jeito (ex.: "sóculo" vira "sótão", "prancha" vira "trancha", nome de software vira palavra comum). O glossário fica em `$PASTA_CONTROLE/glossario.md`, uma tabela "como a pessoa fala | como a transcrição escreve":
- corrigir na legenda sempre que aparecer;
- quando o usuário corrigir um termo novo, acrescentar na tabela;
- termo de que não há certeza: listar no relatório em vez de adivinhar;
- usar o mesmo vocabulário nos textos da vinheta e das transições.
