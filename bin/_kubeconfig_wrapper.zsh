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
    local count=0
    local item_title
    local output_file
    local output_tmp
    local command_path
    local wrapper_path
    local exit_code
    local -A expected_files
    local -a existing_files
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
            expected_files[$output_file]=1
            if [[ ! -s "$output_file" ]]; then
                output_tmp="${output_file}.tmp.$$"
                if ! op document get "$item_title" --vault "$vault" --out-file "$output_tmp" 2>/dev/null; then
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

        kubeconfig_files=("$config_dir"/*.yaml(N))
        if (( ${#kubeconfig_files} == 0 )); then
            echo "${command_name}: no kubeconfig files available in '$config_dir'" >&2
            return 1
        fi
        export KUBECONFIG="${(j/:/)kubeconfig_files}"

        command_path=$(_kubeconfig_wrapper_resolve_binary "$command_name" "$wrapper_path")
        if [[ -z "$command_path" ]]; then
            echo "${command_name}: command not found" >&2
            return 127
        fi

        "$command_path" "$@"
        exit_code=$?
    } always {
        if [[ $cleanup_config_dir -eq 1 ]] && [[ -n "$config_dir" ]] && [[ -d "$config_dir" ]]; then
            rm -rf "$config_dir"
        fi
    }

    return $exit_code
}
