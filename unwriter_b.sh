#!/bin/bash
txid1="$1"
node<<<"let bsv = require('bsv'); var script = bsv.Script.fromHex('$(curl -s --location --request GET  https://api.whatsonchain.com/v1/bsv/main/tx/$txid1/out/0/hex)');console.log(script.toAsmString())" > temp.file."$txid1"
fileBlob=$(cut -d ' ' -f 3 temp.file."$txid1")
printf '%s' "$fileBlob" | xxd -r -p > "$txid1" 
rm temp.file."$txid1"
unset txid1
unset fileName
unset fileBlob
file "$txid1"
