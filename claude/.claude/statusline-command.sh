#!/usr/bin/env bash
# Claude Code detailed statusline
#
# Line 1: Model (context size)
# Line 2: progress bar pct% | dir (branch)
# Line 3: 5 hours x% (HHh MMm) | weekly x% (DDd HHh MMm)

COLOR="blue"

C_RESET='\033[0m'
C_GRAY='\033[38;5;245m'
case "$COLOR" in
    orange)   C_ACCENT='\033[38;5;173m' ;;
    blue)     C_ACCENT='\033[38;5;74m' ;;
    teal)     C_ACCENT='\033[38;5;66m' ;;
    green)    C_ACCENT='\033[38;5;71m' ;;
    lavender) C_ACCENT='\033[38;5;139m' ;;
    rose)     C_ACCENT='\033[38;5;132m' ;;
    gold)     C_ACCENT='\033[38;5;136m' ;;
    slate)    C_ACCENT='\033[38;5;60m' ;;
    cyan)     C_ACCENT='\033[38;5;37m' ;;
    *)        C_ACCENT="$C_GRAY" ;;
esac

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"' | sed 's/ ([0-9]*[KMkm] context)$//')
MODEL_ID=$(echo "$input" | jq -r '.model.id')
cwd=$(echo "$input" | jq -r '.cwd // empty')
dir=$(basename "$cwd" 2>/dev/null || echo "?")
session=$(echo "$input" | jq -r '.session_id // empty')

branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

# -- Context window -----------------------------------------------------------

CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage')
REMAINING_PCT=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
max_k=$((CONTEXT_SIZE / 1000))

# Human-readable context size (e.g. "200K", "1M")
if [ "$max_k" -ge 1000 ]; then
    ctx_label="$((max_k / 1000))M context"
else
    ctx_label="${max_k}K context"
fi

MAX_OUTPUT_CAP=20000
case "$MODEL_ID" in
    *opus-4-6*)                          MODEL_MAX=128000 ;;
    *opus-4-5*|*sonnet-4*|*haiku-4*)     MODEL_MAX=64000 ;;
    *opus-4*)                            MODEL_MAX=32000 ;;
    *3-5*)                               MODEL_MAX=8192 ;;
    *claude-3-opus*)                     MODEL_MAX=4096 ;;
    *claude-3-sonnet*)                   MODEL_MAX=8192 ;;
    *claude-3-haiku*)                    MODEL_MAX=4096 ;;
    *)                                   MODEL_MAX=32000 ;;
esac
[ "$MODEL_MAX" -lt "$MAX_OUTPUT_CAP" ] && MAX_OUTPUT=$MODEL_MAX || MAX_OUTPUT=$MAX_OUTPUT_CAP

EHA=$((CONTEXT_SIZE - MAX_OUTPUT))
THRESHOLD=$((EHA - 13000))

AUTOCOMPACT_ENABLED=1
if [ -f "$HOME/.claude.json" ]; then
    cfg_val=$(jq -r 'if has("autoCompactEnabled") then .autoCompactEnabled else true end' "$HOME/.claude.json" 2>/dev/null)
    [ "$cfg_val" = "false" ] && AUTOCOMPACT_ENABLED=0
fi
[ "$AUTOCOMPACT_ENABLED" = "1" ] && EFFECTIVE=$THRESHOLD || EFFECTIVE=$EHA

pct_prefix=""
if [ "$USAGE" != "null" ] && [ -n "$USAGE" ]; then
    CURRENT_TOKENS=$(echo "$USAGE" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    pct=$((CURRENT_TOKENS * 100 / EFFECTIVE))
    [ "$pct" -gt 100 ] && pct=100
else
    pct=$((20000 * 100 / EFFECTIVE))
    pct_prefix="~"
fi

# Progress bar (10 segments)
bar=""
filled=$((pct / 10))
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = filled; i < 10; i++)); do bar+="░"; done

if [ "$pct" -lt 50 ]; then
    C_CTX='\033[32m'
elif [ "$pct" -lt 65 ]; then
    C_CTX='\033[33m'
elif [ "$pct" -lt 80 ]; then
    C_CTX='\033[38;5;208m'
else
    C_CTX='\033[31m'
fi

# -- GSD context bridge (for context-monitor hook) ----------------------------

if [ -n "$session" ]; then
    printf '{"session_id":"%s","remaining_percentage":%s,"used_pct":%d,"timestamp":%d}' \
        "$session" "${REMAINING_PCT:-0}" "$pct" "$(date +%s)" \
        > "/tmp/claude-ctx-${session}.json" 2>/dev/null
fi

# -- API usage ----------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./fetch-usage.sh
source "${SCRIPT_DIR}/fetch-usage.sh"

usage_5hr=""
usage_weekly=""
usage_data=$(fetch_usage_data)

# Helper: format seconds as zero-padded HHh MMm
fmt_hms() {
    local s=$1
    printf "%02dh %02dm" $((s / 3600)) $(((s % 3600) / 60))
}

# Helper: format seconds as zero-padded DDd HHh MMm
fmt_dhm() {
    local s=$1
    local d=$((s / 86400))
    local rem=$((s % 86400))
    printf "%02dd %02dh %02dm" "$d" $((rem / 3600)) $(((rem % 3600) / 60))
}

if [ -n "$usage_data" ]; then
    error=$(echo "$usage_data" | jq -r '.error // empty' 2>/dev/null)

    if [ -z "$error" ]; then
        utilization=$(echo "$usage_data" | jq -r '.sessionUsage // empty' 2>/dev/null)
        weekly_usage=$(echo "$usage_data" | jq -r '.weeklyUsage // empty' 2>/dev/null)
        resets_at=$(echo "$usage_data" | jq -r '.sessionResetAt // empty' 2>/dev/null)
        weekly_resets_at=$(echo "$usage_data" | jq -r '.weeklyResetAt // empty' 2>/dev/null)

        now_ts=$(date +%s)

        # 5-hour session usage
        if [ -n "$utilization" ] && [ -n "$resets_at" ]; then
            utilization_pct=$(printf "%.0f" "$utilization")
            reset_epoch=$(date -d "$resets_at" +%s 2>/dev/null)
            if [ -n "$reset_epoch" ]; then
                diff=$((reset_epoch - now_ts))
                [ "$diff" -lt 0 ] && diff=0
                usage_5hr="${C_GRAY}5 hours ${C_ACCENT}${utilization_pct}%${C_GRAY} ($(fmt_hms "$diff"))"
            fi
        fi

        # Weekly usage
        if [ -n "$weekly_usage" ] && [ -n "$weekly_resets_at" ]; then
            weekly_pct=$(printf "%.0f" "$weekly_usage")
            weekly_reset_epoch=$(date -d "$weekly_resets_at" +%s 2>/dev/null)
            if [ -n "$weekly_reset_epoch" ]; then
                diff=$((weekly_reset_epoch - now_ts))
                [ "$diff" -lt 0 ] && diff=0
                usage_weekly="${C_GRAY}weekly ${C_ACCENT}${weekly_pct}%${C_GRAY} ($(fmt_dhm "$diff"))"
            fi
        fi
    fi
fi

# -- Output -------------------------------------------------------------------

# Line 1: Model (context size)
line1="${C_ACCENT}${model}${C_GRAY} (${ctx_label})${C_RESET}"

# Line 2: progress bar pct% | dir (branch)
dir_part="${C_GRAY}${dir}"
[ -n "$branch" ] && dir_part="${dir_part} (${branch})"
line2="${C_CTX}${bar} ${pct_prefix}${pct}%${C_RESET} ${C_GRAY}|${C_RESET} ${dir_part}${C_RESET}"

# Line 3: 5 hours x% (HHh MMm) | weekly x% (DDd HHh MMm)
line3=""
if [ -n "$usage_5hr" ] && [ -n "$usage_weekly" ]; then
    line3="${usage_5hr} ${C_GRAY}|${C_RESET} ${usage_weekly}${C_RESET}"
elif [ -n "$usage_5hr" ]; then
    line3="${usage_5hr}${C_RESET}"
elif [ -n "$usage_weekly" ]; then
    line3="${usage_weekly}${C_RESET}"
fi

output="${line1}\n${line2}"
[ -n "$line3" ] && output="${output}\n${line3}"

printf '%b\n' "$output"
