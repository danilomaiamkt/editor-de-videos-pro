# Carregado por todos os scripts da skill. Define PATH, Python, pastas e marca.
SKILL_DIR="${SKILL_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export PATH="$HOME/.local/bin:$PATH"
CONFIG_DIR="$HOME/.config/editor-de-videos-pro"
CONFIG="$CONFIG_DIR/config.env"
# padrões do exemplo, depois o config da pessoa por cima
# shellcheck disable=SC1091
. "$SKILL_DIR/config.env.exemplo"
# shellcheck disable=SC1090
if [ -f "$CONFIG" ]; then . "$CONFIG"; fi
[ -n "${FONTE_ARQUIVO:-}" ] || FONTE_ARQUIVO="$SKILL_DIR/assets/fonts/BricolageGrotesque.ttf"
PY="$HOME/.local/share/editor-de-videos-pro/venv/bin/python"
[ -x "$PY" ] || PY="python3"
export SKILL_DIR CONFIG_DIR CONFIG PASTA_TRABALHO PASTA_CONTROLE PASTA_ENTREGA ORIGEM_BRUTOS PASTA_BRUTOS \
  MARCA_NOME ASSINATURA COR_ESCURA COR_CLARA COR_DESTAQUE FONTE_ARQUIVO FONTE_PALMIER IDIOMA TRILHA_DEMONSTRACAO PY
