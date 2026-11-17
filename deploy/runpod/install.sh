#!/usr/bin/env bash
set -Eeuo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PERSIST_ROOT="${WAN2GP_PERSIST_ROOT:-/workspace}"
mkdir -p "$PERSIST_ROOT/.cache/huggingface" "$PERSIST_ROOT/.cache/torch" "$PERSIST_ROOT/.cache/pip"
export HF_HOME="$PERSIST_ROOT/.cache/huggingface" TORCH_HOME="$PERSIST_ROOT/.cache/torch" PIP_CACHE_DIR="$PERSIST_ROOT/.cache/pip" PYTHONUNBUFFERED=1
if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: NVIDIA GPU not detected. Choose a GPU Pod." >&2; exit 1
fi
python3 - <<'PY'
import sys
if sys.version_info[:2] != (3,11):
    raise SystemExit(f"ERROR: Expected Python 3.11, found {sys.version.split()[0]}")
try:
    import torch
except ImportError as e:
    raise SystemExit(f"ERROR: CUDA PyTorch is missing: {e}")
if not torch.cuda.is_available():
    raise SystemExit("ERROR: PyTorch cannot access CUDA GPU.")
print("PyTorch:", torch.__version__, "CUDA:", torch.version.cuda)
PY
cd "$REPO_DIR"
python3 -m pip install -r requirements.txt
echo "Dependencies installed. Set WAN2GP_WEB_USER and WAN2GP_WEB_PASSWORD then run bash deploy/runpod/start.sh"
