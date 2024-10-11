#!/usr/bin/env bash
set -euo pipefail

git clone https://repo1.dso.mil/big-bang/bigbang.git
cd ~/bigbang
git checkout tags/$BIG_BANG_VERSION
$HOME/bigbang/scripts/install_flux.sh -u $REGISTRY1_USERNAME -p $REGISTRY1_PASSWORD