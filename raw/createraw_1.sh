#!/bin/bash
ncli(){ "$HOME"/.novo-bitcoin/bin/novobitcoin-cli $1 $2 $3 $4 $5 $6; }; export -f ncli
createraw(){ vout=0; amount=1
bash<<<"ncli createrawtransaction '[{\"txid\":\"""$(ncli listunspent | jq -r .[$vout].txid)""\",\"vout\":$vout}]' '{\"""$(ncli listunspent | jq -r .[$vout].address)""\":$amount}' 0"; }
firstPartRaw=$(createraw)
echo "$firstPartRaw"
