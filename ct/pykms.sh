#!/usr/bin/env bash
# Engine comes from community-scripts/core; this repo only ships the scripts.
# Local checkout wins (COMMUNITY_SCRIPTS_CORE_DIR, else a sibling ../core), so a
# fork/branch of core can be tested without touching this file.
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")

# Copyright (c) 2024-2026 community-scripts ORG
# Author: Randy
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/Py-KMS-Organization/py-kms

APP="PyKMS"
var_tags="${var_tags:-kms;activation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/py-kms ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating py-kms"
  cd /opt/py-kms
  if git pull | grep -q 'Already up to date.'; then
    msg_ok "py-kms is already up to date"
  else
    msg_info "Stopping Services"
    systemctl stop py-kms py-kms-webui
    msg_ok "Stopped Services"

    msg_info "Starting Services"
    systemctl start py-kms py-kms-webui
    msg_ok "Started Services"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access KMS Server IP: ${BGN}${IP}:1688${CL}"
echo -e "${INFO}${YW} Access WebUI URL: ${BGN}http://${IP}:8080${CL}"
