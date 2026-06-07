# Open WebUI Setup — Local SFCC AI Front-end

Open WebUI runs at `http://localhost:3000` and connects to your local Ollama instance.
It gives you a chat interface with file upload, conversation history, and model switching
— so instead of piping repomix output through bash you can drag files into a chat window.

---

## Install via Docker

The simplest install. Requires Docker Desktop running on your Mac.

```bash
docker run -d \
  --name open-webui \
  --restart always \
  -p 3000:8080 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  ghcr.io/open-webui/open-webui:main
```

Open `http://localhost:3000` — create an admin account on first launch.

---

## Install via pip (no Docker)

If you prefer not to use Docker:

```bash
pip install open-webui
open-webui serve
```

Then open `http://localhost:8080`.

---

## Connect to your Ollama models

Open WebUI auto-discovers models from Ollama. After launching:

1. Go to **Settings → Connections**
2. Ollama URL should show `http://localhost:11434` — click **Verify**
3. Your models (`sfcc-expert`, `sfcc-expert-docs`, `llama3.1:8b`) appear in the model picker

---

## SFCC workflow in Open WebUI

Instead of bash scripts, you can:

- Select **sfcc-expert** in the model picker
- Upload a repomix-output.txt directly into the chat (drag & drop)
- Ask: *"Analyse this SFRA code for bugs — focus on null pointer risks and Transaction.wrap misuse"*
- Conversation history is preserved — you can follow up: *"Show me the fix for the second issue"*

For documentation:

- Switch to **sfcc-expert-docs**
- Upload the same file
- Ask: *"Generate technical documentation for this cartridge"*

---

## Add shell alias to launch it

```bash
echo 'alias webui="open http://localhost:3000"' >> ~/.zshrc
source ~/.zshrc
```

Then start Docker Desktop, run the container, and type `webui` to open the browser.

---

## Tip: use repomix output as context

Generate the packed file first, then upload it:

```bash
cd ~/projects/sfcc/baccarat
/Users/brunolopes/.volta/bin/npx repomix \
  --config ~/work/ollama/repomix-configs/baccarat.json \
  --output /tmp/baccarat-context.txt
```

Then drag `/tmp/baccarat-context.txt` into the Open WebUI chat window.

---

## Start/stop the container

```bash
docker start open-webui
docker stop open-webui

# Check logs if something is wrong
docker logs open-webui
```
