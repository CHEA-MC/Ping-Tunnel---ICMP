#!/bin/bash

set -e

# Fallback tag (used only if the latest release can't be downloaded)
FALLBACK_TAG="2.8"
BASE_URL="https://github.com/esrrhs/pingtunnel/releases"

# Detect OS
get_os() {
    os=$(uname | tr '[:upper:]' '[:lower:]')
    case "$os" in
        linux|darwin|freebsd|dragonfly|illumos|aix) echo "$os" ;;
        *) echo "Unsupported OS: $os" >&2; exit 1 ;;
    esac
}

# Detect architecture
get_arch() {
    arch=$(uname -m)
    case "$arch" in
        x86_64) echo "amd64" ;;
        i386|i686) echo "386" ;;
        armv7l|armv6l) echo "arm" ;;
        aarch64|arm64) echo "arm64" ;;
        riscv64) echo "riscv64" ;;
        ppc64) echo "ppc64" ;;
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
    esac
}

# Ensure unzip is available
ensure_unzip() {
    if ! command -v unzip >/dev/null 2>&1; then
        echo "Installing unzip..."

        if command -v apt-get >/dev/null 2>&1; then
            # Wait up to 5 minutes if another apt/dpkg process (e.g. unattended-upgrades) holds the lock
            apt-get -o DPkg::Lock::Timeout=300 update
            apt-get -o DPkg::Lock::Timeout=300 install -y unzip
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y unzip
        elif command -v yum >/dev/null 2>&1; then
            yum install -y unzip
        else
            echo "❌ Please install unzip manually."
            exit 1
        fi
    fi
}

# Download PingTunnel, trying several known URL patterns
download_pingtunnel() {
    local out="$1"
    local urls=(
        "${BASE_URL}/latest/download/pingtunnel_${OS}_${ARCH}.zip"
        "${BASE_URL}/download/${FALLBACK_TAG}/pingtunnel_${OS}_${ARCH}.zip"
    )

    # Older releases used names like pingtunnel_linux64.zip
    if [ "$ARCH" = "amd64" ]; then
        urls+=("${BASE_URL}/download/${FALLBACK_TAG}/pingtunnel_${OS}64.zip")
        urls+=("${BASE_URL}/latest/download/pingtunnel_${OS}64.zip")
    fi

    for url in "${urls[@]}"; do
        echo "Trying: $url"
        if curl -fL --retry 3 -o "$out" "$url"; then
            echo "Downloaded from: $url"
            return 0
        fi
        rm -f "$out"
    done

    return 1
}

# Install PingTunnel
install_pingtunnel() {
    OS=$(get_os)
    ARCH=$(get_arch)

    echo "--------------------------------"
    echo "Installing PingTunnel"
    echo "Detected OS: $OS"
    echo "Detected Architecture: $ARCH"
    echo "--------------------------------"

    ensure_unzip

    mkdir -p /opt/pingtunnel
    cd /opt/pingtunnel

    FILE="pingtunnel.zip"

    if ! download_pingtunnel "$FILE"; then
        echo "❌ Failed to download PingTunnel (all URLs returned an error)."
        echo "   Check https://github.com/esrrhs/pingtunnel/releases for the file name."
        exit 1
    fi

    echo "Extracting PingTunnel..."

    if ! unzip -o "$FILE"; then
        echo "❌ Failed to extract $FILE"
        exit 1
    fi

    if [ ! -f pingtunnel ]; then
        echo "❌ PingTunnel binary not found after extraction."
        exit 1
    fi

    chmod +x pingtunnel
    rm -f "$FILE"

    echo "✅ PingTunnel installed successfully."
}

# Create systemd service
create_service() {
    echo "Creating systemd service..."

    cat <<EOF > /etc/systemd/system/pingtunnel.service
[Unit]
Description=PingTunnel Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/opt/pingtunnel
ExecStart=/opt/pingtunnel/pingtunnel -type server -password ${PINGTUNNEL_KEY}
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable pingtunnel
    systemctl restart pingtunnel

    if systemctl is-active --quiet pingtunnel; then
        echo "✅ PingTunnel service is running."
    else
        echo "❌ PingTunnel service failed to start."
        systemctl status pingtunnel --no-pager || true
        exit 1
    fi
}

# Show installation information
show_final_info() {
    SERVER_IP=$(curl -fsS --max-time 10 https://api.ipify.org || echo "Unknown")

    echo ""
    echo "================================"
    echo "✅ PingTunnel Installation Complete"
    echo "================================"
    echo "Server IP : ${SERVER_IP}"
    echo "Password  : ${PINGTUNNEL_KEY}"
    echo "Service   : pingtunnel"
    echo "Status    : $(systemctl is-active pingtunnel)"
    echo "================================"
    echo ""
    echo "Useful commands:"
    echo "  systemctl status pingtunnel"
    echo "  systemctl restart pingtunnel"
    echo "  systemctl stop pingtunnel"
    echo "  journalctl -u pingtunnel -f"
    echo ""
}

# Main function
main() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "❌ Please run this script as root (use sudo)."
        exit 1
    fi

    # systemd is required
    if ! command -v systemctl >/dev/null 2>&1; then
        echo "❌ This installer requires systemd."
        exit 1
    fi

    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        echo "❌ curl is required. Please install curl first."
        exit 1
    fi

    # Prompt user for PingTunnel password (v3+: -password, min 8 chars)
    # Only safe characters are allowed because the value goes into a systemd unit file.
    while true; do
        read -r -p "Enter a Password for PingTunnel (-password, min 8 chars, allowed: a-z A-Z 0-9 . _ -): " PINGTUNNEL_KEY

        if [[ "$PINGTUNNEL_KEY" =~ ^[A-Za-z0-9._-]{8,}$ ]]; then
            break
        else
            echo "❌ Password must be at least 8 characters and use only a-z A-Z 0-9 . _ -"
        fi
    done

    install_pingtunnel
    create_service
    show_final_info
}

main
