" ==============================================================================
" AUTO-START DA API FLASK
" ==============================================================================

" Variável para guardar o ID do processo em background [cite: 23]
let s:api_job = -1

function! s:StartCerebroAPI()
    " 1. Verifica se a porta 5000 já está respondendo [cite: 23]
    let l:check_cmd = 'curl -s -o /dev/null http://127.0.0.1:5000/perguntar || echo "offline"' [cite: 23, 24]
    let l:status = system(l:check_cmd) [cite: 24]

    if l:status =~# 'offline' [cite: 24]
        echom "🧠 Inicializando o Segundo Cérebro em background..." [cite: 24]
        
        " Descobre o diretório raiz do plugin dinamicamente
        " <sfile>:p:h pega a pasta atual. Adicionamos :h de novo se o arquivo
        " estiver dentro da pasta 'plugin/'
        let l:plugin_root = expand('<sfile>:p:h:h')
        let l:api_dir = l:plugin_root . '/api'
        
        " Permite que o usuário defina o executável do Python no .vimrc
        " Se não definir, assume 'python3' no PATH do sistema operacional
        let l:python_path = get(g:, 'cerebro_python_cmd', 'python3')
        
        let l:api_script = l:api_dir . '/api.py'

        " Pega o diretório configurado pelo usuário ou usa um padrão [cite: 25]
        let l:wiki_dir_padrao = l:api_dir . "/dados" [cite: 25]
        let l:wiki_dir = expand(get(g:, 'cerebro_wiki_dir', l:wiki_dir_padrao)) [cite: 25]

        " Adicionamos os argumentos ao comando [cite: 25]
        let l:cmd = [l:python_path, l:api_script, '--wiki-dir', l:wiki_dir] [cite: 26]
        
        " Inicia o processo de forma assíncrona na pasta da API [cite: 26]
        let s:api_job = job_start(l:cmd, {'cwd': l:api_dir}) [cite: 26]
    endif
endfunction

function! s:StopCerebroAPI() [cite: 26, 27]
    " Desliga a API apenas se ELA foi iniciada por ESTA instância do Vim [cite: 27]
    if s:api_job != -1 && job_status(s:api_job) ==# 'run' [cite: 27]
        echom "🧠 Desligando o Segundo Cérebro e liberando a RAM..." [cite: 27]
        call job_stop(s:api_job) [cite: 27]
    endif [cite: 27]
endfunction [cite: 27]

" Cria os gatilhos automáticos [cite: 27]
augroup CerebroAutoStart [cite: 27]
    autocmd! [cite: 27]
    autocmd VimEnter * call s:StartCerebroAPI() [cite: 28]
    autocmd VimLeave * call s:StopCerebroAPI() [cite: 28]
augroup END [cite: 28]
