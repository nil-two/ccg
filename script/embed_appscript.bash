#!/bin/bash
set -eu

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

target_file=$(basename "$PWD")
embed_marker_start='" appscript:start'
embed_marker_end='" appscript:end'
embed_file="src/$(basename "$PWD").vim"
sed -i \
  -e '/^'"$embed_marker_start"'$/r '"$embed_file"'' \
  -e '/^'"$embed_marker_start"'$/i'"$embed_marker_start"'' \
  -e '/^'"$embed_marker_end"'$/i'"$embed_marker_end"'' \
  -e '/^'"$embed_marker_start"'$/,/^'"$embed_marker_end"'$/d' \
  "$target_file"
