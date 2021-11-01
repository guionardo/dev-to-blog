#!/bin/bash

function unquote() {
    u="${1%\"}"
    u="${u#\"}"
    echo $u
}

function trim() {
    local t="${1##*( )}"
    t="${t%%*( )}"
    echo "$t"
}

function replace() {
    local template=$1
    local tag=$(trim "$2")
    local data_file=$3

    local _tmp=$(mktemp)
    data=$(cat $data_file)

    while IFS= read -r line; do
        line=$(trim "$line")
        if [ "$line" == "$tag" ]; then
            cat $data_file >>$_tmp
        else
            echo "$line" >>$_tmp
        fi
    done <$template

    echo $_tmp
}

echo "* Updating README.md"

tmp_posts=$(mktemp)

for post in posts/*; do
    metadata_file="$post/metadata.json"
    if [ ! -f "$metadata_file" ]; then
        continue
    fi
    title=$(unquote "$(jq '.article.title' $metadata_file)")

    id_file="$post/id.json"
    if [ -f "$id_file" ]; then
        url=$(unquote "$(jq '.url' $id_file)")
    else
        url=""
    fi
    echo "* [$title]($url)" >>$tmp_posts
    echo "  + [$title]"
done

tmp_0=$(replace docs/templates/README.md %POSTS% $tmp_posts)

if [ -f "HISTORY.md" ]; then
    echo "  + Update history"
    tmp_1=$(replace $tmp_0 %HISTORY% "HISTORY.md")
    mv $tmp_1 $tmp_0
fi

mv $tmp_0 README.md
echo "* Updated README.md"
