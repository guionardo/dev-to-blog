#!/bin/bash
# Publish posts to dev-to

POST_ID=""
POST_ID_FILE=""
POST_FOLDER=""
POST_TITLE=""
POST_SLUG=""
POST_CANONICAL_URL=""
POST_METADATA_FILE=""
POST_SOURCE_FILE=""
POST_MAIN_IMAGE=""

CURL_HTTP_STATUS=0
CURL_RESPONSE_DATA=""

# Validates files existing in post folder
function validate_files() {
    POST_FOLDER=$1
    if [ ! -d "$1" ]; then
        echo "Folder not found: $1"
        exit 1
    fi

    POST_METADATA_FILE="$POST_FOLDER/metadata.json"
    if [ ! -f "$POST_METADATA_FILE" ]; then
        echo "Metadata file not found: $POST_METADATA_FILE"
        exit 1
    fi

    POST_SOURCE_FILE="$1/post.md"
    if [ ! -f "$POST_SOURCE_FILE" ]; then
        echo "Source file not found: $POST_SOURCE_FILE"
        exit 1
    fi

    POST_ID_FILE="$1/id.json"
    echo "+ FOLDER $POST_FOLDER"
    echo "  + $POST_METADATA_FILE"
    echo "  + $POST_SOURCE_FILE"

    validate_post_id_

    if [ -f "$POST_ID_FILE" ]; then
        echo "  + $POST_ID_FILE (update post)"
    else
        echo "  + $POST_ID_FILE (not found = create post)"
    fi
}

function parse_title_canonical_url() {
    local _title=$(get_value $POST_METADATA_FILE .article.title)
    if [ -z "$_title" ]; then
        echo "Invalid metadata. Empty title."
        exit 1
    fi
    POST_TITLE=$_title
    local _expected_canonical_url
    local _slug
    local _id_url
    if [ -f $POST_ID_FILE ]; then
        _id_url=$(get_value $POST_ID_FILE .url)
    fi
    if [ "$_id_url" == "null" ] || [ -z $_id_url ]; then
        _slug=$(echo "$_title" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)
        if [ -z "$_slug" ]; then
            echo "Invalid title. Empty slug"
            exit 1
        fi
        _expected_canonical_url="https://dev.to/$DEVTO_USER/${_slug}"
        POST_SLUG=$_slug
    else
        _slut=$(basename "$_id_url")
        _expected_canonical_url="$_id_url"
    fi

    local _current_canonical_url=$(get_value $POST_METADATA_FILE .article.canonical_url)
    if [ "$_current_canonical_url" != "$_expected_canonical_url" ]; then
        # Updates metadata file for canonical url
        local _tmp=$(mktemp)
        jq --arg slug "$_expected_canonical_url" '.article.canonical_url = $slug' $POST_METADATA_FILE >$_tmp
        mv $_tmp $POST_METADATA_FILE
    fi
    POST_CANONICAL_URL=$_expected_canonical_url

    POST_MAIN_IMAGE=$(find_images $POST_FOLDER)
    echo "  + Title [$POST_TITLE]"
    echo "  + $POST_CANONICAL_URL"
    echo "  + Main image: $POST_MAIN_IMAGE"
}

function add_history() {
    if [ ! -f "HISTORY.md" ]; then
        echo "# HISTORY" >HISTORY.md
        echo "" >>HISTORY.md
    fi

    echo "* $(date -R) $1" >>HISTORY.md
    echo "  + $1"
}

function validate_post_id_() {
    local _id_from_file
    if [ -f "$POST_ID_FILE" ]; then
        _id_from_file=$(get_value $POST_ID_FILE '.id')
        if [ "$_id_from_file" -eq "$_id_from_file" ] 2>/dev/null; then
            echo "  + Validate post #$_id_from_file"
            local _tmp=$(mktemp)
            local _http_status=$(curl -X GET -s -o "$_tmp" -w "%{http_code}" \
                "https://dev.to/api/articles/${_id_from_file}")
            if [ "$_http_status" == "404" ]; then
                echo "  + $POST_ID_FILE - id not found at dev.to: will be recreated"
                rm $POST_ID_FILE
            else
                POST_ID=$_id_from_file
                echo "  + Post ID=$POST_ID"
            fi
        else
            echo "  + $POST_ID_FILE - Invalid id file: will be recreated"
            rm $POST_ID_FILE
        fi
    fi
}

function parse_post_id() {
    local _id_from_file

    if [ ! -f "$POST_ID_FILE" ]; then
        # Post doesnt have a id file
        local _tmp=$(mktemp)
        local _http_status=$(curl -X GET -s -o "$_tmp" -w "%{http_code}" \
            "https://dev.to/api/articles/$DEVTO_USER/${_slug}")

        case $_http_status in
        200)
            _id_from_file=$(get_value $_tmp '.id')
            if [ "$_id_from_file" == "null" ]; then
                echo "  + Invalid content from response"
                cat $_tmp
            else
                POST_ID=$_id_from_file
                mv $_tmp $_id_file
            fi
            ;;
        404)
            echo "  + Post ${POST_CANONICAL_URL} inexistent"
            ;;
        *)
            echo "  + Failed to get id from post - HTTP STATUS=$_http_status $(cat $_tmp)"

            rm $_tmp
            ;;
        esac

    fi

}

function get_publishing_file() {
    body_markdown=$(cat "$POST_SOURCE_FILE" | jq '.' --raw-input --slurp)
    body_markdown=$(unquote "$body_markdown")
    local _tmp=$(mktemp)
    jq --arg md "$body_markdown" '.article.body_markdown = $md' $POST_METADATA_FILE >$_tmp
    local _tmp2=$(mktemp)
    # jq --arg url "$POST_CANONICAL_URL" '.article.canonical_url = $url' $_tmp >$_tmp2
    jq 'del(.article.canonical_url)' $_tmp >$_tmp2
    if [ -z "$POST_MAIN_IMAGE" ]; then
        jq 'del(.article.main_image)' $_tmp2 >$_tmp
    else
        jq --arg main_image "$POST_MAIN_IMAGE" '.article.main_image = $main_image' $_tmp2 >$_tmp
    fi

    rm $_tmp2
    unescape_file $_tmp
    echo $_tmp
}

function do_curl() {
    local _method=$1
    local _url=$2
    local _publishing_file=$3
    local _response_file=$(mktemp --dry-run --suffix=.json publisherXXXX)
    echo "  + CURL $_method $_url"
    echo "  +  $(cat $_publishing_file)"
    local _http_status=$(
        curl -X $_method -s \
            -H "Content-Type: application/json" \
            -H "api-key: ${DEVTO_TOKEN}" \
            -o "$_response_file" \
            -d @$_publishing_file \
            -w "%{http_code}" \
            $_url
    )
    CURL_HTTP_STATUS=$_http_status
    CURL_RESPONSE_DATA=$(cat $_response_file)
    echo "  +  HTTP STATUS = $_http_status"
    parse_response_file $? $_http_status $_response_file $_publishing_file
    if [ -f "$_response_file" ]; then
        rm $_response_file
    fi

}

function publish_file() {
    local _publishing_file=$1
    local _response_file=$(mktemp --dry-run --suffix=.json publisherXXXX)
    local _http_status
    if [ -z "$POST_ID" ]; then
        # Create post
        do_curl "POST" "https://dev.to/api/articles" $_publishing_file
        if [ "$CURL_HTTP_STATUS" -eq 201 ]; then
            add_history "Created post: #$POST_ID - [$POST_TITLE]($POST_CANONICAL_URL)"
        else
            add_history "Error creating post: #$POST_ID - $CURL_HTTP_STATUS - $CURL_RESPONSE_DATA"
        fi
    else
        # Update post
        do_curl "PUT" "https://dev.to/api/articles/$POST_ID" $_publishing_file
        if [ "$CURL_HTTP_STATUS" -eq 200 ]; then
            echo "  + Updated post: #$POST_ID - [$POST_TITLE]($POST_CANONICAL_URL)"
        else
            echo "  + Error updating post: #$POST_ID - $CURL_HTTP_STATUS - $CURL_RESPONSE_DATA"
        fi
        add_history "Updated post: #$POST_ID - [$POST_TITLE]($POST_CANONICAL_URL)"
    fi
    if [ -f "$_response_file" ]; then
        rm $_response_file
    fi
}

function unquote() {
    local u="${1%\"}"
    u="${u#\"}"
    echo $u
}

function unescape_file() {
    cat $1 | sed 's/\\\\/\\/g' | sed 's/\\\\/\\/g' >unescaped.tmp
    mv unescaped.tmp $1
}

function get_value() {
    POST_SOURCE_FILE=$1
    source_tag=$2
    u=$(jq "$source_tag" $POST_SOURCE_FILE)
    unquote "$u"
}

function find_images() {
    for f in "$1"/*; do
        if [[ $f == *.png || $f == *.jpg || $f == *.jpeg ]]; then
            echo "https://raw.githubusercontent.com/$GITHUB_REPOSITORY/main/$f"
            return
        fi
    done
}

function parse_response_file() {
    exit_status=$1
    http_status=$2
    response_file=$3
    post_folder=$4
    if [ "$exit_status" != "0" ]; then
        echo "  + cURL exit status = $exit_status"
    fi
    if [ ! -f $response_file ]; then
        echo "  + cURL response file inexistent ($response_file)"
        return
    fi

    echo "  + cURL HTTP status = $http_status ($(cat $response_file))"

    local response_file_id=$(jq '.id' $response_file)

    case $http_status in
    422)
        echo "  + HTTP request failed - $http_status $(cat $post_folder)"
        ;;
    esac
    
    if [ "$response_file_id" == "null" ]; then
        if [ "$http_status" == "422" ]; then            
            # Post exists but doesnt have a id file
            used_canonical_url=$(jq '.article.canonical_url' $POST_METADATA_FILE)
            tmp_0=$(mktemp)
            http_status=$(
                curl -X GET -s -o "$tmp_0" -w "%{http_code}" \
                    "https://dev.to/api/articles/$DEVTO_USER/${slug}"
            )
            if [ "$http_status" == "200" ]; then
                response_file_id=$(jq '.id' $tmp_)
                echo "Post id got from URL $used_canonical_url = $ #$response_file_id"
                mv $tmp_ $POST_ID_FILE
                return
            fi
        else
            echo "  + cURL response file doesn't have a 'id' field: $(cat $response_file)"
            return
        fi
    fi

    create_commit=false

    # Gets id from response file
    if [ ! -f $POST_ID_FILE ]; then
        echo "  + id file created - $POST_ID_FILE"
        mv $response_file $POST_ID_FILE
        create_commit=true
    else
        current_id=$(jq '.id' $POST_ID_FILE)
        if [ "$current_id" == "$response_file_id" ]; then
            echo "  + Post id doesn't changed: $current_id"
            return
        fi
        echo "  + id file updated: $response_file_id"
        mv $response_file $POST_ID_FILE
        create_commit=true
    fi

    if [ $create_commit = false ]; then
        return
    fi

    post_title=$(get_value $POST_METADATA_FILE .article.title)
}

validate_files $1
parse_title_canonical_url
parse_post_id
publishing_file=$(get_publishing_file)

publish_file $publishing_file

rm $publishing_file
exit 0
