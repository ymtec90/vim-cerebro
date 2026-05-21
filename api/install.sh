#!/bin/bash
echo "🧠 Configurando o ambiente Python para o vim-cerebro..."
cd "$(dirname "$0")"
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
echo "✅ Ambiente configurado com sucesso!"
