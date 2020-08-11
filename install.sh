#!/bin/bash
set -e -u -o pipefail
cd "$(dirname "$0")"

VM_NAME="mobymac"

# command line arguments
RAM="${1:-4096}"
DISKSIZE="${2:-50}"
SHELL_INTEGRATION="${3:-auto}"
SUBNET="${4:-192.168.42}"

HOST_IP="${SUBNET}.1" # when given a 192.168.x.y IP, vagrant assigns 192.168.x.1 to the host
VM_IP="${SUBNET}.2"
ENV_LINE="export DOCKER_HOST='tcp://${VM_IP}:2376'"
ENV_LINE_FISH="set -x DOCKER_HOST 'tcp://${VM_IP}:2376';"
DOCKER_MACHINE_LINE="docker-machine env"
EXPORTS_LINE="${HOME} ${VM_IP} -alldirs -mapall=$(id -u):$(id -g)"
PLIST="$HOME/Library/LaunchAgents/com.dziemba.mobymac.plist"

error_banner() {
 echo
 echo
 echo "+===============================================+"
 echo "|               ERRORS FOUND                    |"
 echo "| Inspect logs and ask for assistance if needed |"
 echo "+===============================================+"
 echo
 echo "For troubleshooting help, go to:"
 echo "https://github.com/dziemba/mobymac#troubleshooting"
}
trap error_banner ERR

lineinfile() {
  FILE="$1"
  LINE="$2"
  SUDO="${3-}"
  TMP="$(mktemp)"
  MARKER_BEGIN="# mobymac-begin"
  MARKER_END="# mobymac-end"

  $SUDO mkdir -p "$(dirname "$FILE")"
  $SUDO touch "$FILE"

  (
  sed "/^${MARKER_BEGIN}/,/^${MARKER_END}/d" "$FILE"
  echo "$MARKER_BEGIN"
  echo "$LINE"
  echo "$MARKER_END"
  ) > "$TMP"

  # shellcheck disable=SC2002
  cat "$TMP" |$SUDO tee "$FILE" > /dev/null

  rm "$TMP"
}

removefromfile() {
  FILE="$1"
  EXPR="$2"
  TMP="$(mktemp)"

  sed "/${EXPR}/d" "$FILE" > "$TMP"
  cat "$TMP" > "$FILE"
  rm "$TMP"
}

gen_vagrantfile() {
  cat <<EOD
# AUTOGENERATED DO NOT EDIT - see install.sh

VM_DIR = %x(VBoxManage list systemproperties).lines
  .find { |l| l.start_with?('Default machine folder:') }
  .split(':').last.strip

Vagrant.configure('2') do |config|
  config.vm.box = 'debian/buster64'
  config.vm.provider 'virtualbox' do |v|
    v.name = '${VM_NAME}'
    v.cpus = $(sysctl -n hw.physicalcpu)
    v.memory = ${RAM}

    data_disk = "#{VM_DIR}/#{v.name}/data.vdi"
    v.customize ['createhd', '--filename', data_disk, '--size', ${DISKSIZE} * 1024]
    v.customize ['storageattach', :id, '--storagectl', 'SATA Controller',
      '--port', 1, '--device', 0, '--type', 'hdd', '--medium', data_disk]
    end

  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provision :shell, path: 'provision_vm.sh', args: ['${HOST_IP}', '${HOME}']
  config.vm.network :private_network, ip: '${VM_IP}'
end
EOD
}

gen_plist() {
  cat <<EOD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.dziemba.mobymac</string>
    <key>ProgramArguments</key>
    <array>
      <string>/Applications/VirtualBox.app/Contents/MacOS/VBoxManage</string>
      <string>startvm</string>
      <string>${VM_NAME}</string>
      <string>--type</string>
      <string>headless</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOD
}

function main() {
  echo "========="
  echo " mobymac "
  echo "========="
  echo
  echo "Creating a fresh docker VM with these settings:"
  echo "RAM: ${RAM}MB"
  echo "Data disk: ${DISKSIZE}GB"
  echo "Shell integration: ${SHELL_INTEGRATION}"
  echo "VM IP: ${VM_IP}"
  echo
  echo "WARNING: this will uninstall docker4mac and destroy all existing docker data"
  echo "Press CTRL-C to abort (sleeping for 5 seconds)"
  sleep 5
  echo

  if [ ! -e /usr/local/bin/brew ]; then
    echo "Homebrew not installed - Aborting!"
    exit 1
  fi

  echo "=== Checking for mobymac updates (set MOBYMAC_NO_UPDATES=1 to skip)..."
  if [ -z "${MOBYMAC_NO_UPDATES-}" ]; then
    git fetch
    if [ "$(git rev-list HEAD...origin/master --count)" -ne 0 ]; then
      echo "==> Updates available - please 'git pull', then run the installer again."
      exit 2
    fi
    echo "==> OK"
  else
    echo "==> Skipping"
  fi
  echo

  echo "=== Writing Vagrantfile..."
  gen_vagrantfile > Vagrantfile
  echo "=== OK"
  echo

  echo "=== Uninstalling Docker for Mac (brew cask)..."
  if brew cask list |grep ^docker$; then
    brew cask uninstall docker
    echo "==> OK"
  else
    echo "==> Not found - skipping"
  fi
  echo

  echo "=== Uninstalling Docker for Mac (native)..."
  if [ -e /Applications/Docker.app ]; then
    /Applications/Docker.app/Contents/MacOS/Docker --uninstall
    rm -rf /Applications/Docker.app
    echo "==> OK"
  else
    echo "==> Not found - skipping"
  fi
  echo

  echo "=== Installing Virtualbox..."
  if [ ! -e /Applications/VirtualBox.app ]; then
    brew cask install virtualbox
    echo "==> OK"
  else
    echo "==> Already installed - skipping"
  fi
  echo "=== Version: $(VBoxManage --version)"
  echo

  echo "=== Installing Vagrant..."
  if [ ! -e /usr/local/bin/vagrant ]; then
    brew cask install vagrant
    echo "==> OK"
  else
    echo "==> Already installed - skipping"
  fi
  echo "=== Version: $(vagrant --version)"
  echo

  echo "=== Removing old docker packages..."
  brew uninstall --force docker docker-compose docker-machine docker-machine-nfs
  rm -f /usr/local/bin/{docker,docker-compose,docker-machine,docker-machine-nfs}
  echo "==> OK"
  echo

  echo "=== Installing docker packages..."
  brew install docker docker-compose
  echo "==> OK"
  echo

  echo "=== Removing old mobymac/docker-machine VMs..."
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

  echo "=== Removing existing docker configuration..."
  if [ -e "$HOME/.docker" ]; then
    rm -rfv "$HOME/.docker"
    echo "==> OK"
  else
    echo "==> Not found - skipping"
  fi
  echo

  echo "=== Removing leftover vagrant state..."
  rm -rf .vagrant
  echo "==> OK"
  echo

  echo "=== Setting up NFS mount on host..."
  echo "=== Mounted homedir: ${HOME}"
  echo "=== NOTE: sudo will be required to edit /etc/exports and restart NFS server"
  lineinfile /etc/exports "$EXPORTS_LINE" sudo
  nfsd checkexports
  sudo nfsd restart
  echo "==> OK"
  echo

  echo "=== Creating docker VM..."
  vagrant up
  echo "==> OK"
  echo

  echo "=== Setting up VM launch-at-login plist..."
  mkdir -p "$(dirname "$PLIST")"
  gen_plist > "$PLIST"
  launchctl load -w "$PLIST"
  echo "==> OK"
  echo

  echo "=== Applying docker config..."
  eval "${ENV_LINE}"
  # unset potential leftovers from `docker-machine env`
  export DOCKER_TLS_VERIFY=""
  export DOCKER_TLS=""
  echo "==> OK"
  echo

  echo "=== Testing docker and NFS volume mounts..."
  docker run --rm -w "$(pwd)" -v "$(pwd):$(pwd):ro" busybox ls install.sh >/dev/null
  echo "==> Finished. It works!"
  echo

  echo "=== Adding docker host env to shell config..."
  case "$SHELL_INTEGRATION" in
    auto)
      lineinfile "$HOME/.bash_profile" "$ENV_LINE"
      lineinfile "$HOME/.zprofile" "$ENV_LINE"
      lineinfile "$HOME/.config/fish/config.fish" "$ENV_LINE_FISH"

      # remove leftover docker-machine config which would now cause errors
      removefromfile "$HOME/.bash_profile" "$DOCKER_MACHINE_LINE"
      removefromfile "$HOME/.zprofile" "$DOCKER_MACHINE_LINE"
      removefromfile "$HOME/.config/fish/config.fish" "$DOCKER_MACHINE_LINE"
      ;;

    manual)
      echo "==="
      echo "=== ACTION REQUIRED: Add docker config to your shell's profile file"
      echo "==="
      echo "=== Please add the appropriate line to your shell's configuration:"
      echo "==="
      echo
      echo ".bash_profile (bash) / .zprofile (zsh):"
      echo "   ${ENV_LINE}"
      echo
      echo "config.fish (fish):"
      echo "   ${ENV_LINE_FISH}"
      echo
      echo "=== Make sure to remove any leftover 'docker-machine env' lines!"
      ;;

    *)
      echo "Unknown shell integration type. Aborting!"
      exit 1
      ;;
  esac
  echo "==> OK"
  echo

  echo "=== Please re-open all your terminal windows for the new docker settings to apply!"
}

main
