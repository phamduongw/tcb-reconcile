#!/usr/bin/env bash
set -euo pipefail

readonly BOOTSTRAP='10.35.222.247:9092'
readonly RETENTION_MS=86400000

if command -v kafka-topics >/dev/null 2>&1; then
    topics_cli=kafka-topics
elif command -v kafka-topics.sh >/dev/null 2>&1; then
    topics_cli=kafka-topics.sh
else
    printf 'ERROR: kafka-topics or kafka-topics.sh must be on PATH.\n' >&2
    exit 1
fi

if command -v kafka-configs >/dev/null 2>&1; then
    configs_cli=kafka-configs
elif command -v kafka-configs.sh >/dev/null 2>&1; then
    configs_cli=kafka-configs.sh
else
    printf 'ERROR: kafka-configs or kafka-configs.sh must be on PATH.\n' >&2
    exit 1
fi

# Match RHS1-RHS4 prefixes, but not RHS10, RHS20, or other numbered groups.
listing=$("$topics_cli" --bootstrap-server "$BOOTSTRAP" --list)
topics=()
while IFS= read -r topic; do
    if [[ "$topic" =~ ^RHS[1-4]([^0-9]|$) ]]; then
        topics+=("$topic")
    fi
done <<< "$listing"

if (( ${#topics[@]} == 0 )); then
    printf 'ERROR: no RHS1-RHS4 topics found; nothing changed.\n' >&2
    exit 1
fi

printf 'Broker: %s\nRetention: %s ms (1 day)\nTopics: %s\n' \
    "$BOOTSTRAP" "$RETENTION_MS" "${#topics[@]}"
printf '  %s\n' "${topics[@]}"
printf 'WARNING: expired data may be deleted; increasing retention cannot restore it.\n' >&2

# Read every selected topic before making any changes. A failed read aborts.
printf '\nCurrent topic overrides:\n'
for topic in "${topics[@]}"; do
    "$configs_cli" --bootstrap-server "$BOOTSTRAP" \
        --entity-type topics --entity-name "$topic" --describe
done

# Only retention.ms changes. Do not change cleanup.policy or broker defaults.
# Updates are sequential, not atomic; an error can leave earlier topics updated.
retention_pattern="(^|[[:space:],])retention[.]ms=${RETENTION_MS}([[:space:],]|$)"
for topic in "${topics[@]}"; do
    printf '\nUpdating %s\n' "$topic"
    "$configs_cli" --bootstrap-server "$BOOTSTRAP" \
        --entity-type topics --entity-name "$topic" \
        --alter --add-config "retention.ms=$RETENTION_MS"

    description=$("$configs_cli" --bootstrap-server "$BOOTSTRAP" \
        --entity-type topics --entity-name "$topic" --describe)
    printf '%s\n' "$description"
    if [[ ! "$description" =~ $retention_pattern ]]; then
        printf 'ERROR: retention.ms verification failed for %s; stopping.\n' "$topic" >&2
        exit 1
    fi
done

printf '\nVerified retention.ms=%s on all %s selected topics.\n' \
    "$RETENTION_MS" "${#topics[@]}"
