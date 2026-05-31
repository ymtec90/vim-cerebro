" ==============================================================================
" Plugin: vim-cerebro
" Descrição: Interface para o Segundo Cérebro RAG (Ollama + LlamaIndex)
" ==============================================================================

if exists('g:loaded_cerebro')
    finish
endif
let g:loaded_cerebro = 1

" Configuração de porta padrão (o usuário pode sobrescrever no .vimrc)
let g:cerebro_api_url = get(g:, 'cerebro_api_url', 'http://127.0.0.1:5000/perguntar')


" Pegamos o caminho raiz do plugin AQUI FORA, onde <sfile> funciona corretamente
let s:plugin_root = expand('<sfile>:p:h:h')

function! s:GetApiToken()
    let l:token_file = s:plugin_root . '/api/.api_token'
    if filereadable(l:token_file)
        return trim(readfile(l:token_file)[0])
    endif
    return ''
endfunction

let s:cerebro_buf = -1

" --- FUNÇÕES PRINCIPAIS ---

function! s:ConsultarCerebro(pergunta, usar_contexto)
    " Prepara o contexto do arquivo atual, se solicitado
    let l:contexto = ""
    if a:usar_contexto
        let l:contexto = join(getline(1, '$'), "\n")
    endif

    " Prepara a janela horizontal abaixo do buffer atual
    if !bufexists(s:cerebro_buf) || bufwinnr(s:cerebro_buf) == -1
        " Abre horizontalmente na parte inferior
        rightbelow new
        let s:cerebro_buf = bufnr('%')
        setlocal buftype=nofile bufhidden=hide noswapfile wrap
        " Define a altura do painel para 5 linhas
        resize 5
    else
        execute bufwinnr(s:cerebro_buf) . 'wincmd w'
    endif

    " Feedback visual inicial
    normal! ggdG
    call setline(1, "🧠 Pergunta: " . a:pergunta)
    if a:usar_contexto
        call append(1, "📎 [Lendo contexto do arquivo atual]")
    endif
    call append(line('$'), "⏳ Consultando a base (Pode continuar programando)...")
    
    " Retorna ao código do usuário
    wincmd p

    " Prepara payload e requisição assíncrona
    let l:json_payload = json_encode({'pergunta': a:pergunta, 'contexto': l:contexto})
    let s:temp_file = tempname()
    let l:token = s:GetApiToken()
    let l:cmd = ['curl', '-s', '-X', 'POST', g:cerebro_api_url, 
               \ '-H', 'Content-Type: application/json', 
               \ '-H', 'Authorization: Bearer ' . l:token,
               \ '-d', l:json_payload, '-o', s:temp_file]

    call job_start(l:cmd, {'close_cb': function('s:CerebroFinalizado')})
endfunction

function! s:CerebroFinalizado(channel)
    if filereadable(s:temp_file)
        let l:raw_json = join(readfile(s:temp_file), "")
        call delete(s:temp_file)
        
        try
            let l:response = json_decode(l:raw_json)
            let l:linhas_texto = []
            
            " 1. Prepara o conteúdo do texto
            if has_key(l:response, 'resposta')
                let l:linhas_texto = ["🧠 Resposta do Segundo Cérebro:", "=============================================", ""] + split(l:response['resposta'], "\n")
            elseif has_key(l:response, 'erro')
                let l:linhas_texto = ["❌ Erro da API: " . l:response['erro']]
            endif
            
            " Se não houver texto, aborta
            if empty(l:linhas_texto)
                return
            endif

            " 2. FECHA A BARRA HORIZONTAL TEMPORÁRIA
            if bufwinnr(s:cerebro_buf) != -1
                execute bufwinnr(s:cerebro_buf) . 'wincmd q'
            endif

            " 3. INTEGRAÇÃO COM FLOATERM
            if exists(':FloatermNew') == 2
                " Cria um arquivo temporário com extensão .md para syntax highlight
                let l:md_file = tempname() . '.md'
                call writefile(l:linhas_texto, l:md_file)
                
                " CORREÇÃO 1: --autoclose=0 garante que a janela fique aberta mesmo se o comando terminar
                let l:floaterm_cmd = 'FloatermNew --title=Cérebro --width=0.7 --height=0.8 --autoclose=0 less ' . l:md_file
                execute l:floaterm_cmd
            
            " 4. FALLBACK: Barra horizontal caso o Floaterm não exista
            else
                if !bufexists(s:cerebro_buf) || bufwinnr(s:cerebro_buf) == -1
                    rightbelow new
                    let s:cerebro_buf = bufnr('%')
                    setlocal buftype=nofile bufhidden=hide noswapfile wrap
                    resize 15
                else
                    execute bufwinnr(s:cerebro_buf) . 'wincmd w'
                endif
                normal! ggdG
                call append(0, l:linhas_texto)
                wincmd p
            endif
            
        catch
            " CORREÇÃO 3: Agora o erro é exibido na barra inferior se algo der errado
            echom "❌ Erro ao exibir resposta: " . v:exception
        endtry
    endif
endfunction

" Variável para armazenar o arquivo temporário da troca de modelo
let s:modelo_temp_file = ""

function! s:TrocarModelo(modelo)
    let l:json_payload = json_encode({'modelo': a:modelo})
    let s:modelo_temp_file = tempname()
    
    " Pega a URL de consulta padrão e substitui 'perguntar' por 'trocar_modelo'
    let l:url = substitute(g:cerebro_api_url, 'perguntar$', 'trocar_modelo', '')

    let l:token = s:GetApiToken()
    let l:cmd = ['curl', '-s', '-X', 'POST', l:url, 
               \ '-H', 'Content-Type: application/json', 
               \ '-H', 'Authorization: Bearer ' . l:token,
               \ '-d', l:json_payload, '-o', s:modelo_temp_file]

    echom "🔄 Carregando o modelo " . a:modelo . " na memória (Aguarde)..."
    call job_start(l:cmd, {'close_cb': function('s:ModeloTrocado')})
endfunction

function! s:ModeloTrocado(channel)
    if filereadable(s:modelo_temp_file)
        let l:raw_json = join(readfile(s:modelo_temp_file), "")
        call delete(s:modelo_temp_file)
        
        try
            let l:response = json_decode(l:raw_json)
            if has_key(l:response, 'sucesso')
                echom "✅ " . l:response['sucesso']
            elseif has_key(l:response, 'erro')
                echom "❌ Erro ao trocar modelo: " . l:response['erro']
            endif
        catch
            echom "❌ Erro ao ler resposta da API."
        endtry
    endif
endfunction

" --- COMANDOS EXPOSTOS ---

command! -nargs=+ Cerebro call s:ConsultarCerebro(<q-args>, 0)
command! -nargs=+ CerebroContexto call s:ConsultarCerebro(<q-args>, 1)
command! -nargs=1 CerebroModelo call s:TrocarModelo(<q-args>)

" --- MAPEAMENTOS (KEYBINDS) ---

" O usuário pode mapear o leader para espaço no seu .vimrc se já não tiver:
" let mapleader = " "

" <leader>c -> Pergunta Simples
nnoremap <Plug>(CerebroPrompt) :Cerebro <C-R>=input("Pergunta para o Cérebro: ")<CR><CR>
if !hasmapto('<Plug>(CerebroPrompt)')
    nmap <leader>c <Plug>(CerebroPrompt)
endif

" <leader>ctx -> Pergunta com o contexto do arquivo atual
nnoremap <Plug>(CerebroContextoPrompt) :CerebroContexto <C-R>=input("Pergunta sobre este arquivo: ")<CR><CR>
if !hasmapto('<Plug>(CerebroContextoPrompt)')
    nmap <leader>ctx <Plug>(CerebroContextoPrompt)
endif

" ==============================================================================
" AUTO-START DA API FLASK
" ==============================================================================



" Variável para guardar o ID do processo em background
let s:api_job = -1

function! s:StartCerebroAPI()
    " 1. Verifica se a porta 5000 já está respondendo (outro Vim pode ter ligado a API)
    " O comando curl falha silenciosamente se a API estiver desligada
    let l:check_cmd = 'curl -s -o /dev/null http://127.0.0.1:5000/ping || echo "offline"'
    let l:status = system(l:check_cmd)

    if l:status =~# 'offline'
        echom "🧠 Inicializando o Segundo Cérebro em background..."
        
        " Usa a variável s:plugin_root que foi resolvida globalmente
        let l:api_dir = s:plugin_root . '/api'
        
        " Permite que o usuário defina o executável do Python no .vimrc
        let l:python_path = get(g:, 'cerebro_python_cmd', 'python3')
        let l:api_script = l:api_dir . '/api.py'

        " Pega o diretório configurado pelo usuário no .vimrc ou usa um padrão
        let l:wiki_dir_padrao = l:api_dir . "/dados"
        let l:wiki_dir = expand(get(g:, 'cerebro_wiki_dir', l:wiki_dir_padrao))

        " Adicionamos os argumentos ao comando
        let l:cmd = [l:python_path, l:api_script, '--wiki-dir', l:wiki_dir]
        
        " Inicia o processo de forma assíncrona, definindo o diretório correto
        let s:api_job = job_start(l:cmd, {'cwd': l:api_dir})
    endif
endfunction

function! s:StopCerebroAPI()
    " Desliga a API apenas se ELA foi iniciada por ESTA instância do Vim
    if s:api_job != -1 && job_status(s:api_job) ==# 'run'
        echom "🧠 Desligando o Segundo Cérebro e liberando a RAM..."
        call job_stop(s:api_job)
    endif
endfunction

" Cria os gatilhos automáticos
augroup CerebroAutoStart
    autocmd!
    " Executa a função de ligar assim que o Vim terminar de carregar a interface
    autocmd VimEnter * call s:StartCerebroAPI()
    " Executa a função de desligar logo antes do Vim fechar
    autocmd VimLeave * call s:StopCerebroAPI()
augroup END
