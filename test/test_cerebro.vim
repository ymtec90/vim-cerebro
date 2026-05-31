let v:errors = []

" Setup fake curl
let s:mock_dir = tempname()
call mkdir(s:mock_dir, 'p')
let s:fake_curl = s:mock_dir . '/curl'

" Bash script to find the last argument correctly (using a loop instead of eval)
let s:fake_curl_script = [
\ '#!/usr/bin/env bash',
\ 'echo "$@" > ' . s:mock_dir . '/curl_args.txt',
\ 'for last; do true; done',
\ 'echo ''{"sucesso": "Modelo trocado"}'' > "$last"'
\ ]
call writefile(s:fake_curl_script, s:fake_curl)
call system('chmod +x ' . s:fake_curl)
let $PATH = s:mock_dir . ':' . $PATH

" Load plugin
let g:cerebro_api_url = 'http://127.0.0.1:5000/perguntar'
source plugin/cerebro.vim

function! Test_TrocarModelo()
    CerebroModelo test_model_123
    sleep 500m

    let l:curl_args_file = s:mock_dir . '/curl_args.txt'
    if !filereadable(l:curl_args_file)
        call add(v:errors, "Fake curl was not executed.")
        return
    endif

    let l:args = readfile(l:curl_args_file)[0]

    call assert_match('http://127.0.0.1:5000/trocar_modelo', l:args, "URL should end with /trocar_modelo")
    call assert_match('{"modelo":"test_model_123"}', l:args, "Payload should contain the model name")
    call assert_match('-X POST', l:args)
    call assert_match('-H Content-Type: application/json', l:args)
endfunction

call Test_TrocarModelo()

if empty(v:errors)
    echo "All tests passed."
    cquit 0
else
    for err in v:errors
        echo err
    endfor
    cquit 1
endif
