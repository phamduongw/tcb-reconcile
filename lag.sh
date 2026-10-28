#!/usr/bin/env bash

readonly BOOTSTRAP='10.35.222.247:9092'
readonly INTERVAL_SECONDS=2

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 CONSUMER_GROUP [CONSUMER_GROUP ...]" >&2
    exit 1
fi

group_args=()
for group in "$@"; do
    group_args+=(--group "$group")
done

while true; do
    # Describe all groups in one call: each call starts a JVM, so this keeps every refresh to a single startup.
    if output=$(kafka-consumer-groups --bootstrap-server "$BOOTSTRAP" --describe "${group_args[@]}" 2>&1); then
        # A partition without a committed offset counts its full LOG-END-OFFSET.
        screen=$(awk -v groups="$*" '
            $5 ~ /^[0-9]+$/ { seen[$1] = 1; lag[$1] += ($4 ~ /^[0-9]+$/ ? $6 : $5) }
            END {
                n = split(groups, g, " ")
                for (i = 1; i <= n; i++) {
                    if (g[i] in seen) printf "%s lag: %.0f\n", g[i], lag[g[i]]
                    else printf "%s: no offsets reported\n", g[i]
                }
            }' <<<"$output")
    else
        screen=$output
    fi
    clear
    date
    echo "$screen"
    sleep "$INTERVAL_SECONDS"
done
