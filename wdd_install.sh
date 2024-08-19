#!/bin/bash
set -eu
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Permission denied"
    exit
fi
git clone https://github.com/tobilasinde/defacement-checker.git
# cd defacement-checker
./defacement-checker/install.sh
cd ..
rm -r defacement-checker
