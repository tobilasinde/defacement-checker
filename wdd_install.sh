#!/bin/bash
set -eu
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Permission denied"
    exit
fi
git clone https://github.com/tobilasinde/defacement-checker.git
echo "cloned"
ls
# cd defacement-checker
command ./defacement-checker/install.sh
# cd ..
# command rm -r defacement-checker
