#!/bin/bash

# Calcola la root dell'app Rails (2 livelli sopra lo script)
APP_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUBY_SCRIPT="$APP_ROOT/script/ruby/snai_fetch.rb"

NumArg=5

if [ $# -ne $NumArg ]; then
  echo "Uso: $0 modello gruppo giorno mese anno"
  exit 1
fi

if [ ! -f "$RUBY_SCRIPT" ]; then
  echo "File Ruby non trovato: $RUBY_SCRIPT"
  exit 2
fi

echo "App Rails: $APP_ROOT"
echo "Script Ruby: $RUBY_SCRIPT"

echo "Recupero modello $1 gruppo $2 del $3/$4/$5"

ruby "$RUBY_SCRIPT" -c "$2" -t "$1" -d "$3" -m "$4" -y "$5"
