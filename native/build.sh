#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
swiftc -O DropMenu.swift -o DropMenu \
  -framework AppKit -framework WebKit
echo "Built: $(pwd)/DropMenu"
echo "Run:   DROP_URL=http://10.0.0.218:4321 ./DropMenu &"
