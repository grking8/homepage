#!/usr/bin/env sh

TITLE=$1
IMAGE_PATH=$2
IMAGE_FILE=$(basename $IMAGE_PATH)
DATE=$(date +'%Y-%m-%d')
TITLE_WITH_DASHES=$(echo "${TITLE}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
IMAGE_DIR="assets/images/posts/${DATE}-${TITLE_WITH_DASHES}/"
mkdir $IMAGE_DIR
cp $IMAGE_PATH $IMAGE_DIR
FRONT_MATTER=$'---\nlayout: post\ntitle: '"${TITLE}"''$'\nauthor: familyguy\ncomments: true\ntags:\n---\n\n'
IMAGE_INCLUDE=$'{% include post-image.html name='"\"${IMAGE_FILE}\""' width="100" height="100" alt="" %}'
cat <<EOF > _posts/${DATE}-${TITLE_WITH_DASHES}.md
$FRONT_MATTER$IMAGE_INCLUDE
EOF
