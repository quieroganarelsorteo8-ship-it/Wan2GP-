# WanGP — RunPod GPU web deployment (experimental)

This setup runs WanGP's original Gradio interface on a rented NVIDIA GPU Pod so it can be opened from a web browser. It does **not** run GPU models directly on Vercel and it does **not** deploy or purchase a Pod for you.

## Before starting

- You need a RunPod account and billing credit. GPU time and storage cost money.
- Create a **GPU Pod** (not Serverless). Recommended official **base image**: `runpod/pytorch:2.1.0-cu1300-torch2121-ubuntu2404` (CUDA 13.0, Ubuntu 24.04). This base includes PyTorch 2.12.1, but the installer creates a separate Python 3.11 virtualenv with PyTorch 2.10.0 + CUDA 13.0, as recommended by WanGP. RunPod's default Python may be 3.12; the installation explicitly selects `python3.11`. Check that the image contains a working `python3.11` command before installing.
- Choose a GPU appropriate for your model. About **24 GB VRAM** is a useful starting point for broader model compatibility; smaller models can use less.
- Reserve ample **persistent storage**, initially around 100 GB or more, depending on the models you download. Make sure `/workspace` is on persistent storage.
- Configure an **HTTP exposed port: 7860** in the Pod template/settings.
- In RunPod environment variables (not Git), set:
  - `WAN2GP_WEB_USER` — a private username
  - `WAN2GP_WEB_PASSWORD` — a long unique password

## First installation

Open the Pod's Terminal or SSH and run:

```bash
cd /workspace
git clone --branch deploy/runpod-web --single-branch https://github.com/quieroganarelsorteo8-ship-it/Wan2GP-.git Wan2GP
cd Wan2GP
bash deploy/runpod/install.sh
bash deploy/runpod/start.sh
```

The initial install will install many large dependencies and may take time and significant disk space. CUDA/Python wheel compatibility depends on the selected Pod image. The scripts stop if PyTorch cannot see the GPU.

When WanGP launches, open your Pod's **Connect** screen in RunPod and choose the HTTP service for **port 7860**. RunPod normally provides an address like `https://<pod-id>-7860.proxy.runpod.net` — use the exact link displayed in your own account, not this example. Sign in with your configured username and password.

## Subsequent startup

With the same Pod environment variables:

```bash
cd /workspace/Wan2GP
bash deploy/runpod/start.sh
```

Only one WanGP process should use port 7860 at a time. Use a persistent volume or network volume appropriate to your requirements. Container and Pod deletion do not necessarily preserve all data; back up important outputs independently.

## Why the entrypoint fix on Vercel is insufficient

The original `wgp.py` is a long-lived Gradio program whose image/video inference uses CUDA and substantial disk/GPU memory. Vercel's Python serverless entrypoint setting would address only the initial entrypoint detection error, not those GPU requirements.

## Security and costs

- The deployment branch adds **Gradio HTTP login** and refuses to serve via `--listen` without both credentials.
- **Do not** use `--share` or expose the Gradio port without password protection.
- The Gradio account is for trusted private use, not a multi-tenant service. A public product needs a proper authentication gateway, isolation, quotas and a queue.
- **Stop your Pod after using it.** GPU costs accrue while running; depending on the volume settings, storage can continue to incur charges.
- Do not put secrets in commits, terminal screenshots, chat messages or public repository files.
- This configuration has not yet been run on an actual RunPod GPU. Verify dependency versions and startup logs after choosing your template.

## Troubleshooting

- **Missing GPU**: ensure the Pod has an NVIDIA GPU and a CUDA-compatible PyTorch image.
- **Wrong Python**: use Python 3.11.
- **Cannot open site**: check exposed *HTTP* port 7860 and whether the Python process is still running.
- **Out of disk**: increase persistent volume storage or remove unneeded model caches.
- **Out of VRAM**: use a smaller/quantized model, a low-VRAM profile, or a larger GPU.
- **Dependency install fails**: collect the last error lines before changing CUDA wheels or the core app.

References: RunPod documentation (https://docs.runpod.io/) and WanGP's own Dockerfile, requirements.txt and docs/INSTALLATION.md.
