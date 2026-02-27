#!/usr/bin/env bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.cwd')

folder=$(basename "$cwd")
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -z "$branch" ] && branch="-"

if [ -n "$used" ]; then
    context="${used}%"
else
    context="-"
fi

echo "${folder} | ${branch} | ${model} | ${context}"
