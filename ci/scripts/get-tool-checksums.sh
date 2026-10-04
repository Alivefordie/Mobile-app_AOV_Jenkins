#!/usr/bin/env bash

set -euo pipefail

VERSIONS_FILE="${1:-ci/tool-versions.env}"

if [[ ! -f "$VERSIONS_FILE" ]]; then
    echo "ERROR: $VERSIONS_FILE not found"
    exit 1
fi

# shellcheck disable=SC1090
source "$VERSIONS_FILE"

TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT


# ============================================================
# Helpers
# ============================================================

download_checksum() {
    local name="$1"
    local url="$2"
    local output="$TMP_DIR/$name"

    echo "------------------------------------------------------------" >&2
    echo "Downloading: $name" >&2
    echo "URL        : $url" >&2

    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --retry 3 \
        --retry-delay 2 \
        "$url" \
        -o "$output"

    sha256sum "$output" | awk '{print $1}'
}


show_result() {
    local variable="$1"
    local checksum="$2"

    printf '%-32s=%s\n' "$variable" "$checksum"
}


# ============================================================
# yq
# ============================================================

YQ_HASH="$(
    download_checksum \
        "yq_linux_amd64" \
        "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
)"


# ============================================================
# Docker Compose
# ============================================================

COMPOSE_HASH="$(
    download_checksum \
        "docker-compose-linux-x86_64" \
        "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64"
)"


# ============================================================
# Docker Buildx
# ============================================================

BUILDX_HASH="$(
    download_checksum \
        "buildx-linux-amd64" \
        "https://github.com/docker/buildx/releases/download/${BUILDX_VERSION}/buildx-${BUILDX_VERSION}.linux-amd64"
)"


# ============================================================
# Helm
# ============================================================

HELM_HASH="$(
    download_checksum \
        "helm-linux-amd64.tar.gz" \
        "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
)"


# ============================================================
# Cosign
# ============================================================

COSIGN_HASH="$(
    download_checksum \
        "cosign-linux-amd64" \
        "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
)"


# ============================================================
# Trivy
# ============================================================

TRIVY_HASH="$(
    download_checksum \
        "trivy-linux-amd64.tar.gz" \
        "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
)"


# ============================================================
# Syft
# ============================================================

SYFT_HASH="$(
    download_checksum \
        "syft-linux-amd64.tar.gz" \
        "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz"
)"


# ============================================================
# OPA
# ============================================================

OPA_HASH="$(
    download_checksum \
        "opa_linux_amd64_static" \
        "https://github.com/open-policy-agent/opa/releases/download/v${OPA_VERSION}/opa_linux_amd64_static"
)"


# ============================================================
# Gitleaks
# ============================================================

GITLEAKS_HASH="$(
    download_checksum \
        "gitleaks-linux-x64.tar.gz" \
        "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
)"


# ============================================================
# OSV Scanner
# ============================================================

OSV_HASH="$(
    download_checksum \
        "osv-scanner_linux_amd64" \
        "https://github.com/google/osv-scanner/releases/download/v${OSV_SCANNER_VERSION}/osv-scanner_linux_amd64"
)"


# ============================================================
# SonarScanner CLI
# ============================================================

SONAR_HASH="$(
    download_checksum \
        "sonar-scanner.zip" \
        "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux-x64.zip"
)"


# ============================================================
# Node.js
#
# Optional:
# ถ้าจะ verify Node ด้วย ให้เพิ่ม NODE_SHA256 ใน versions file
# ============================================================

NODE_HASH="$(
    download_checksum \
        "node-linux-x64.tar.xz" \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"
)"


# ============================================================
# Result
# ============================================================

echo
echo "============================================================"
echo "SHA256 RESULTS"
echo "============================================================"

show_result "NODE_SHA256" "$NODE_HASH"
show_result "YQ_SHA256" "$YQ_HASH"
show_result "DOCKER_COMPOSE_SHA256" "$COMPOSE_HASH"
show_result "BUILDX_SHA256" "$BUILDX_HASH"
show_result "HELM_SHA256" "$HELM_HASH"
show_result "COSIGN_SHA256" "$COSIGN_HASH"
show_result "TRIVY_SHA256" "$TRIVY_HASH"
show_result "SYFT_SHA256" "$SYFT_HASH"
show_result "OPA_SHA256" "$OPA_HASH"
show_result "GITLEAKS_SHA256" "$GITLEAKS_HASH"
show_result "OSV_SCANNER_SHA256" "$OSV_HASH"
show_result "SONAR_SCANNER_SHA256" "$SONAR_HASH"

update_env() {
    local key="$1"
    local value="$2"

    if grep -q "^${key}=" "$VERSIONS_FILE"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$VERSIONS_FILE"
    else
        echo "${key}=${value}" >> "$VERSIONS_FILE"
    fi
}

update_env NODE_SHA256 "$NODE_HASH"
update_env YQ_SHA256 "$YQ_HASH"
update_env DOCKER_COMPOSE_SHA256 "$COMPOSE_HASH"
update_env BUILDX_SHA256 "$BUILDX_HASH"
update_env HELM_SHA256 "$HELM_HASH"
update_env COSIGN_SHA256 "$COSIGN_HASH"
update_env TRIVY_SHA256 "$TRIVY_HASH"
update_env SYFT_SHA256 "$SYFT_HASH"
update_env OPA_SHA256 "$OPA_HASH"
update_env GITLEAKS_SHA256 "$GITLEAKS_HASH"
update_env OSV_SCANNER_SHA256 "$OSV_HASH"
update_env SONAR_SCANNER_SHA256 "$SONAR_HASH"

echo
echo "Updated: $VERSIONS_FILE"

echo
echo "Done."