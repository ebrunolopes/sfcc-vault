# Deploy Steps — SFCC Ollama Tooling

## 1. Create the folder structure

```bash
mkdir -p ~/work/ollama/scripts
mkdir -p ~/work/ollama/repomix-configs
mkdir -p ~/work/AIWorkspace/work/ai-reports
```

## 2. Move files out of ~/work root into the right place

```bash
mv ~/work/Modelfile        ~/work/ollama/Modelfile
mv ~/work/scan_bugs.sh     ~/work/ollama/scripts/scan_bugs.sh
mv ~/work/gerar_doc.sh     ~/work/ollama/scripts/gerar_doc.sh
mv ~/work/dw_classes.txt   ~/work/ollama/scripts/dw_classes.txt
```

## 3. Replace scripts with updated versions

Download the new scripts from Claude and copy them:

```bash
cp ~/Downloads/scan_bugs.sh   ~/work/ollama/scripts/scan_bugs.sh
cp ~/Downloads/gerar_doc.sh   ~/work/ollama/scripts/gerar_doc.sh
cp ~/Downloads/dw_classes.txt ~/work/ollama/scripts/dw_classes.txt
cp ~/Downloads/Modelfile      ~/work/ollama/Modelfile
```

## 4. Make scripts executable

```bash
chmod +x ~/work/ollama/scripts/*.sh
```

## 5. Add repomix config per project

```bash
cp ~/Downloads/baccarat.repomix.json ~/work/ollama/repomix-configs/baccarat.json
# Duplicate and adapt for other projects:
cp ~/work/ollama/repomix-configs/baccarat.json \
   ~/work/ollama/repomix-configs/my-origines.json
```

## 6. Rebuild the Ollama model with the updated Modelfile

```bash
ollama create sfcc-expert -f ~/work/ollama/Modelfile
# Verify:
ollama list
```

## 7. Add shell aliases to ~/.zshrc

```bash
echo '' >> ~/.zshrc
echo '# SFCC Ollama tooling' >> ~/.zshrc
echo 'export OLLAMA_MAX_LOADED_MODELS=1' >> ~/.zshrc
echo 'export OLLAMA_NUM_PARALLEL=1' >> ~/.zshrc
echo 'alias sfcc-bugs="~/work/ollama/scripts/scan_bugs.sh"' >> ~/.zshrc
echo 'alias sfcc-docs="~/work/ollama/scripts/gerar_doc.sh"' >> ~/.zshrc
source ~/.zshrc
```

## 8. Verify everything works

```bash
# Check aliases
which sfcc-bugs   # should echo the path
sfcc-bugs         # should print usage error (no args = working)

# Check vault report folder exists
ls ~/work/AIWorkspace/work/ai-reports
```

## 9. Run your first analysis

```bash
# Bug scan — full project
sfcc-bugs baccarat

# Bug scan — single cartridge (faster, for large repos)
sfcc-bugs baccarat cartridges/app_baccarat_core

# Documentation
sfcc-docs baccarat
```

Reports land at:
`~/work/AIWorkspace/work/ai-reports/<project>/`

---

## Final folder structure

```
~/work/
├── AIWorkspace/
│   └── work/                        ← Obsidian vault root
│       └── ai-reports/              ← generated reports (visible in Obsidian)
│           ├── baccarat/
│           │   ├── Bugs_2026-06-07_1430.md
│           │   └── Docs_2026-06-07_1445.md
│           └── my-origines/
└── ollama/                          ← all tooling lives here
    ├── Modelfile
    ├── scripts/
    │   ├── scan_bugs.sh
    │   ├── gerar_doc.sh
    │   └── dw_classes.txt
    └── repomix-configs/
        ├── baccarat.json
        └── my-origines.json

~/projects/sfcc/                          ← untouched, scripts point here
├── baccarat/
└── my-origines/
```
