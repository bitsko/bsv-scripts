#!/usr/bin/env bash
if ! [ -x "$(command -v npm)" ]; then echo "install npm"; exit 1; fi
if [ $(npm list bsv | awk NR==2 | tr -dc '0-9' | cut -c 1) -eq "1" ]; then
        echo "bsvjs 1x installed, needs bsvjs 2x"; exit 1; fi
if [ ! -d node_modules/bsv/ ]; then npm i --prefix "$(pwd)" bsv --save &>/dev/null; fi
if [[ -p "/dev/stdin" ]]; then scriptPubKey="$(cat)"; else
        scriptPubKey="$1"; if [[ -z "$1" ]]; then echo "provide hex input as \$1 or pipe in"; fi; fi
node<<<"let bsv = require('bsv'); var script = bsv.Script.fromHex('$scriptPubKey'); console.log(script.toAsmString())"
