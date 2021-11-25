#!/bin/bash

function create {

    echo "*** Creating new post ***"
    echo "Title:"
    read title
    if [ -z "$title" ]; then
        exit 1
    fi
    slug=$(echo "$title" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)
    folder="posts/$slug"
    if [ -d $folder ]; then
        echo "Preexistent Post at folder $folder"
        exit 1
    fi
    echo "Tags (separate words with spaces):"
    IFS=', ' read -a tags
    if [ ${#tags[@]} -eq 0 ]; then
        echo "You must inform tags"
        exit 1
    fi

    echo "Series (optional):"
    read series

    url="https://dev.to/guionardo/$slug"

    json_tags=$(printf '%s\n' "${tags[@],,}" | jq -R . | jq -s .)
    tmp=$(
        jq -n \
            '{article:$ARGS.named}' \
            --arg title "$title" \
            --argjson published "true" \
            --arg body_markdown "in the file post.md" \
            --argjson tags "$json_tags" \ 
            --arg series "$series" \     
            --arg canonical_url "$url"
    )    
    mkdir -p $folder
    echo "Created folder: $folder"
    echo $tmp >$folder/metadata.json
    echo "Created metadata file: $folder/metadata.json"
    cat >$folder/post.md <<-EOF
# ${title}

Post created at $(date "+%Y-%m-%d %H:%M")

You can add some image to this folder to set post header
EOF

    echo "Created markdown file: $folder/post.md"
}

#     {
#   "article": {
#     "title": "Hello, World 2!",
#     "published": true,
#     "body_markdown": "Hello DEV, this is my first post",
#     "tags": [
#       "discuss",
#       "help"
#     ],
#     "series": "Hello series",
#     "canonical_url": "https://dev.to/guionardo/hello-world-2"
#   }
# }

# }

case $1 in
create)
    create $2
    ;;
*)
    echo "Unexpected option: $1"
    ;;
esac
