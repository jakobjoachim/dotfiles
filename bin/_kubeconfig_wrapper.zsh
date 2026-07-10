_kubeconfig_wrapper_resolve_binary() {
    local command_name="$1"
    local wrapper_path="$2"
    local candidate
    local candidate_path

    for candidate in \
        "/opt/homebrew/bin/${command_name}" \
        "/usr/local/bin/${command_name}" \
        ${(f)"$(whence -ap "$command_name" 2>/dev/null)"}
    do
        [[ -x "$candidate" ]] || continue
        candidate_path=$(realpath "$candidate" 2>/dev/null || printf '%s' "$candidate")
        if [[ "$candidate_path" != "$wrapper_path" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

_kubeconfig_wrapper_state_file() {
    local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"

    printf '%s\n' "${KUBECONFIG_STATE_FILE:-$state_home/dotfiles/kubeconfig-state.json}"
}

_kubeconfig_wrapper_read_state_field() {
    local vault="$1"
    local field="$2"
    local state_file

    state_file=$(_kubeconfig_wrapper_state_file)
    [[ -r "$state_file" ]] || return 1

    jq -er --arg vault "$vault" --arg field "$field" \
        'select(.vault == $vault) | .[$field] // empty' "$state_file" 2>/dev/null
}

_kubeconfig_wrapper_write_state() {
    local vault="$1"
    local item_title="$2"
    local context_name="$3"
    local state_file
    local state_dir
    local state_tmp

    [[ -n "$vault" && -n "$item_title" && -n "$context_name" ]] || return 1

    state_file=$(_kubeconfig_wrapper_state_file)
    state_dir="${state_file:h}"
    if ! mkdir -p "$state_dir" 2>/dev/null; then
        return 1
    fi

    state_tmp="${state_file}.tmp.$$"
    if ! jq -n \
        --arg vault "$vault" \
        --arg item_title "$item_title" \
        --arg context "$context_name" \
        --arg updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{ vault: $vault, item_title: $item_title, context: $context, updated_at: $updated_at }' \
        > "$state_tmp" 2>/dev/null
    then
        rm -f "$state_tmp" 2>/dev/null
        return 1
    fi

    if ! mv "$state_tmp" "$state_file"; then
        rm -f "$state_tmp" 2>/dev/null
        return 1
    fi

    chmod 600 "$state_file" 2>/dev/null
}

_kubeconfig_wrapper_context_arg() {
    local arg
    local next_is_context=0

    for arg in "$@"; do
        if (( next_is_context )); then
            [[ -n "$arg" ]] && printf '%s\n' "$arg"
            return 0
        fi

        case "$arg" in
            --context=*)
                printf '%s\n' "${arg#--context=}"
                return 0
                ;;
            --context)
                next_is_context=1
                ;;
        esac
    done

    return 1
}

_kubeconfig_wrapper_config_subcommand() {
    local -a args
    local arg
    local i
    local found_config=0
    local skip_next=0

    args=("$@")
    for (( i = 1; i <= ${#args}; i++ )); do
        arg="${args[$i]}"

        if (( skip_next )); then
            skip_next=0
            continue
        fi

        case "$arg" in
            --context|--kubeconfig|--namespace|-n|--server|--user|--cluster|--token|--as|--as-uid|--cache-dir|--certificate-authority|--client-certificate|--client-key|--request-timeout)
                skip_next=1
                continue
                ;;
            --*=*)
                continue
                ;;
            --)
                continue
                ;;
            -*)
                continue
                ;;
        esac

        if (( found_config )); then
            printf '%s\n' "$arg"
            return 0
        fi

        if [[ "$arg" == "config" ]]; then
            found_config=1
        else
            return 1
        fi
    done

    return 1
}

_kubeconfig_wrapper_config_use_context_arg() {
    local -a args
    local arg
    local i
    local subcommand
    local found_config=0
    local found_use_context=0
    local skip_next=0

    subcommand=$(_kubeconfig_wrapper_config_subcommand "$@") || return 1
    [[ "$subcommand" == "use-context" ]] || return 1

    args=("$@")
    for (( i = 1; i <= ${#args}; i++ )); do
        arg="${args[$i]}"

        if (( skip_next )); then
            skip_next=0
            continue
        fi

        case "$arg" in
            --context|--kubeconfig|--namespace|-n|--server|--user|--cluster|--token|--as|--as-uid|--cache-dir|--certificate-authority|--client-certificate|--client-key|--request-timeout)
                skip_next=1
                continue
                ;;
            --*=*|-*)
                continue
                ;;
        esac

        if (( found_use_context )); then
            printf '%s\n' "$arg"
            return 0
        fi

        if (( found_config )) && [[ "$arg" == "use-context" ]]; then
            found_use_context=1
            continue
        fi

        if [[ "$arg" == "config" ]]; then
            found_config=1
        fi
    done

    return 1
}

_kubeconfig_wrapper_requires_all_contexts() {
    local command_name="$1"
    shift

    local subcommand

    [[ "$command_name" == "kubectl" ]] || return 0

    subcommand=$(_kubeconfig_wrapper_config_subcommand "$@") || return 1
    case "$subcommand" in
        get-contexts|use-context)
            return 0
            ;;
        view)
            if [[ " $* " != *" --minify "* ]]; then
                return 0
            fi
            ;;
    esac

    return 1
}

_kubeconfig_wrapper_download_item() {
    local command_name="$1"
    local vault="$2"
    local config_dir="$3"
    local item_title="$4"
    local output_file="$config_dir/${item_title#kubeconfig-}.yaml"
    local output_tmp

    if [[ ! -s "$output_file" ]]; then
        output_tmp="${output_file}.tmp.$$"
        if ! op document get "$item_title" --vault "$vault" --out-file "$output_tmp" >/dev/null 2>&1; then
            rm -f "$output_tmp" 2>/dev/null
            echo "${command_name}: failed to download '$item_title'" >&2
            return 1
        fi
        if ! mv "$output_tmp" "$output_file"; then
            rm -f "$output_tmp" 2>/dev/null
            echo "${command_name}: failed to write '$output_file'" >&2
            return 1
        fi
        chmod 600 "$output_file" 2>/dev/null
    fi
}

_kubeconfig_wrapper_file_has_context() {
    local command_path="$1"
    local config_file="$2"
    local context_name="$3"

    [[ -s "$config_file" && -n "$context_name" ]] || return 1

    KUBECONFIG="$config_file" "$command_path" config view -o json 2>/dev/null \
        | jq -e --arg context "$context_name" \
            '.contexts[]? | select(.name == $context)' >/dev/null 2>&1
}

_kubeconfig_wrapper_set_current_context() {
    local command_path="$1"
    local config_file="$2"
    local context_name="$3"

    [[ -s "$config_file" && -n "$context_name" ]] || return 1

    KUBECONFIG="$config_file" "$command_path" config use-context "$context_name" >/dev/null 2>&1
}

_kubeconfig_wrapper_download_all() {
    local command_name="$1"
    local vault="$2"
    local config_dir="$3"
    local items
    local count=0
    local item_title
    local output_file
    local -A expected_files
    local -a existing_files

    items=$(op item list --vault "$vault" --tags kubeconfig --format json 2>/dev/null) || {
        echo "${command_name}: failed to list items in vault '$vault'" >&2
        return 1
    }

    if [[ -z "$items" ]] || [[ "$items" == "[]" ]]; then
        echo "${command_name}: no kubeconfig items found in vault '$vault'" >&2
        return 1
    fi

    while IFS= read -r item_title; do
        [[ -n "$item_title" ]] || continue
        output_file="$config_dir/${item_title#kubeconfig-}.yaml"
        _kubeconfig_wrapper_download_item "$command_name" "$vault" "$config_dir" "$item_title" || return 1
        expected_files[$output_file]=1
        count=$((count + 1))
    done < <(jq -r '.[] | .title' <<< "$items")

    if [[ $count -eq 0 ]]; then
        echo "${command_name}: no kubeconfig documents found in vault '$vault'" >&2
        return 1
    fi

    rm -f "$config_dir"/*.yaml.tmp.*(N)

    existing_files=("$config_dir"/*.yaml(N))
    for output_file in $existing_files; do
        if [[ -z "${expected_files[$output_file]}" ]]; then
            rm -f "$output_file"
        fi
    done

    printf '%s\n' "$items"
}

_kubeconfig_wrapper_item_title_for_file() {
    local items="$1"
    local config_file="$2"
    local file_name="${${config_file:t}%.*}"

    jq -er --arg file_name "$file_name" \
        'first(.[] | select((.title | sub("^kubeconfig-"; "")) == $file_name) | .title) // empty' \
        <<< "$items" 2>/dev/null
}

_kubeconfig_wrapper_find_context_file() {
    local command_path="$1"
    local context_name="$2"
    shift 2

    local config_file

    for config_file in "$@"; do
        if _kubeconfig_wrapper_file_has_context "$command_path" "$config_file" "$context_name"; then
            printf '%s\n' "$config_file"
            return 0
        fi
    done

    return 1
}

_kubeconfig_wrapper_current_context() {
    local command_path="$1"

    "$command_path" config current-context 2>/dev/null
}

_kubeconfig_wrapper_run() {
    local command_name="$1"
    local wrapper_input_path="$2"
    shift 2

    if ! command -v op &>/dev/null; then
        echo "${command_name}: 'op' command not found" >&2
        return 1
    fi

    if ! op account get &>/dev/null; then
        echo "${command_name}: not signed in to 1password. Run 'op signin' first." >&2
        return 1
    fi

    local vault="${KUBECONFIG_VAULT:-dev}"
    local config_dir
    local cleanup_config_dir=0
    local items
    local item_title
    local command_path
    local wrapper_path
    local exit_code=1
    local state_item_title
    local state_context
    local target_context
    local context_file
    local context_item_title
    local use_fast_path=0
    local -a kubeconfig_files

    if [[ -n "$KUBECONFIG_SESSION_DIR" ]] \
        && [[ -d "$KUBECONFIG_SESSION_DIR" ]] \
        && [[ "${KUBECONFIG_SESSION_VAULT:-$vault}" == "$vault" ]]
    then
        config_dir="$KUBECONFIG_SESSION_DIR"
    else
        config_dir="$(mktemp -d)" || {
            echo "${command_name}: failed to create temporary kubeconfig directory" >&2
            return 1
        }
        cleanup_config_dir=1
    fi

    {
        wrapper_path=$(realpath "$wrapper_input_path" 2>/dev/null || printf '%s' "$wrapper_input_path")
        command_path=$(_kubeconfig_wrapper_resolve_binary "$command_name" "$wrapper_path")
        if [[ -z "$command_path" ]]; then
            echo "${command_name}: command not found" >&2
            return 127
        fi

        target_context=$(_kubeconfig_wrapper_context_arg "$@" 2>/dev/null || true)
        if [[ -z "$target_context" ]]; then
            target_context=$(_kubeconfig_wrapper_config_use_context_arg "$@" 2>/dev/null || true)
        fi

        if [[ "$command_name" == "kubectl" ]] \
            && ! _kubeconfig_wrapper_requires_all_contexts "$command_name" "$@"
        then
            state_item_title=$(_kubeconfig_wrapper_read_state_field "$vault" item_title 2>/dev/null || true)
            state_context=$(_kubeconfig_wrapper_read_state_field "$vault" context 2>/dev/null || true)
            if [[ -n "$state_item_title" && -n "$state_context" ]]; then
                item_title="$state_item_title"
                context_file="$config_dir/${item_title#kubeconfig-}.yaml"
                if _kubeconfig_wrapper_download_item "$command_name" "$vault" "$config_dir" "$item_title" 2>/dev/null; then
                    if [[ -n "$target_context" ]]; then
                        if _kubeconfig_wrapper_file_has_context "$command_path" "$context_file" "$target_context"; then
                            use_fast_path=1
                        fi
                    elif _kubeconfig_wrapper_file_has_context "$command_path" "$context_file" "$state_context"; then
                        target_context="$state_context"
                        use_fast_path=1
                    fi
                fi
            fi
        fi

        if (( use_fast_path )); then
            export KUBECONFIG="$context_file"
            _kubeconfig_wrapper_set_current_context "$command_path" "$context_file" "$target_context" || true
            "$command_path" "$@"
            exit_code=$?
            if [[ $exit_code -eq 0 && -n "$target_context" ]]; then
                _kubeconfig_wrapper_write_state "$vault" "$item_title" "$target_context" || true
            fi
            return $exit_code
        fi

        items=$(_kubeconfig_wrapper_download_all "$command_name" "$vault" "$config_dir") || return 1

        kubeconfig_files=("$config_dir"/*.yaml(N))
        if (( ${#kubeconfig_files} == 0 )); then
            echo "${command_name}: no kubeconfig files available in '$config_dir'" >&2
            return 1
        fi

        if [[ -n "$state_item_title" ]]; then
            context_file="$config_dir/${state_item_title#kubeconfig-}.yaml"
            if [[ -s "$context_file" ]]; then
                kubeconfig_files=("$context_file" ${kubeconfig_files:#$context_file})
            fi
        fi

        export KUBECONFIG="${(j/:/)kubeconfig_files}"

        "$command_path" "$@"
        exit_code=$?

        if [[ "$command_name" == "kubectl" && $exit_code -eq 0 ]]; then
            if [[ -z "$target_context" ]]; then
                target_context=$(_kubeconfig_wrapper_current_context "$command_path" 2>/dev/null || true)
            fi

            if [[ -n "$target_context" ]]; then
                context_file=$(_kubeconfig_wrapper_find_context_file "$command_path" "$target_context" $kubeconfig_files 2>/dev/null || true)
                if [[ -n "$context_file" ]]; then
                    context_item_title=$(_kubeconfig_wrapper_item_title_for_file "$items" "$context_file" 2>/dev/null || true)
                    if [[ -n "$context_item_title" ]]; then
                        _kubeconfig_wrapper_write_state "$vault" "$context_item_title" "$target_context" || true
                    fi
                fi
            fi
        fi
    } always {
        if [[ $cleanup_config_dir -eq 1 ]] && [[ -n "$config_dir" ]] && [[ -d "$config_dir" ]]; then
            rm -rf "$config_dir"
        fi
    }

    return $exit_code
}
