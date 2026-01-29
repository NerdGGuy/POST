#!/usr/bin/env bash
# Collect build status and update dashboard
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Collect build status from cache repository and update dashboard.

Options:
  --cache-owner OWNER   Cache repository owner
  --cache-repo REPO     Cache repository name
  --output DIR          Output directory (default: current directory)
  --dry-run             Show what would be generated without writing
  -h, --help            Show this help

Environment:
  GITHUB_TOKEN          Token for API access

This script:
  1. Fetches manifests from cache repository
  2. Updates data/current.json with latest status
  3. Appends to data/history.json (maintains last 100 entries)
  4. Generates badges/*.svg for each variant
EOF
}

# Try to read config from PULL if available
PULL_CONFIG="${SCRIPT_DIR}/../PULL/cache/config.json"
CACHE_OWNER=""
CACHE_REPO=""
if [[ -f "$PULL_CONFIG" ]]; then
    CACHE_OWNER=$(jq -r '.cache_repo.owner' "$PULL_CONFIG")
    CACHE_REPO=$(jq -r '.cache_repo.repo' "$PULL_CONFIG")
fi

OUTPUT_DIR="${SCRIPT_DIR}"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --cache-owner)
            CACHE_OWNER="$2"
            shift 2
            ;;
        --cache-repo)
            CACHE_REPO="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$CACHE_OWNER" ]] || [[ -z "$CACHE_REPO" ]]; then
    echo "Error: Cache repository owner and name required" >&2
    exit 1
fi

CACHE_BASE="https://raw.githubusercontent.com/${CACHE_OWNER}/${CACHE_REPO}/main"
VARIANTS=(release debug asan ubsan tsan msan coverage fuzz test-build test-run)

echo "Fetching status from: ${CACHE_OWNER}/${CACHE_REPO}"
echo "Output: ${OUTPUT_DIR}"
echo ""

# Create output directories
mkdir -p "${OUTPUT_DIR}/data/variants" "${OUTPUT_DIR}/badges"

# Fetch variant status from manifests
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
VARIANTS_JSON="{}"

for variant in "${VARIANTS[@]}"; do
    echo -n "  ${variant}: "

    manifest_url="${CACHE_BASE}/manifests/${variant}.json"
    manifest=$(curl -sf "$manifest_url" 2>/dev/null || echo "")

    if [[ -n "$manifest" ]] && echo "$manifest" | jq -e '.path_hash' > /dev/null 2>&1; then
        status="pass"
        version=$(echo "$manifest" | jq -r '.version // "unknown"')
        store_path=$(echo "$manifest" | jq -r '.store_path // ""')
        path_hash=$(echo "$manifest" | jq -r '.path_hash // ""')
        rev=$(echo "$manifest" | jq -r '.rev // ""')
        build_timestamp=$(echo "$manifest" | jq -r '.timestamp // ""')

        echo "${status} (${version})"

        variant_entry=$(jq -n \
            --arg status "$status" \
            --arg version "$version" \
            --arg store_path "$store_path" \
            --arg log_hash "$path_hash" \
            --arg timestamp "$build_timestamp" \
            --arg rev "$rev" \
            '{
                status: $status,
                version: $version,
                store_path: $store_path,
                log_hash: $log_hash,
                timestamp: $timestamp,
                rev: $rev
            }'
        )
    else
        status="unknown"
        echo "${status}"

        variant_entry=$(jq -n \
            --arg status "$status" \
            --arg timestamp "$TIMESTAMP" \
            '{status: $status, timestamp: $timestamp}'
        )
    fi

    VARIANTS_JSON=$(echo "$VARIANTS_JSON" | jq --arg k "$variant" --argjson v "$variant_entry" '. + {($k): $v}')

    # Write per-variant file
    if ! $DRY_RUN; then
        echo "$variant_entry" > "${OUTPUT_DIR}/data/variants/${variant}.json"
    fi
done

# Generate current.json
CURRENT_JSON=$(jq -n \
    --arg updated "$TIMESTAMP" \
    --argjson variants "$VARIANTS_JSON" \
    '{updated: $updated, variants: $variants}'
)

if $DRY_RUN; then
    echo ""
    echo "Would write data/current.json:"
    echo "$CURRENT_JSON" | jq .
else
    echo "$CURRENT_JSON" > "${OUTPUT_DIR}/data/current.json"
fi

# Update history.json
HISTORY_FILE="${OUTPUT_DIR}/data/history.json"
if [[ -f "$HISTORY_FILE" ]]; then
    HISTORY=$(cat "$HISTORY_FILE")
else
    HISTORY='{"builds": []}'
fi

# Create history entry with just status and log_hash per variant
HISTORY_VARIANTS="{}"
for variant in "${VARIANTS[@]}"; do
    status=$(echo "$VARIANTS_JSON" | jq -r ".${variant}.status // \"unknown\"")
    log_hash=$(echo "$VARIANTS_JSON" | jq -r ".${variant}.log_hash // \"\"")
    HISTORY_VARIANTS=$(echo "$HISTORY_VARIANTS" | jq \
        --arg k "$variant" \
        --arg status "$status" \
        --arg log_hash "$log_hash" \
        '. + {($k): {status: $status, log_hash: $log_hash}}'
    )
done

HISTORY_ENTRY=$(jq -n \
    --arg timestamp "$TIMESTAMP" \
    --argjson variants "$HISTORY_VARIANTS" \
    '{timestamp: $timestamp, variants: $variants}'
)

# Append to history and keep last 100
NEW_HISTORY=$(echo "$HISTORY" | jq \
    --argjson entry "$HISTORY_ENTRY" \
    '.builds = (.builds + [$entry])[-100:]'
)

if ! $DRY_RUN; then
    echo "$NEW_HISTORY" > "$HISTORY_FILE"
fi

# Generate badges
echo ""
echo "Generating badges..."

generate_badge() {
    local variant="$1"
    local status="$2"

    local color
    case "$status" in
        pass) color="#4c1" ;;
        fail) color="#e05d44" ;;
        *) color="#9f9f9f" ;;
    esac

    local label_width=$((${#variant} * 6 + 10))
    local status_width=$((${#status} * 6 + 10))
    local width=$((label_width + status_width))

    cat <<EOF
<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="20">
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <mask id="a">
    <rect width="${width}" height="20" rx="3" fill="#fff"/>
  </mask>
  <g mask="url(#a)">
    <rect width="${label_width}" height="20" fill="#555"/>
    <rect x="${label_width}" width="${status_width}" height="20" fill="${color}"/>
    <rect width="${width}" height="20" fill="url(#b)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="$((label_width / 2))" y="15" fill="#010101" fill-opacity=".3">${variant}</text>
    <text x="$((label_width / 2))" y="14">${variant}</text>
    <text x="$((label_width + status_width / 2))" y="15" fill="#010101" fill-opacity=".3">${status}</text>
    <text x="$((label_width + status_width / 2))" y="14">${status}</text>
  </g>
</svg>
EOF
}

for variant in "${VARIANTS[@]}"; do
    status=$(echo "$VARIANTS_JSON" | jq -r ".${variant}.status // \"unknown\"")
    badge_file="${OUTPUT_DIR}/badges/${variant}.svg"

    if $DRY_RUN; then
        echo "  Would generate: badges/${variant}.svg (${status})"
    else
        generate_badge "$variant" "$status" > "$badge_file"
        echo "  Generated: badges/${variant}.svg"
    fi
done

echo ""
echo "=== Update Complete ==="
if $DRY_RUN; then
    echo "(dry run - no files were written)"
fi
