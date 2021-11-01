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

function show_env(){
    echo "+ ENVIRONMENT"
    echo "  + GITHUB_REPOSITORY = $GITHUB_REPOSITORY"
    echo "  + GITHUB_REF = $GITHUB_REF"
    echo "  + DEVTO_TOKEN = $DEVTO_TOKEN"
    env

    git config --global user.email "guionardo@gmail.com"
    git config --global user.name "Guionardo [action]"
}

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
    local _slug=$(echo "$_title" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)
    if [ -z "$_slug" ]; then
        echo "Invalid title. Empty slug"
        exit 1
    fi
    POST_SLUG=$_slug
    local _expected_canonical_url="https://dev.to/guionardo/${_slug}"
    local _current_canonical_url=$(get_value $POST_METADATA_FILE .article.canonical_url)
    if [ "$_current_canonical_url" != "$_expected_canonical_url" ]; then
        # Updates metadata file for canonical url
        local _tmp=$(mktemp)
        jq --arg slug "$_expected_canonical_url" '.article.canonical_url = $slug' $POST_METADATA_FILE >$_tmp
        mv $_tmp $POST_METADATA_FILE
        git_commit $POST_METADATA_FILE "Fixed canonical_url in $POST_METADATA_FILE = $_expected_canonical_url"
    fi
    POST_CANONICAL_URL=$_expected_canonical_url

    POST_MAIN_IMAGE=$(find_images $POST_FOLDER)
    echo "  + Title [$POST_TITLE]"
    echo "  + $POST_CANONICAL_URL"
    echo "  + Main image: $POST_MAIN_IMAGE"
}

function add_history() {
    if [ ! -f "HISTORY.md" ]; then
        echo "# HISTORY\n" > HISTORY.md
    fi

    echo "${date -R} $1" >> HISTORY.md
    echo "  + $1"
    git_commit HISTORY.md "Updated HISTORY.md"
}

function git_commit() {
    return
    local _file_added=$1
    local _git_commit_message=$2
    local _do_not_push=$3
    if [ ! -z $_file_added ]; then
        echo "  + [GIT] git add $_file_added"
        git add "$_file_added"
        if [ "$?" != "0" ]; then
            echo "  + [GIT-FAIL] $?"
            return
        fi

        echo "  + [GIT] git commit -m \"$_git_commit_message\""
        git commit -m "$_git_commit_message"
        if [ "$?" != "0" ]; then
            echo "  + [GIT-FAIL] $?"
            return
        fi
    fi
    if [ ! -z $_do_not_push ]; then
        echo "  + [GIT] git push"
        git push
        if [ "$?" != "0" ]; then
            echo "  + [GIT-FAIL] $?"
            return
        fi
    fi
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
            "https://dev.to/api/articles/guionardo/${_slug}")

        case $_http_status in
        200)
            _id_from_file=$(get_value $_tmp '.id')
            if [ "$_id_from_file" == "null" ]; then
                echo "  + Invalid content from response"
                cat $_tmp
            else
                POST_ID=$_id_from_file
                mv $_tmp $_id_file
                git_commit $_id_file "Added file $_id_file for post $_title #$_id_from_file" 1
                _git=true
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
    jq --arg url "$POST_CANONICAL_URL" '.article.canonical_url = $url' $_tmp >$_tmp2
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
        # _http_status=$(curl -X POST -s -H "Content-Type: application/json" \
        #     -H "api-key: ${DEVTO_TOKEN}" \
        #     -o "$_response_file" \
        #     -d @$_publishing_file \
        #     -w "%{http_code}" \
        #     https://dev.to/api/articles)
        # parse_response_file $? $_http_status $_response_file $1
        if [ "$CURL_HTTP_STATUS" -eq 201 ]; then
            add_history "Created post: #$POST_ID - $POST_TITLE ($POST_CANONICAL_URL)"            
        else
            add_history "Error creating post: #$POST_ID - $CURL_HTTP_STATUS - $CURL_RESPONSE_DATA"
        fi
    else
        # Update post
        do_curl "PUT" "https://dev.to/api/articles/$POST_ID" $_publishing_file
        # _http_status=$(curl -X PUT -s -H "Content-Type: application/json" \
        #     -H "api-key: ${DEVTO_TOKEN}" \
        #     -o "$_response_file" \
        #     -d @_publishing_file \
        #     -w "%{http_code}" \
        #     https://dev.to/api/articles/$POST_ID)
        # parse_response_file $? $_http_status $_response_file $1
        if [ "$CURL_HTTP_STATUS" -eq 200 ]; then
            echo "  + Updated post: #$POST_ID - $POST_TITLE ($POST_CANONICAL_URL)"
        else
            echo "  + Error updating post: #$POST_ID - $CURL_HTTP_STATUS - $CURL_RESPONSE_DATA"
        fi
        # validate_post_id $1
    fi
    if [ -f "$_response_file" ]; then
        rm $_response_file
    fi
}

# function get_id_and_url_from_metadata() {
#     POST_ID=""
#     POST_CANONICAL_URL=""
#     local _post_folder=$1
#     local _metadata_file="$1/metadata.json"
#     if [ ! -f $_metadata_file ]; then
#         echo "Metadata file not found: $_metadata_file"
#         return
#     fi

#     # validates canonical_url
#     local _current_canonical_url=$(get_value $_metadata_file .article.canonical_url)
#     local _title=$(get_value $_metadata_file .article.title)
#     local _slug=$(echo "$_title" | iconv -t ascii//TRANSLIT | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z)
#     local _expected_canonical_url="https://dev.to/guionardo/${_slug}"

#     local _git=false
#     if [ "$_current_canonical_url" != "$_expected_canonical_url" ]; then
#         # Updates metadata file for canonical url
#         local _tmp=$(mktemp)
#         jq --arg slug "$_expected_canonical_url" '.article.canonical_url = $slug' $_metadata_file >$_tmp
#         mv $_tmp $_metadata_file
#         git_commit $_metadata_file "Fixed canonical_url in $_metadata_file = $_expected_canonical_url" 1
#         _git=true
#     fi
#     POST_CANONICAL_URL=$_expected_canonical_url

#     local _id_file="$1/id.json"
#     local _id_from_file
#     if [ -f "$_id_file" ]; then
#         _id_from_file=$(get_value $_id_file '.id')
#         if [ "$_id_from_file" == "null" ]; then
#             echo "Invalid id file - will be recreated"
#             rm $_id_file
#         else
#             POST_ID=$_id_from_file
#             POST_ID_FILE=$_id_file
#         fi
#     fi

#     if [ ! -f "$_id_file" ]; then
#         # Post doesnt have a id file
#         local _tmp=$(mktemp)
#         local _http_status=$(curl -X GET -s -o "$_tmp" -w "%{http_code}" \
#             "https://dev.to/api/articles/guionardo/${_slug}")

#         if [ "$_http_status" == "200" ]; then
#             _id_from_file=$(get_value $_tmp '.id')
#             if [ "$_id_from_file" == "null" ]; then
#                 echo "Invalid content from response"
#                 cat $_tmp
#             else
#                 POST_ID=$_id_from_file
#                 POST_ID_FILE=$_id_file
#                 mv $_tmp $_id_file
#                 git_commit $_id_file "Added file $_id_file for post $_title #$_id_from_file" 1
#                 _git=true
#             fi
#         else
#             echo "Failed to get id from post - HTTP STATUS=$_http_status"
#             cat $_tmp
#             rm $_tmp
#         fi
#     fi

#     if [ $_git == true ]; then
#         git_commit unexistent.json just_push
#     fi

# }

function validate_post_id() {
    if [ -d $1 ]; then
        file_id="$1/id.json"
    else
        if [ -f $1 ]; then
            file_id="$1"
        else
            echo "Post id file not found $1"
        fi
    fi
    if [ -f $file_id ]; then
        id=$(jq '.id' $file_id)
        if [ "$id" -eq "$id" ]; then
            POST_ID=$id
            echo "Post id #$id"
        else
            echo "Invalid file $file_id"
            rm $file_id
        fi
    fi
}

function unquote() {
    u="${1%\"}"
    u="${u#\"}"
    echo $u
}

function unescape_file() {
    cat $1 | sed 's/\\\\/\\/g' >unescaped.tmp
    mv unescaped.tmp $1
}

function get_value() {
    POST_SOURCE_FILE=$1
    source_tag=$2
    u=$(jq "$source_tag" $POST_SOURCE_FILE)
    unquote "$u"
}

function find_images() {
    GH_REPO="${GITHUB_REPOSITORY:-guionardo/dev-to-blog}"
    for f in "$1"/*; do
        if [[ $f == *.png || $f == *.jpg || $f == *.jpeg ]]; then
            echo "https://raw.githubusercontent.com/$GH_REPO/main/$f"
            return
        fi
    done
}

function set_publish_id() {
    id_file="$1/id.json"
    tmp=$(mktemp)
    jq --arg id "$2" '.id = $id' $id_file >$tmp
    mv $tmp $id_file
}

function validate_metadata_file() {
    metadata_file=$1
    slug=$2
    current_slug=$(jq '.article.canonical_url' $metadata_file)
    current_slug=$(unquote $current_slug)
    expected_slug="https://dev.to/guionardo/${slug}"
    if [ "$current_slug" == "$expected_slug" ]; then
        return
    fi
    tmp=$(mktemp)
    jq --arg slug "$expected_slug" '.article.canonical_url = $slug' $metadata_file >$tmp
    echo "Updated canonical_url: $expected_slug"
    mv $tmp $metadata_file

    git_commit $metadata_file "Updated canonical_url: $expected_slug"
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

    # if [ "$http_status" -gt 399 ]; then

    if [ "$response_file_id" == "null" ]; then
        if [ "$http_status" == "422" ]; then
            #TODO: Tratar retorno 422
            # Post exists but doesnt have a id file
            used_canonical_url=$(jq '.article.canonical_url' $POST_METADATA_FILE)
            tmp_0=$(mktemp)
            http_status=$(
                curl -X GET -s -o "$tmp_0" -w "%{http_code}" \
                    "https://dev.to/api/articles/guionardo/${slug}"
            )
            if [ "$http_status" == "200" ]; then
                response_file_id=$(jq '.id' $tmp_)
                echo "Post id got from URL $used_canonical_url = $ #$response_file_id"
                mv $tmp_ $POST_ID_FILE
                post_title=$(get_value $POST_METADATA_FILE .article.title)
                git_commit $POST_ID_FILE "Updated id file of post $1 - $post_title"
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
    git_commit $POST_ID_FILE "Updated id file of post $POST_FOLDER - $POST_TITLE"
}

show_env
validate_files $1
parse_title_canonical_url
parse_post_id
publishing_file=$(get_publishing_file)

publish_file $publishing_file

rm $publishing_file
exit 0
