#!/bin/bash
# run this script in the downloads folder with any number of files downloaded from electrumsv.io,
# and compare the hash listed on github to the hash of the file downloaded

wget -q https://raw.githubusercontent.com/electrumsv/electrumsv/master/build-hashes.txt
GRN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
downloaded=$(ls ElectrumSV*)
while IFS= read -r line; do
    echo ""
    echo "the line below is from https://raw.githubusercontent.com/electrumsv/electrumsv/master/build-hashes.txt"
    rt=$(grep $line build-hashes.txt)
    printf "${GRN} $rt ${NC}"$'\n'
    usr=$(sha256sum $line)
    printf "${RED} $usr ${NC}"$'\n'
    echo "^ sha256sum of the file from the current directory"
    echo ""
done <<< "$downloaded"
