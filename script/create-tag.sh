#!/usr/bin/env sh

set -xe

for tag in "$@"
do
    output=$'---\nlayout: tagpage\ntitle: '"\"Tag: ${tag}\""''$'\ntag: '"${tag}"''$'\n---'
    cat << EOF > tag/${tag}.md
$output
EOF
done