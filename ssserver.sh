#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script requires root privileges. Please run as root or use sudo."
  exit 1
fi

# Function to get the latest release version from GitHub API
get_latest_version() {
  latest_version=$(curl -s "https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest" | jq -r .tag_name)
  if [[ "$latest_version" == "null" ]]; then
    echo "Unable to fetch latest version from GitHub. Using default v1.22.0."
    echo "v1.22.0"
  else
    echo "$latest_version"
  fi
}

# Function to detect the package manager and install missing packages
install_packages() {
  if command -v apt-get &> /dev/null; then
    apt-get update && apt-get install -y curl jq tar openssl xz-utils ntp
  elif command -v pacman &> /dev/null; then
    pacman -Syu --noconfirm curl jq tar openssl xz ntp
  elif command -v dnf &> /dev/null; then
    dnf install -y curl jq tar openssl xz ntp
  elif command -v zypper &> /dev/null; then
    zypper install -y curl jq tar openssl xz ntp
  elif command -v yum &> /dev/null; then
    yum install -y curl jq tar openssl xz ntp
  else
    echo "Unsupported package manager. Please install curl, jq, tar, and openssl manually."
    exit 1
  fi
}

# Check if required tools are installed, if not install them
for tool in curl jq tar openssl xz ntpd; do
  if ! command -v "$tool" &> /dev/null; then
    echo "$tool not found. Installing..."
    install_packages
    break
  fi
done

# Set version argument or fallback to latest or default version
if [ -z "$1" ]; then
  version=$(get_latest_version)
else
  version="$1"
fi

# Sync system time
ntpd -gd > /dev/null 2>&1

# Detect CPU architecture
cpu_arch=$(uname -m)

case "$cpu_arch" in
  x86_64) arch="x86_64" ;;
  aarch64) arch="aarch64" ;;
  *) echo "Unsupported architecture: $cpu_arch"; exit 1 ;;
esac

# Construct the download URL
url="https://github.com/shadowsocks/shadowsocks-rust/releases/download/${version}/shadowsocks-${version}.${arch}-unknown-linux-musl.tar.xz"

# Accept port argument or generate a random port
if [ -z "$2" ]; then
  port=$((RANDOM % 50000 + 10000))
else
  port=$2
fi

# Accept IP argument or fetch the IP from Cloudflare CDN trace
if [ -z "$3" ]; then
  ip=$(curl -s https://cloudflare.com/cdn-cgi/trace -4 | grep -oP '(?<=ip=)[0-9.]+')
  if [ -z "$ip" ]; then
    ip=$(curl -s https://cloudflare.com/cdn-cgi/trace -6 | grep -oP '(?<=ip=)[0-9a-f:]+')
  fi
fi

# Create target directory
mkdir -p /opt/ss-rust

# Download and extract
echo "Downloading ${url}..."
curl -s -L -o shadowsocks.tar.xz "$url"
tar -xvf shadowsocks.tar.xz -C /opt/ss-rust/ > /dev/null
rm -rf shadowsocks.tar.xz
echo "Shadowsocks downloaded and extracted to /opt/ss-rust/."

# Keep only the ssserver binary and remove other files
find /opt/ss-rust/ -type f ! -name "ssserver" -exec rm -f {} \;

# Generate password using openssl
password=$(openssl rand -base64 16)

# Print the chosen port, IP, and password
echo "Using port: $port"
echo "Using IP: $ip"
echo "Generated password: $password"

# Generate ss:// URL
encryption_method="2022-blake3-aes-128-gcm"
ss_url="ss://$(echo -n "${encryption_method}:${password}" | base64)"
echo "Shadowsocks URL: $ss_url@$ip:$port#ssquick-ss2022aes128gcm-$ip-$port"

# Generate JSON configuration
json_config=$(cat <<EOF
{
  "type": "shadowsocks",
  "tag": "shadowsocks-server",
  "server": "$ip",
  "server_port": $port,
  "method": "$encryption_method",
  "password": "$password"
}
EOF
)
echo "JSON configuration: $json_config"

# Generate a random systemd service name
random_service_name=$(openssl rand -hex 6)

# Create a systemd service for ssserver
service_file="/etc/systemd/system/ssserver-${random_service_name}.service"

cat > "$service_file" <<EOF
[Unit]
Description=Shadowsocks Server
After=network.target

[Service]
ExecStart=/opt/ss-rust/ssserver -U --server-addr 0.0.0.0:$port --encrypt-method $encryption_method --password $password
WorkingDirectory=/opt/ss-rust
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
echo "Creating systemd service at $service_file..."
systemctl daemon-reload
systemctl enable "ssserver-${random_service_name}"
systemctl start "ssserver-${random_service_name}"

echo "Shadowsocks server started with systemd service ssserver-${random_service_name}."
