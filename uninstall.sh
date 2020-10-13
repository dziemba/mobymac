#!/bin/bash
set -e -E -u -o pipefail
cd "$(dirname "$0")"

PLIST="$HOME/Library/LaunchAgents/com.dziemba.mobymac.plist"

function main() {
  echo "==========="
  echo "  mobymac  "
  echo " UNINSTALL "
  echo "==========="
  echo
  echo "WARNING: this will uninstall mobymac and destroy all existing docker data"
  echo "Press CTRL-C to abort (sleeping for 5 seconds)"
  sleep 5
  echo

  echo "=== Checking for mobymac updates (set MOBYMAC_NO_UPDATES=1 to skip)..."
  if [ -z "${MOBYMAC_NO_UPDATES-}" ]; then
    git fetch
    if [ "$(git rev-list HEAD...origin/master --count)" -ne 0 ]; then
      echo "==> Updates available - please 'git pull', then run the uninstaller again."
      exit 2
    fi
    echo "==> OK"
  else
    echo "==> Skipping"
  fi
  echo

  echo "=== Removing mobymac/docker-machine VMs..."
  for VM in default mobymac; do
    if VBoxManage showvminfo "$VM" &>/dev/null; then
      echo "=== Shut down and destroy: '$VM'"
      VBoxManage controlvm "$VM" poweroff || true
      sleep 10
      VBoxManage unregistervm "$VM" --delete
    else
      echo "=== No VM with name: '$VM'"
    fi
  done
  echo "=== Remaining VMs (please clean up manually if needed):"
  VBoxManage list vms
  echo "==> OK"
  echo

  echo "=== Removing vagrant state..."
  rm -rf .vagrant Vagrantfile
  echo "==> OK"
  echo

  echo "=== Removing all NFS mounts on host..."
  echo "=== NOTE: sudo will be required to edit /etc/exports and restart NFS server"
  echo |sudo tee /etc/exports
  nfsd checkexports
  sudo nfsd restart
  echo "==> OK"
  echo

  echo "=== Removing mobymac launch-at-login plist..."
  rm -f "$PLIST"
  echo "==> OK"
  echo

  echo "=== Removing docker host env from shell config..."
  for FILE in "$HOME/.bash_profile" "$HOME/.zprofile" "$HOME/.config/fish/config.fish"; do
    sed -i -e '/^# mobymac-begin/{N;N;d;}' "$FILE"
  done
  echo "==> OK"
  echo

  echo "=== Uninstalled successfully!"
  echo "=== Please re-open all your terminal windows to complete the process."
}

main
