# Editor de vídeos pro

Skill do [Claude Code](https://claude.com/claude-code) que edita aulas e vídeos gravados no celular dentro do [Palmier Pro](https://github.com/palmier-io/palmier-pro). Você pede, o Claude monta a timeline, você assiste, ajusta e aprova.

Feita para vídeo de gente explicando e demonstrando: aula prática, tutorial, curso gravado em casa ou em campo.

## O que ela faz

* **Áudio limpo:** tira ruído e eco do ambiente, equaliza e nivela o volume (-16 LUFS) sem mexer no vídeo nem perder o HDR.
* **Corte:** tira câmera vazia, ajustes de tripé, frases abandonadas, retakes e autocorreções. Os trechos em que a pessoa demonstra sem falar ficam, em 2x e sem som.
* **Pausas:** remove silêncios sem comer palavras e mede o som real em cada emenda, porque a transcrição marca as palavras atrasadas.
* **Vários arquivos num vídeo:** junta continuações gravadas em outro arquivo, inclusive trecho vertical com fundo desfocado.
* **Câmera frontal:** detecta gravação espelhada e corrige.
* **Legenda:** palavra por palavra, com destaque animado, nas cores e na fonte da sua marca, e com glossário para os termos técnicos que a transcrição erra.
* **Vinheta e transições:** abertura com título e marca, e transições entre blocos, geradas em 4K com transparência (HyperFrames).
* **Entrega:** exporta a versão final (1080p, boa para Hotmart, Kiwify, YouTube), entrega numa pasta do iCloud e libera o espaço do Mac.
* **Relatório:** em cada vídeo, o que foi cortado e por quê, com timecode, e o que vale você conferir.

## Requisitos

1. **Mac com chip Apple** (M1 ou mais novo) e **macOS 26 (Tahoe)** ou mais novo. O Palmier Pro não roda em Mac Intel nem em Windows.
2. **Conta Claude Pro ou Max** (o Claude Code vem incluído).
3. Uns **20 GB livres**. Cada vídeo 4K ocupa de 5 a 10 GB enquanto é editado; depois da entrega o espaço volta.

## Instalação

Abra o **Terminal** e cole:

```bash
curl -fsSL https://raw.githubusercontent.com/danilomaiamkt/editor-de-videos-pro/main/instalar.sh | bash
```

Ou baixe o repositório (botão **Code** > **Download ZIP**), descompacte e dê dois cliques em `instalar.command`. Se o Mac bloquear: botão direito > **Abrir** > **Abrir**.

O instalador não pede senha nem precisa de Homebrew. Ele instala:

| O quê | Para quê |
|---|---|
| Claude Code | quem edita |
| Palmier Pro | o editor de vídeo |
| ffmpeg e ffprobe | processar vídeo e áudio |
| DeepFilterNet | tirar ruído e eco |
| ExifTool | detectar câmera frontal |
| Node e plugin HyperFrames | gerar vinheta e transições |
| Python com Whisper | conferir trechos com fala baixa |
| Fonte Bricolage Grotesque | tema padrão |
| Conexão MCP com o Palmier | o Claude mexer na timeline |

Pode rodar de novo quantas vezes quiser: ele pula o que já está instalado e serve também para atualizar a skill.

## Primeiro uso

1. Abra o **Palmier Pro** e entre na conta se ele pedir (a transcrição roda na nuvem dele).
2. No Terminal, digite `claude` e faça login.
3. Com o Palmier aberto, digite `/editor-de-videos-pro`.
4. Na primeira vez, o Claude pergunta:
   * de onde vêm os vídeos brutos (app Fotos do Mac ou uma pasta, por exemplo do iCloud Drive);
   * onde entregar o vídeo pronto;
   * a sua marca: nome, assinatura da vinheta, três cores e a fonte. Se você mandar o site ou um post, ele tira as cores de lá. Sem marca, usa o tema padrão;
   * se quer uma trilha instrumental por baixo das demonstrações.

   Depois gera uma vinheta de teste para você aprovar as cores.

Tudo isso fica em `~/.config/editor-de-videos-pro/config.env`, que você pode editar quando quiser.

## Como é o trabalho de cada vídeo

1. Você pede: "edita o vídeo IMG_1234" (ou o nome do arquivo na pasta).
2. O Claude trata o áudio, monta, corta, legenda e põe vinheta e transições.
3. Ele entrega um relatório com o que fez e o que vale conferir.
4. Você assiste no Palmier, ajusta o que quiser e aprova.
5. Ele exporta a versão final, entrega na pasta e, perguntando antes, apaga os arquivos pesados.

Enquanto o Claude edita, deixe aberto no Palmier só o projeto em que ele está trabalhando.

## Se algo der errado

* **"Não consigo falar com o Palmier":** o Palmier Pro precisa estar aberto. Depois, no Claude, digite `/mcp`, escolha `palmier-pro` e clique em Reconnect.
* **A transcrição falhou:** acontece às vezes na nuvem do Palmier; o Claude tenta de novo.
* **Pouco espaço:** o Claude não prepara um vídeo sem espaço suficiente. Entregue o anterior para liberar.
* **Outra coisa:** rode o instalador de novo e veja o resumo do final, que mostra o que está faltando.

## Licença

Código sob licença MIT (veja `LICENSE`). A fonte Bricolage Grotesque vem com a própria licença, SIL Open Font License (`skill/editor-de-videos-pro/assets/fonts/OFL.txt`). O Palmier Pro, o Claude Code e as demais ferramentas são baixados das fontes oficiais e seguem as licenças deles.
