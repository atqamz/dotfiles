#!/usr/bin/env bash
# Fetch Claude API usage data with caching and rate-limit handling.
# Sourced by statusline-command.sh.

CACHE_DIR="${HOME}/.cache/claude/statusline"
CACHE_FILE="${CACHE_DIR}/usage.json"
LOCK_FILE="${CACHE_DIR}/usage.lock"
CACHE_MAX_AGE=180
LOCK_MAX_AGE=30
DEFAULT_RATE_LIMIT_BACKOFF=300
TOKEN_CACHE_FILE="${CACHE_DIR}/token.cache"
TOKEN_CACHE_MAX_AGE=3600

USAGE_API_HOST="api.anthropic.com"
USAGE_API_PATH="/api/oauth/usage"
USAGE_API_TIMEOUT=5

ensure_cache_dir() {
    mkdir -p "$CACHE_DIR" 2>/dev/null || true
}

now() { date +%s; }

file_mtime() {
    stat -c %Y "$1" 2>/dev/null || echo 0
}

get_usage_token() {
    local now_ts
    now_ts=$(now)

    if [[ -f "$TOKEN_CACHE_FILE" ]]; then
        local cache_age=$(( now_ts - $(file_mtime "$TOKEN_CACHE_FILE") ))
        if [[ $cache_age -lt $TOKEN_CACHE_MAX_AGE ]]; then
            cat "$TOKEN_CACHE_FILE" 2>/dev/null && return 0
        fi
    fi

    local token=""
    local cred_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.credentials.json"
    [[ -f "$cred_file" ]] || return 1
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$cred_file" 2>/dev/null)

    [[ -n "$token" && "$token" != "null" ]] || return 1

    ensure_cache_dir
    echo "$token" > "$TOKEN_CACHE_FILE" 2>/dev/null
    echo "$token"
}

read_active_lock() {
    local now_ts
    now_ts=$(now)
    [[ -f "$LOCK_FILE" ]] || return 1

    local lock_data
    lock_data=$(cat "$LOCK_FILE" 2>/dev/null)
    if [[ -n "$lock_data" ]]; then
        local blocked_until error
        blocked_until=$(echo "$lock_data" | jq -r '.blockedUntil // empty' 2>/dev/null)
        error=$(echo "$lock_data" | jq -r '.error // "timeout"' 2>/dev/null)
        if [[ -n "$blocked_until" && "$blocked_until" =~ ^[0-9]+$ ]]; then
            if [[ $blocked_until -gt $now_ts ]]; then
                echo "$error:$blocked_until"
                return 0
            fi
            return 1
        fi
    fi

    local lock_mtime
    lock_mtime=$(file_mtime "$LOCK_FILE")
    local blocked_until=$(( lock_mtime + LOCK_MAX_AGE ))
    if [[ $blocked_until -gt $now_ts ]]; then
        echo "timeout:$blocked_until"
        return 0
    fi
    return 1
}

write_lock() {
    local blocked_until="$1"
    local error="${2:-timeout}"
    ensure_cache_dir
    echo "{\"blockedUntil\":$blocked_until,\"error\":\"$error\"}" > "$LOCK_FILE" 2>/dev/null
}

parse_retry_after() {
    local retry_after="$1"
    [[ -z "$retry_after" ]] && return 1
    if [[ "$retry_after" =~ ^[0-9]+$ ]]; then
        [[ $retry_after -gt 0 ]] && echo "$retry_after" && return 0
        return 1
    fi
    local retry_at_s
    retry_at_s=$(date -d "$retry_after" +%s 2>/dev/null)
    [[ -n "$retry_at_s" ]] || return 1
    local diff=$(( retry_at_s - $(date +%s) ))
    [[ $diff -gt 0 ]] && echo "$diff" && return 0
    return 1
}

fetch_from_api() {
    local token="$1"
    local response_file headers_file http_code
    response_file=$(mktemp)
    headers_file=$(mktemp)

    http_code=$(curl -s -m "$USAGE_API_TIMEOUT" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -w "%{http_code}" \
        -o "$response_file" \
        -D "$headers_file" \
        "https://${USAGE_API_HOST}${USAGE_API_PATH}" 2>/dev/null)

    local result=""
    if [[ "$http_code" == "200" ]]; then
        local body
        body=$(cat "$response_file" 2>/dev/null)
        [[ -n "$body" ]] && result="success:$body" || result="error"
    elif [[ "$http_code" == "429" ]]; then
        local retry_after retry_seconds
        retry_after=$(grep -i "^retry-after:" "$headers_file" | sed 's/^retry-after: *//i' | tr -d '\r\n' 2>/dev/null)
        retry_seconds=$(parse_retry_after "$retry_after")
        retry_seconds=${retry_seconds:-$DEFAULT_RATE_LIMIT_BACKOFF}
        result="rate-limited:$retry_seconds"
    else
        result="error"
    fi

    rm -f "$response_file" "$headers_file"
    echo "$result"
}

parse_api_response() {
    local body="$1"
    jq -n --argjson data "$body" '{
        sessionUsage: $data.five_hour.utilization,
        sessionResetAt: $data.five_hour.resets_at,
        weeklyUsage: $data.seven_day.utilization,
        weeklyResetAt: $data.seven_day.resets_at,
        extraUsageEnabled: $data.extra_usage.is_enabled,
        extraUsageLimit: $data.extra_usage.monthly_limit,
        extraUsageUsed: $data.extra_usage.used_credits,
        extraUsageUtilization: $data.extra_usage.utilization
    }' 2>/dev/null
}

read_stale_cache() {
    [[ -f "$CACHE_FILE" ]] || return 1
    cat "$CACHE_FILE" 2>/dev/null
}

create_error_response() {
    echo "{\"error\":\"$1\"}"
}

fetch_usage_data() {
    local now_ts
    now_ts=$(now)

    # Fresh cache?
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age=$(( now_ts - $(file_mtime "$CACHE_FILE") ))
        if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
            local cached_data
            cached_data=$(cat "$CACHE_FILE" 2>/dev/null)
            if [[ -n "$cached_data" ]]; then
                local has_error
                has_error=$(echo "$cached_data" | jq -r '.error // empty' 2>/dev/null)
                [[ -z "$has_error" ]] && { echo "$cached_data"; return 0; }
            fi
        fi
    fi

    # Token
    local token
    token=$(get_usage_token)
    if [[ -z "$token" ]]; then
        local stale
        stale=$(read_stale_cache)
        if [[ -n "$stale" ]]; then
            local has_error
            has_error=$(echo "$stale" | jq -r '.error // empty' 2>/dev/null)
            [[ -z "$has_error" ]] && { echo "$stale"; return 0; }
        fi
        create_error_response "no-credentials"
        return 1
    fi

    # Lock
    local lock_info
    if lock_info=$(read_active_lock); then
        local stale
        stale=$(read_stale_cache)
        if [[ -n "$stale" ]]; then
            local has_error
            has_error=$(echo "$stale" | jq -r '.error // empty' 2>/dev/null)
            [[ -z "$has_error" ]] && { echo "$stale"; return 0; }
        fi
        create_error_response "${lock_info%%:*}"
        return 1
    fi

    write_lock $(( now_ts + LOCK_MAX_AGE )) "timeout"

    local api_result
    api_result=$(fetch_from_api "$token")
    local result_type="${api_result%%:*}"
    local result_value="${api_result#*:}"

    case "$result_type" in
        success)
            local usage_data
            usage_data=$(parse_api_response "$result_value")
            if [[ -z "$usage_data" ]]; then
                local stale; stale=$(read_stale_cache)
                if [[ -n "$stale" ]]; then
                    local has_error; has_error=$(echo "$stale" | jq -r '.error // empty' 2>/dev/null)
                    [[ -z "$has_error" ]] && { echo "$stale"; return 0; }
                fi
                create_error_response "parse-error"; return 1
            fi
            local has_session has_weekly
            has_session=$(echo "$usage_data" | jq -r '.sessionUsage // empty' 2>/dev/null)
            has_weekly=$(echo "$usage_data" | jq -r '.weeklyUsage // empty' 2>/dev/null)
            if [[ -z "$has_session" && -z "$has_weekly" ]]; then
                local stale; stale=$(read_stale_cache)
                if [[ -n "$stale" ]]; then
                    local has_error; has_error=$(echo "$stale" | jq -r '.error // empty' 2>/dev/null)
                    [[ -z "$has_error" ]] && { echo "$stale"; return 0; }
                fi
                create_error_response "parse-error"; return 1
            fi
            ensure_cache_dir
            echo "$usage_data" > "$CACHE_FILE" 2>/dev/null
            echo "$usage_data"
            return 0
            ;;
        rate-limited)
            write_lock $(( now_ts + result_value )) "rate-limited"
            local stale; stale=$(read_stale_cache)
            if [[ -n "$stale" ]]; then
                local has_error; has_error=$(echo "$stale" | jq -r '.error // empty' 2>/dev/null)
                [[ -z "$has_error" ]] && { echo "$stale"; return 0; }
            fi
            create_error_response "rate-limited"; return 1
            ;;
        *)
            local stale; stale=$(read_stale_cache)
            if [[ -n "$stale" ]]; then
                local has_error; has_error=$(echo "$stale" | jq -r '.error // empty' 2>/dev/null)
                [[ -z "$has_error" ]] && { echo "$stale"; return 0; }
            fi
            create_error_response "api-error"; return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    fetch_usage_data
fi
