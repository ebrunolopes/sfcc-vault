# SFCC Local AI Workspace — Setup & Automation Guide

> **Target hardware:** Apple M1 Pro · 16 GB unified memory  
> **Focus:** Salesforce B2C Commerce Cloud (SFRA architecture)  
> **Last reviewed:** June 2026

---

## ✅ Feasibility Assessment

| Concern | Reality |
|---|---|
| 2 GB repo on 16 GB RAM | ✅ Feasible — after filtering, actual JS/ISML/JSON code is typically < 50 MB |
| 7B model + 64k context on M1 Pro 16 GB | ✅ Fits — model uses ~5–6 GB; 10 GB left for macOS + context |
| SFRA-specific accuracy | ⚠️ Partial — models know general JS patterns; SFCC APIs (e.g. `dw.*`) are niche. Use a tight system prompt + always verify output |
| repomix + Ollama pipeline | ✅ Production-ready toolchain as of 2026 |

**Bottom line: this is fully implementable. The filtering step (repomix) is the most critical part — without it, you will exceed context limits.**

---

## Part 1 — Installing Ollama on macOS

### Step 1 — Download and Install Ollama

1. Go to **https://ollama.com** and click **Download for macOS**.
2. Open the downloaded `.zip` and drag **Ollama.app** to your `/Applications` folder.
3. Open Ollama from Launchpad — you will see a small llama icon in the macOS menu bar.
4. Ollama is now running as a background service on `http://localhost:11434`.

### Step 2 — Verify Ollama is Running

Open Terminal (`⌘ Space` → type "Terminal"):

```bash
ollama --version
# Expected output: ollama version X.X.X

curl http://localhost:11434
# Expected output: Ollama is running
```

### Step 3 — Install Supporting Tools

Install Homebrew if you don't have it:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install Node.js (required for repomix):

```bash
brew install node
node --version   # Should return v20+ or v22+
```

Install repomix globally:

```bash
npm install -g repomix
repomix --version
```

---

## Part 2 — Pull the Recommended Models

Run these commands in Terminal. Pull times depend on your connection speed.

### Primary: SFCC Code Analysis

```bash
# Best coding model for 16 GB — fits fully in unified memory
ollama pull qwen2.5-coder:7b
```

> **Why this model:** Strong at JavaScript, CommonJS patterns, and structured code analysis. Runs at ~40 tokens/sec on M1 Pro 16 GB. Fits in ~5–6 GB of RAM.

### Optional Upgrade: Better Reasoning (if you can tolerate ~20 tok/sec)

```bash
# 14B — slower but significantly better at multi-file reasoning
ollama pull qwen2.5-coder:14b
```

> **RAM budget check:** `qwen2.5-coder:14b` uses ~9 GB. On 16 GB with macOS overhead, this is tight but workable. Close other heavy applications (Docker, Xcode) before running.

### Bonus: General Chat / Documentation Writing

```bash
# Excellent instruction-following, good for writing docs and summaries
ollama pull llama3.1:8b
```

---

## Part 3 — Create the SFCC-Specialist Model

This step creates a custom Ollama model with a system prompt pre-loaded with SFRA context, so you don't repeat instructions on every query.

### Step 1 — Create the Modelfile

```bash
nano ~/Modelfile
```

Paste the following content:

```dockerfile
FROM qwen2.5-coder:7b

# Context window: 64k tokens — handles ~40-50 typical SFCC files
PARAMETER num_ctx 65536

# Low temperature for code analysis (precise, not creative)
PARAMETER temperature 0.2

SYSTEM """
You are a Senior Salesforce B2C Commerce Cloud (SFCC) Architect with deep expertise in SFRA (Storefront Reference Architecture).

STRICT ANALYSIS RULES:
1. Controllers: Validate correct usage of server.append, server.prepend, and server.replace. Flag any route that returns a full response when it should be appending.
2. Performance: Flag any dw.* API call (e.g. ProductMgr.getProduct, BasketMgr.getCurrentBasket) inside a loop without caching. Flag uncached remote includes. Flag missing pagination on SystemObjectMgr queries.
3. Transactions: Flag Transaction.wrap() used unnecessarily (reads don't need transactions). Flag missing Transaction.wrap() around writes to custom objects or system objects.
4. Error handling: Flag missing try/catch around service calls (LocalServiceRegistry). Flag missing Status object returns in scripts.
5. Code style: All generated code must use CommonJS (require/module.exports). No ES6 import/export. No arrow functions in server-side scripts.
6. Security: Flag any use of req.querystring or req.form without validation. Flag output passed to ISML without encoding.

When generating code, always include:
- Relative file path (e.g. cartridges/app_custom/cartridge/controllers/Product.js)
- Proper error handling
- A comment explaining WHY each non-obvious decision was made
"""
```

Save: `Control + O`, then `Enter`. Exit: `Control + X`.

### Step 2 — Build the Custom Model

```bash
ollama create sfcc-expert -f ~/Modelfile
```

Verify it was created:

```bash
ollama list
# Should show: sfcc-expert   ...
```

---

## Part 4 — Organise Your Workspace

Run these commands to set up a clean folder structure:

```bash
mkdir -p ~/AiWorkspace/sfcc
mkdir -p ~/AiWorkspace/python
mkdir -p ~/AiWorkspace/scripts

echo "Workspace created at ~/AiWorkspace"
```

**Expected structure:**

```
~/AiWorkspace/
├── sfcc/
│   ├── baccarat/        ← your SFCC project repos
│   └── my-origines/
├── python/
│   └── scripts/
└── scripts/
    ├── scan_bugs.sh
    └── gerar_doc.sh
```

Clone or move your SFCC repos into `~/AiWorkspace/sfcc/`.

---

## Part 5 — Automation Scripts

### Step 1 — Create the Scripts

```bash
# Create and open the bug scan script
nano ~/AiWorkspace/scripts/scan_bugs.sh
```

Paste this content:

```bash
#!/bin/bash
# SFCC Bug Scanner — powered by Ollama (sfcc-expert)
# Usage: ./scan_bugs.sh <project-folder-name>
# Example: ./scan_bugs.sh baccarat

set -e

if [ -z "$1" ]; then
    echo "❌ Error: Provide the project folder name."
    echo "   Usage: ./scan_bugs.sh <project-name>"
    exit 1
fi

PROJ_DIR="$HOME/AiWorkspace/sfcc/$1"
OUTPUT_TXT="$PROJ_DIR/repomix-output.txt"
REPORT_DIR="$HOME/Desktop/sfcc-reports"
REPORT_OUT="$REPORT_DIR/Bugs_${1}_$(date +%Y-%m-%d).md"

if [ ! -d "$PROJ_DIR" ]; then
    echo "❌ Error: Folder not found: $PROJ_DIR"
    exit 1
fi

mkdir -p "$REPORT_DIR"

echo "🔍 [1/3] Filtering and packaging SFRA code (ignoring node_modules, dist, static)..."
cd "$PROJ_DIR"
npx repomix \
    --include "cartridges/**/*.js,cartridges/**/*.isml,cartridges/**/*.json,cartridges/**/*.xml" \
    --ignore "**/node_modules/**,**/dist/**,**/static/**,**/*.min.js,**/images/**,**/*.png,**/*.jpg,**/*.svg" \
    --output "$OUTPUT_TXT"

echo "🤖 [2/3] Sending to Ollama sfcc-expert for bug analysis..."
{
    echo "# SFCC Bug Report — $1"
    echo "**Generated:** $(date)"
    echo "**Project path:** $PROJ_DIR"
    echo ""
    echo "---"
    echo ""
    cat "$OUTPUT_TXT" | ollama run sfcc-expert \
        "Analyse this SFRA codebase. Find and report: 
        1. Null pointer risks (accessing properties on potentially null objects, e.g. product.custom without null check)
        2. dw.* API calls inside loops without caching
        3. Missing Transaction.wrap() around write operations  
        4. Missing try/catch around service calls
        5. server.append/prepend/replace misuse
        6. Input validation gaps on req.querystring or req.form
        
        For each issue: state the file path, line context, problem, and the corrected code snippet."
} > "$REPORT_OUT"

echo "🧹 [3/3] Cleaning up temp files..."
rm -f "$OUTPUT_TXT"

echo ""
echo "✅ Done! Report saved to: $REPORT_OUT"
```

Save (`Control + O`, `Enter`) and exit (`Control + X`).

```bash
# Create and open the documentation script
nano ~/AiWorkspace/scripts/gerar_doc.sh
```

Paste this content:

```bash
#!/bin/bash
# SFCC Technical Documentation Generator — powered by Ollama (sfcc-expert)
# Usage: ./gerar_doc.sh <project-folder-name>
# Example: ./gerar_doc.sh baccarat

set -e

if [ -z "$1" ]; then
    echo "❌ Error: Provide the project folder name."
    echo "   Usage: ./gerar_doc.sh <project-name>"
    exit 1
fi

PROJ_DIR="$HOME/AiWorkspace/sfcc/$1"
OUTPUT_TXT="$PROJ_DIR/repomix-output.txt"
REPORT_DIR="$HOME/Desktop/sfcc-reports"
REPORT_OUT="$REPORT_DIR/Docs_${1}_$(date +%Y-%m-%d).md"

if [ ! -d "$PROJ_DIR" ]; then
    echo "❌ Error: Folder not found: $PROJ_DIR"
    exit 1
fi

mkdir -p "$REPORT_DIR"

echo "📦 [1/3] Mapping SFRA project structure..."
cd "$PROJ_DIR"
npx repomix \
    --include "cartridges/**/*.js,cartridges/**/*.isml,cartridges/**/*.json,cartridges/**/*.xml" \
    --ignore "**/node_modules/**,**/dist/**,**/static/**,**/*.min.js,**/images/**,**/*.png,**/*.jpg,**/*.svg" \
    --output "$OUTPUT_TXT"

echo "📝 [2/3] Generating architectural documentation with Ollama..."
{
    echo "# Technical Documentation — $1"
    echo "**Generated:** $(date)"
    echo ""
    echo "---"
    echo ""
    cat "$OUTPUT_TXT" | ollama run sfcc-expert \
        "Generate structured technical documentation for this SFRA project.

        Include these sections:
        ## 1. Cartridge Overview
        - List all custom cartridges found
        - Suggested cartridge path order (most specific → least specific)
        - Purpose of each cartridge

        ## 2. Controller Endpoints
        - List each controller and its routes (server.get/post/append/prepend)
        - What each route does
        - Any middleware or hooks observed

        ## 3. External Integrations
        - Services registered via LocalServiceRegistry or dw.svc.ServiceRegistry
        - Payment, shipping, or search integrations detected

        ## 4. Custom Objects & System Object Extensions
        - Custom attribute groups found in XML metadata
        - Custom object definitions

        ## 5. Known Risks or Technical Debt
        - Patterns that may cause issues at scale
        - Anything that should be refactored

        Be precise and technical. Use Markdown headings and code blocks."
} > "$REPORT_OUT"

echo "🧹 [3/3] Cleaning up temp files..."
rm -f "$OUTPUT_TXT"

echo ""
echo "✅ Done! Documentation saved to: $REPORT_OUT"
```

Save and exit.

### Step 2 — Make Scripts Executable

```bash
chmod +x ~/AiWorkspace/scripts/*.sh
```

### Step 3 — Run Your First Analysis

```bash
# Bug scan for the baccarat project:
~/AiWorkspace/scripts/scan_bugs.sh baccarat

# Technical documentation for my-origines:
~/AiWorkspace/scripts/gerar_doc.sh my-origines
```

Reports are saved to `~/Desktop/sfcc-reports/` with the date in the filename.

---

## Part 6 — Recommended Model Stack (Updated for 2026)

| Model | Ollama Pull Command | RAM Usage | Use Case |
|---|---|---|---|
| `qwen2.5-coder:7b` | `ollama pull qwen2.5-coder:7b` | ~5.5 GB | **Primary SFCC code analysis** — fast, fits easily in 16 GB |
| `qwen2.5-coder:14b` | `ollama pull qwen2.5-coder:14b` | ~9 GB | **Complex multi-file debugging** — better reasoning, slower |
| `llama3.1:8b` | `ollama pull llama3.1:8b` | ~5 GB | **Documentation writing** — better prose than code models |
| `deepseek-r1:7b` | `ollama pull deepseek-r1:7b` | ~5 GB | **Chain-of-thought debugging** — explains reasoning step by step |
| `nomic-embed-text` | `ollama pull nomic-embed-text` | ~300 MB | **Future RAG** — embeddings for semantic code search |

> ⚠️ **Do not run multiple large models simultaneously** on 16 GB. Ollama keeps models loaded in memory. Use `ollama stop <model>` to unload before switching.

---

## Improvements Over the Original Instructions

The original guide from Gemini was a good starting point but had these gaps, now corrected here:

| Issue | Original | This Guide |
|---|---|---|
| Reports saved location | Desktop root (messy) | `~/Desktop/sfcc-reports/` subfolder with date in filename |
| Error handling in scripts | Basic | `set -e` + meaningful error messages |
| XML metadata ignored | Not included | Added `**/*.xml` to repomix include (catches custom object definitions) |
| Single model suggestion | Only qwen2.5-coder:7b | Multi-model stack with clear trade-offs per use case |
| Model version | qwen2.5-coder (generic) | Explicit `:7b` tag — avoids ambiguity on future Ollama pulls |
| macOS env tuning | Not mentioned | Add to `~/.zshrc` for consistent behaviour |
| Ollama stop/start | Not mentioned | Documented model unload pattern |

### Optional macOS Environment Tuning

Add to your `~/.zshrc`:

```bash
# Ollama: optimised for M1 Pro 16 GB
export OLLAMA_MAX_LOADED_MODELS=1      # Only 1 model in memory at a time
export OLLAMA_NUM_PARALLEL=1           # Sequential requests (saves RAM)

# Shortcut aliases for SFCC scripts
alias sfcc-bugs="~/AiWorkspace/scripts/scan_bugs.sh"
alias sfcc-docs="~/AiWorkspace/scripts/gerar_doc.sh"
```

Then reload:

```bash
source ~/.zshrc

# Now you can just run:
sfcc-bugs baccarat
sfcc-docs my-origines
```

---

## Known Limitations

- **SFCC `dw.*` API accuracy:** The model does not have official SFCC API docs in its training data. It will make reasonable guesses at method signatures. Always cross-check generated code against [SFCC documentation](https://documentation.b2c.commercecloud.salesforce.com/DOC2/index.jsp).
- **64k context ≈ ~40–50 files:** A large cartridge with 200+ files will be truncated by repomix. For targeted debugging, point repomix at a single cartridge subfolder rather than the full repo.
- **No internet access:** This is fully offline. The model cannot query SFCC or Adyen release notes.
- **Output quality degrades on complex ISML:** ISML is not well-represented in open-source training data. Treat ISML suggestions as starting points, not finished code.
