#!/bin/bash
set -e

SHELL_INTEGRATION="${1:-manual}"
MEM="${2:-4096}"
VER="${3:-v19.03.5}"

VMNAME="default"
ENV_LINE="docker-machine env ${VMNAME}"
EVAL_LINE="eval \"\$(docker-machine env ${VMNAME})\""
EVAL_LINE_FISH="eval (docker-machine env ${VMNAME} --shell fish)"

function main() {
  echo "========="
  echo " mobymac "
  echo "========="
  echo
  echo "Creating docker ${VER} VM with ${MEM}MB RAM and $SHELL_INTEGRATION shell integration"
  echo
  echo "WARNING: this will uninstall docker4mac and destroy all existing docker data"
  echo "Press CTRL-C to abort (sleeping for 5 seconds)"
  sleep 5
  echo

  if [ ! -e /usr/local/bin/brew ]; then
    echo "Homebrew not installed - Aborting!"
    exit 1
  fi

  echo "=== Uninstalling Docker for Mac (brew cask)..."
  if brew cask list |grep ^docker$; then
    brew cask uninstall docker
    echo "===> OK"
  else
    echo "=== Not found - skipping"
  fi
  echo

  echo "=== Uninstalling Docker for Mac (native)..."
  if [ -e /Applications/Docker.app ]; then
    /Applications/Docker.app/Contents/MacOS/Docker --uninstall
    rm -rf /Applications/Docker.app
    echo "===> OK"
  else
    echo "=== Not found - skipping"
  fi
  echo

  echo "=== Installing Virtualbox..."
  if [ ! -e /Applications/VirtualBox.app ]; then
    brew cask install virtualbox
    echo "===> OK"
  else
    echo "=== Already installed - skipping"
  fi
  echo

  echo "=== Removing old docker packages..."
  brew uninstall --force docker docker-compose docker-machine docker-machine-nfs
  rm -f /usr/local/bin/{docker,docker-compose,docker-machine,docker-machine-nfs}
  echo "===> OK"
  echo

  echo "=== Installing docker packages..."
  brew install docker docker-compose docker-machine docker-machine-nfs
  echo "===> OK"
  echo

  echo "=== Removing existing VMs..."
  docker-machine rm -f ${VMNAME} || true
  echo "===> OK"
  echo

  echo "=== Creating docker VM..."
  ISO="https://github.com/boot2docker/boot2docker/releases/download/${VER}/boot2docker.iso"
  docker-machine create ${VMNAME} \
    --engine-storage-driver overlay2 \
    --engine-opt experimental=true \
    -d virtualbox \
    --virtualbox-cpu-count "$(sysctl -n hw.physicalcpu)" \
    --virtualbox-memory "${MEM}" \
    --virtualbox-disk-size 40000 \
    --virtualbox-no-share \
    --virtualbox-boot2docker-url "${ISO}"
  echo "===> OK"
  echo

  echo "=== Setting up NFS mount..."
  docker-machine-nfs ${VMNAME} --mount-opts="noacl,async,noatime,actimeo=1,nfsvers=3"
  echo "===> OK"
  echo

  echo "=== Setting up VM service..."
  brew services start docker-machine
  echo "===> OK"
  echo

  echo "=== Applying docker config..."
  eval "$(docker-machine env ${VMNAME} --shell bash)"
  echo "===> OK"
  echo

  case "$SHELL_INTEGRATION" in
  bash)
    echo "=== Adding docker config to .bash_profile"
    F="$HOME/.bash_profile"
    touch "$F"
    if ! grep -q "${ENV_LINE}" "$F"; then
      echo "${EVAL_LINE}" >> "$F"
    fi
    ;;

  zsh)
    echo "=== Adding docker config to .zprofile"
    F="$HOME/.zprofile"
    touch "$F"
    if ! grep -q "${ENV_LINE}" "$F"; then
      echo "${EVAL_LINE}" >> "$F"
    fi
    ;;

  fish)
    echo "=== Adding docker config to config.fish"
    F="$HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$F")"
    touch "$F"
    if ! grep -q "${ENV_LINE}" "$F"; then
      echo "${EVAL_LINE_FISH}" >> "$F"
    fi
    ;;

  *)
    echo "==="
    echo "=== ACTION REQUIRED: Add docker config to your shell's profile file"
    echo "==="
    echo "=== Please add the appropriate line to your shell's configuration:"
    echo "==="
    echo
    echo ".bash_profile (bash) / .zprofile (zsh):"
    echo "   ${EVAL_LINE}"
    echo
    echo "config.fish (fish):"
    echo "   ${EVAL_LINE_FISH}"
    echo
    echo "Press ENTER when you're done."
    read -r
    ;;
  esac
  echo "===> OK"
  echo

  echo "=== Testing docker..."
  docker run --rm hello-world
  echo "=== Finished. It works!"
  echo
}

main
