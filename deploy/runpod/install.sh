#!/usr/bin/env bash
set -Eeuo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PERSIST_ROOT="${WAN2GP_PERSIST_ROOT:-/workspace}"
PYTHON_BIN="${WAN2GP_PYTHON_BIN:-python3.11}"
VENV_DIR="${WAN2GP_VENV_DIR:-$PERSIST_ROOT/.venvs/wan2gp}"
mkdir -p "$PERSIST_ROOT/.cache/huggingface" "$PERSIST_ROOT/.cache/torch" "$PERSIST_ROOT/.cache/pip" "$(dirname "$VENV_DIR")"
export HF_HOME="$PERSIST_ROOT/.cache/huggingface" TORCH_HOME="$PERSIST_ROOT/.cache/torch" PIP_CACHE_DIR="$PERSIST_ROOT/.cache/pip" PYTHONUNBUFFERED=1
if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: NVIDIA GPU not detected. Choose a GPU Pod." >&2; exit 1
fi
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "ERROR: Python 3.11 not available; select or install Python 3.11." >&2; exit 1
fi
"$PYTHON_BIN" - <<'PY'
import sys
if sys.version_info[:2] != (3, 11):
    raise SystemExit(f"ERROR: Expected Python 3.11, found {sys.version.split()[0]}")
PY
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR" || { echo "ERROR: Install Python 3.11 venv support."; exit 1; }
fi
PY="$VENV_DIR/bin/python"
"$PY" -m pip install --upgrade pip setuptools wheel
"$PY" -m pip install torch==2.10.0 torchvision==0.25.0 torchaudio==2.10.0 --index-url https://download.pytorch.org/whl/cu130
"$PY" - <<'PY'
import torch
if not torch.cuda.is_available():
    raise SystemExit("ERROR: WanGP environment cannot access NVIDIA CUDA GPU.")
print("WanGP PyTorch:", torch.__version__, "CUDA:", torch.version.cuda)
PY
cd "$REPO_DIR"
"$PY" -m pip install -r requirements.txt
echo "WanGP dependencies installed in $VENV_DIR"
echo "Configure WAN2GP_WEB_USER and WAN2GP_WEB_PASSWORD, then run bash deploy/runpod/start.sh"
