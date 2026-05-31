#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pwd > "$DIR/mock_pwd.txt"
echo "$@" > "$DIR/python_args.txt"
