import pytest
import subprocess
import os
import pty
import tempfile
import time

def run_vim_cmd(cmds):
    # Prepare script
    script = ""
    for c in cmds:
        script += c + "\n"

    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix=".vim") as tmp:
        tmp.write(script)
        script_path = tmp.name

    master, slave = pty.openpty()
    # Execute vim without loading user config, and sourcing the test script
    vim_cmd = ["vim", "--clean", "-u", "NONE", "-c", f"source {script_path}"]
    p = subprocess.Popen(vim_cmd, stdin=slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()

    # Close PTY file descriptors
    os.close(master)
    os.close(slave)
    os.remove(script_path)

    return stdout, stderr

def test_start_cerebro_api_spawns_process():
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    mock_python = os.path.join(tests_dir, "mock_python.sh")
    args_file = os.path.join(tests_dir, "python_args.txt")
    pwd_file = os.path.join(tests_dir, "mock_pwd.txt")

    if os.path.exists(args_file): os.remove(args_file)
    if os.path.exists(pwd_file): os.remove(pwd_file)

    cmds = [
        f"let g:cerebro_python_cmd = '{mock_python}'",
        "let g:cerebro_wiki_dir = '/mock/wiki/dir'",
        "source plugin/cerebro.vim",
        "let s:sid = ''",
        "for line in split(execute('scriptnames'), '\\n')",
        "    if line =~ 'cerebro.vim'",
        "        let s:sid = matchstr(line, '^\\s*\\zs\\d\\+\\ze:')",
        "        break",
        "    endif",
        "endfor",
        "if s:sid != ''",
        "    execute 'call <SNR>' . s:sid . '_StartCerebroAPI()'",
        "endif",
        "sleep 1",
        "autocmd! CerebroAutoStart",
        "qall!"
    ]
    run_vim_cmd(cmds)

    assert os.path.exists(args_file), "The mock python script was not executed."
    with open(args_file, "r") as f:
        args = f.read().strip()

    assert "api.py" in args
    assert "--wiki-dir" in args
    assert "/mock/wiki/dir" in args

    with open(pwd_file, "r") as f:
        pwd = f.read().strip()
    assert pwd.endswith("/api")

def test_stop_cerebro_api_avoids_e910_with_non_jobs():
    # Make sure we don't throw an error if StopCerebroAPI is called without a started job
    cmds = [
        "source plugin/cerebro.vim",
        "let s:sid = ''",
        "for line in split(execute('scriptnames'), '\\n')",
        "    if line =~ 'cerebro.vim'",
        "        let s:sid = matchstr(line, '^\\s*\\zs\\d\\+\\ze:')",
        "        break",
        "    endif",
        "endfor",
        "if s:sid != ''",
        "    execute 'call <SNR>' . s:sid . '_StopCerebroAPI()'",
        "endif",
        "autocmd! CerebroAutoStart",
        "qall!"
    ]
    stdout, stderr = run_vim_cmd(cmds)

    # Check that there was no E910 error in the output
    assert b"E910" not in stdout
    assert b"E910" not in stderr
