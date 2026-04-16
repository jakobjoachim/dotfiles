_kubeconfigs_resolve_wrapper_helper() {
    if typeset -f _kubeconfig_wrapper_run >/dev/null 2>&1; then
        return 0
    fi

    local helper_path="$DOTFILES/bin/_kubeconfig_wrapper.zsh"
    if [[ -f "$helper_path" ]]; then
        source "$helper_path"
    fi

    typeset -f _kubeconfig_wrapper_run >/dev/null 2>&1
}

_kubeconfigs_now_epoch() {
    if ! zmodload zsh/datetime 2>/dev/null; then
        date +%s
        return
    fi

    printf '%s\n' "$EPOCHSECONDS"
}

_kubeconfigs_session_timeout_seconds() {
    local timeout="${KUBECONFIG_SESSION_TIMEOUT:-600}"

    if ! [[ "$timeout" =~ '^[0-9]+$' ]] || (( timeout <= 0 )); then
        timeout=600
    fi

    printf '%s\n' "$timeout"
}

_kubeconfigs_touch_session() {
    export KUBECONFIG_SESSION_LAST_USED="$(_kubeconfigs_now_epoch)"
}

_kubeconfigs_expire_session_if_idle() {
    local timeout
    local now
    local last_used

    if [[ -z "$KUBECONFIG_SESSION_DIR" ]] || [[ ! -d "$KUBECONFIG_SESSION_DIR" ]]; then
        return 0
    fi

    last_used="${KUBECONFIG_SESSION_LAST_USED:-}"
    if [[ -z "$last_used" ]] || ! [[ "$last_used" =~ '^[0-9]+$' ]]; then
        _kubeconfigs_clear_session
        return 0
    fi

    timeout=$(_kubeconfigs_session_timeout_seconds)
    now=$(_kubeconfigs_now_epoch)
    if (( now - last_used >= timeout )); then
        _kubeconfigs_clear_session
    fi
}

_kubeconfigs_precmd() {
    _kubeconfigs_expire_session_if_idle
}

_kubeconfigs_clear_session() {
    if [[ -n "$KUBECONFIG_SESSION_DIR" ]] && [[ -d "$KUBECONFIG_SESSION_DIR" ]]; then
        rm -rf "$KUBECONFIG_SESSION_DIR"
    fi

    unset KUBECONFIG_SESSION_DIR
    unset KUBECONFIG_SESSION_VAULT
    unset KUBECONFIG_SESSION_READY
    unset KUBECONFIG_SESSION_LAST_USED
    unset KUBECONFIG
}

_kubeconfigs_ensure_session() {
    local command_name="$1"
    local vault="${KUBECONFIG_VAULT:-dev}"
    local session_root
    local vault_key
    local session_dir

    if [[ -n "$KUBECONFIG_SESSION_DIR" ]] && [[ -d "$KUBECONFIG_SESSION_DIR" ]]; then
        if [[ "${KUBECONFIG_SESSION_VAULT:-$vault}" == "$vault" ]]; then
            return 0
        fi

        _kubeconfigs_clear_session
    fi

    session_root="${KUBECONFIG_SESSION_ROOT:-${TMPDIR:-/tmp}}"
    vault_key="${vault//\//_}"

    if ! mkdir -p "$session_root" 2>/dev/null; then
        echo "${command_name}: failed to create kubeconfig session root" >&2
        return 1
    fi

    session_dir=$(mktemp -d "${session_root%/}/kubeconfig-${vault_key}.XXXXXX") || {
        echo "${command_name}: failed to create kubeconfig session directory" >&2
        return 1
    }

    chmod 700 "$session_dir" 2>/dev/null
    export KUBECONFIG_SESSION_DIR="$session_dir"
    export KUBECONFIG_SESSION_VAULT="$vault"
    unset KUBECONFIG_SESSION_READY
    _kubeconfigs_touch_session
}

_kubeconfigs_session_has_files() {
    local -a kubeconfig_files

    if [[ -z "$KUBECONFIG_SESSION_DIR" ]] || [[ ! -d "$KUBECONFIG_SESSION_DIR" ]]; then
        return 1
    fi

    kubeconfig_files=("$KUBECONFIG_SESSION_DIR"/*.yaml(N))
    (( ${#kubeconfig_files} > 0 ))
}

_kubeconfigs_run_from_session() {
    local command_name="$1"
    shift

    local wrapper_path="$DOTFILES/bin/${command_name}"
    local command_path
    local -a kubeconfig_files

    kubeconfig_files=("$KUBECONFIG_SESSION_DIR"/*.yaml(N))
    if (( ${#kubeconfig_files} == 0 )); then
        return 1
    fi

    wrapper_path=$(realpath "$wrapper_path" 2>/dev/null || printf '%s' "$wrapper_path")
    export KUBECONFIG="${(j/:/)kubeconfig_files}"

    command_path=$(_kubeconfig_wrapper_resolve_binary "$command_name" "$wrapper_path")
    if [[ -z "$command_path" ]]; then
        echo "${command_name}: command not found" >&2
        return 127
    fi

    "$command_path" "$@"
}

_kubeconfigs_run() {
    local command_name="$1"
    local ret
    shift

    if ! _kubeconfigs_resolve_wrapper_helper; then
        echo "${command_name}: failed to load kubeconfig helper" >&2
        return 1
    fi

    _kubeconfigs_expire_session_if_idle

    if ! _kubeconfigs_ensure_session "$command_name"; then
        return 1
    fi

    if [[ -n "$KUBECONFIG_SESSION_READY" ]] && _kubeconfigs_session_has_files; then
        _kubeconfigs_run_from_session "$command_name" "$@"
        ret=$?
        if _kubeconfigs_session_has_files; then
            _kubeconfigs_touch_session
        fi
        return $ret
    fi

    _kubeconfig_wrapper_run "$command_name" "$DOTFILES/bin/${command_name}" "$@"
    ret=$?

    if _kubeconfigs_session_has_files; then
        export KUBECONFIG_SESSION_READY=1
        _kubeconfigs_touch_session
    fi

    return $ret
}

kubectl() {
    _kubeconfigs_run kubectl "$@"
}

k9s() {
    _kubeconfigs_run k9s "$@"
}

kubeconfig-clear() {
    _kubeconfigs_clear_session
}

if [[ -o interactive ]]; then
    if ! (( ${+_KUBECONFIG_SESSION_PRECMD_HOOK} )); then
        add-zsh-hook precmd _kubeconfigs_precmd
        typeset -g _KUBECONFIG_SESSION_PRECMD_HOOK=1
    fi

    if ! (( ${+_KUBECONFIG_SESSION_EXIT_HOOK} )); then
        add-zsh-hook zshexit _kubeconfigs_clear_session
        typeset -g _KUBECONFIG_SESSION_EXIT_HOOK=1
    fi
fi
