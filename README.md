# 🧠 vim-cerebro

Um plugin para Vim/Neovim que integra um Segundo Cérebro RAG (Retrieval-Augmented Generation) diretamente no seu editor usando **Ollama** e **LlamaIndex**.

Com o `vim-cerebro`, você pode fazer perguntas sobre suas anotações em Markdown e interagir com modelos locais de Inteligência Artificial sem sair do código, mantendo tudo 100% privado e open-source.

## 🚀 Pré-requisitos

1. **Vim** (com suporte a `job_start`) ou **Neovim**.
2. **Python 3.8+**.
3. **[Ollama](https://ollama.com/)** instalado e rodando no seu sistema.
4. Modelos do Ollama baixados previamente. Por padrão, o plugin utiliza:
   ```bash
   ollama run qwen2.5:1.5b
   ollama pull nomic-embed-text
   ```
