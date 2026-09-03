#!/usr/bin/env bash

# Copyright (c) 2024-2026 community-scripts ORG
# Author: Randy
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/Py-KMS-Organization/py-kms

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  python3 \
  python3-pip \
  python3-venv \
  python3-tk \
  sqlite3
msg_ok "Installed Dependencies"

msg_info "Installing py-kms"
PYKMS_DIR="/opt/py-kms"
$STD git clone https://github.com/Py-KMS-Organization/py-kms.git "$PYKMS_DIR"
cd "$PYKMS_DIR/py-kms" || exit
python3 -m venv /opt/py-kms-env
source /opt/py-kms-env/bin/activate
$STD pip install --upgrade pip
if [[ -f "$PYKMS_DIR/requirements.txt" ]]; then
  $STD pip install -r "$PYKMS_DIR/requirements.txt"
fi
$STD pip install tzlocal pysqlite3 Flask gunicorn
deactivate
mkdir -p /opt/py-kms/db
msg_ok "Installed py-kms"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/py-kms.service
[Unit]
Description=py-kms KMS Server Emulator
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=5
KillMode=process
User=root
WorkingDirectory=/opt/py-kms/py-kms
ExecStart=/opt/py-kms-env/bin/python3 /opt/py-kms/py-kms/pykms_Server.py 0.0.0.0 1688 -V INFO -F /var/log/pykms.log -w RANDOM --sqlite /opt/py-kms/db/pykms_database.db
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now py-kms.service

cat <<EOF >/etc/systemd/system/py-kms-webui.service
[Unit]
Description=py-kms WebUI
After=network.target py-kms.service

[Service]
Type=simple
Restart=always
RestartSec=5
KillMode=process
User=root
WorkingDirectory=/opt/py-kms/py-kms
Environment="PYKMS_SQLITE_DB_PATH=/opt/py-kms/db/pykms_database.db"
Environment="PYKMS_LICENSE_PATH=/opt/py-kms/LICENSE"
Environment="PYKMS_VERSION_PATH=/opt/py-kms/VERSION"
ExecStart=/opt/py-kms-env/bin/gunicorn --bind 0.0.0.0:8080 --log-level INFO pykms_WebUI:app
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now py-kms-webui.service
msg_ok "Created Services"

motd_ssh
customize
cleanup_lxc
