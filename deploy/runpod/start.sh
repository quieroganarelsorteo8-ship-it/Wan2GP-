#!/usr/bin/env bash
set -Eeuo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PERSIST_ROOT="${WAN2GP_PERSIST_ROOT:-/workspace}"
VENV_DIR="${WAN2GP_VENV_DIR:-$PERSIST_ROOT/.venvs/wan2gp}"
PORT="${WAN2GP_PORT:-7860}"
if [[ -z "${WAN2GP_WEB_USER:-}" || -z "${WAN2GP_WEB_PASSWORD:-}" ]]; then
  echo "ERROR: WAN2GP_WEB_USER and WAN2GP_WEB_PASSWORD must be set in RunPod environment variables." >&2; exit 1
fi
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
  echo "ERROR: WAN2GP_PORT must be a valid TCP port" >&2; exit 1
fi
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  echo "ERROR: WanGP virtualenv not found. Run bash deploy/runpod/install.sh first." >&2; exit 1
fi
export HF_HOME="$PERSIST_ROOT/.cache/huggingface" TORCH_HOME="$PERSIST_ROOT/.cache/torch" PIP_CACHE_DIR="$PERSIST_ROOT/.cache/pip" GRADIO_ANALYTICS_ENABLED=false PYTHONUNBUFFERED=1
mkdir -p "$HF_HOME" "$TORCH_HOME" "$PIP_CACHE_DIR"
cd "$REPO_DIR"
echo "Starting WanGP on 0.0.0.0:$PORT with Gradio login"
exec "$VENV_DIR/bin/python" wgp.py --listen --server-port "$PORT" "$@"
