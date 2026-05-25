" ==============================================================================
" AUTO-START DA API FLASK
" ==============================================================================

" Variável para guardar o ID do processo em background
let s:api_job = -1

function! s:StartCerebroAPI()
    " 1. Verifica se a porta 5000 já está respondendo
    let l:check_cmd = 'curl -s -o /dev/null http://127.0.0.1:5000/perguntar || echo "offline"'
    let l:status = system(l:check_cmd)

    if l:status =~# 'offline'
        echom "🧠 Inicializando o Segundo Cérebro em background..."
        
        " Descobre o diretório raiz do plugin dinamicamente
        let l:plugin_root = expand('<sfile>:p:h:h')
        let l:api_dir = l:plugin_root . '/api'
        
        " Permite que o usuário defina o executável do Python no .vimrc
        let l:python_path = get(g:, 'cerebro_python_cmd', 'python3')
        let l:api_script = l:api_dir . '/api.py'

        " Pega o diretório configurado pelo usuário ou usa um padrão
        let l:wiki_dir_padrao = l:api_dir . "/dados"
        let l:wiki_dir = expand(get(g:, 'cerebro_wiki_dir', l:wiki_dir_padrao))

        " Adicionamos os argumentos ao comando
        let l:cmd = [l:python_path, l:api_script, '--wiki-dir', l:wiki_dir]
        
        " Inicia o processo de forma assíncrona na pasta da API
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
    autocmd VimEnter * call s:StartCerebroAPI()
    autocmd VimLeave * call s:StopCerebroAPI()
augroup END
