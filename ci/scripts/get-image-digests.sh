#!/usr/bin/env bash

set -euo pipefail

VERSIONS_FILE="${1:-ci/image-versions.env}"

if [[ ! -f "$VERSIONS_FILE" ]]; then
    echo "ERROR: $VERSIONS_FILE not found"
    exit 1
fi
# ============================================================
# Images
# ============================================================

JENKINS_BASE_IMAGE="${JENKINS_BASE_IMAGE:-jenkins/inbound-agent:latest-jdk21}"
FLUTTER_BASE_IMAGE="${FLUTTER_BASE_IMAGE:-ghcr.io/cirruslabs/flutter:stable}"

DIND_IMAGE="${DIND_IMAGE:-docker:28.5.2-dind}"
PLAYWRIGHT_IMAGE="${PLAYWRIGHT_IMAGE:-mcr.microsoft.com/playwright:v1.63.0-noble}"


# ============================================================
# Helper
# ============================================================

get_digest() {
    local image="$1"

    echo "Resolving: $image" >&2

    local digest

    digest="$(
        docker buildx imagetools inspect "$image" \
            | awk '/^Digest:/ {print $2; exit}'
    )"

    if [[ -z "$digest" ]]; then
        echo "ERROR: unable to resolve digest for $image" >&2
        exit 1
    fi

    echo "$digest"
}


show_image() {
    local name="$1"
    local image="$2"
    local digest="$3"

    printf '%-24s %s@%s\n' \
        "$name" \
        "$image" \
        "$digest"
}


# ============================================================
# Resolve
# ============================================================

JENKINS_DIGEST="$(get_digest "$JENKINS_BASE_IMAGE")"
FLUTTER_DIGEST="$(get_digest "$FLUTTER_BASE_IMAGE")"
DIND_DIGEST="$(get_digest "$DIND_IMAGE")"
PLAYWRIGHT_DIGEST="$(get_digest "$PLAYWRIGHT_IMAGE")"


# ============================================================
# Output
# ============================================================

echo
echo "============================================================"
echo "IMAGE DIGESTS"
echo "============================================================"

show_image \
    "Jenkins" \
    "$JENKINS_BASE_IMAGE" \
    "$JENKINS_DIGEST"

show_image \
    "Flutter" \
    "$FLUTTER_BASE_IMAGE" \
    "$FLUTTER_DIGEST"

show_image \
    "Docker DinD" \
    "$DIND_IMAGE" \
    "$DIND_DIGEST"

show_image \
    "Playwright" \
    "$PLAYWRIGHT_IMAGE" \
    "$PLAYWRIGHT_DIGEST"

echo
echo "============================================================"
echo "ENV VALUES"
echo "============================================================"

echo "JENKINS_BASE_DIGEST=$JENKINS_DIGEST"
echo "FLUTTER_BASE_DIGEST=$FLUTTER_DIGEST"
echo "DIND_DIGEST=$DIND_DIGEST"
echo "PLAYWRIGHT_DIGEST=$PLAYWRIGHT_DIGEST"

update_env() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" "$VERSIONS_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$VERSIONS_FILE"
    else
        echo "${key}=${value}" >> "$VERSIONS_FILE"
    fi
}

update_env JENKINS_BASE_DIGEST "$JENKINS_DIGEST"
update_env FLUTTER_BASE_DIGEST "$FLUTTER_DIGEST"
update_env DIND_DIGEST "$DIND_DIGEST"
update_env PLAYWRIGHT_DIGEST "$PLAYWRIGHT_DIGEST"