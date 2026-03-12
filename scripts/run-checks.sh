#!/bin/bash
set -u
set -o pipefail

if [ "$#" -eq 0 ]; then
	exec qlty check --all
else
	exec qlty check "$@"
fi
