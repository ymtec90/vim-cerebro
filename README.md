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
   
## 📦 Instalação

Usando [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "seu-usuario/vim-cerebro",
    build = "cd api && ./install.sh", -- Automatiza a instalação das dependências Python
    config = function()
        -- Configurações opcionais
        vim.g.cerebro_python_cmd = vim.fn.stdpath("data") .. "/lazy/vim-cerebro/api/.venv/bin/python"
        vim.g.cerebro_wiki_dir = "~/minhas_anotacoes"
    end
}
```

Usando [vim-plug](https://github.com/junegunn/vim-plug)
```vimscript
Plug 'seu-usuario/vim-cerebro', { 'do': 'cd api && ./install.sh' }

" Especifique o caminho do executável do Python dentro do ambiente virtual criado
let g:cerebro_python_cmd = '~/.vim/plugged/vim-cerebro/api/.venv/bin/python'
" O caminho para a pasta onde você guarda seus resumos e notas
let g:cerebro_wiki_dir = '~/minhas_anotacoes'
```

## ⌨️ Comandos e Atalhos

O plugin expõe os seguintes atalhos (mapeados para a tecla `<leader>`):

`<leader>c`: Abre um prompt para uma pergunta simples para a IA.

`<leader>ctx`: Envia a pergunta junto com todo o contexto do arquivo atual que você está editando.

Comandos manuais disponíveis:

* `:Cerebro [pergunta]`
* `:CerebroContexto [pergunta]`
* `:CerebroModelo [nome-do-modelo] (ex: :CerebroModelo llama3)`

## 🛠️ Como funciona?

O plugin inicia um servidor Flask em background de forma assíncrona assim que o Vim é aberto. O LlamaIndex lê a sua pasta de anotações (arquivos `.md`) e cria um banco de dados vetorial em memória para realizar buscas por similaridade antes de enviar o contexto para o LLM. Ao fechar o Vim, o servidor é encerrado automaticamente, liberando a RAM.
