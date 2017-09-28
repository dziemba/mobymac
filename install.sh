#!/bin/bash
set -e

MEM="${1:-4096}"
VER="${2:-v17.09.0-ce}"

VMNAME="mobymac"
ENV_LINE="docker-machine env ${VMNAME}"
EVAL_LINE="eval \"\$(docker-machine env ${VMNAME})\""

echo "========="
echo " mobymac "
echo "========="
echo
echo "Creating docker ${VER} VM with ${MEM}MB RAM"
echo
echo "WARNING: this will uninstall docker4mac and destroy all existing docker data"
echo "Press CTRL-C to abort (sleeping for 5 seconds)"
sleep 5
echo

if [ ! -e /usr/local/bin/brew ]; then
  echo "Homebrew not installed - Aborting!"
  exit 1
fi

echo "=== Uninstalling Docker for Mac..."
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
  brew tap caskroom/cask
  brew cask install virtualbox
  echo "===> OK"
else
  echo "=== Already installed - skipping"
fi
echo

echo "=== (Re-)installing docker packages..."
brew uninstall --force docker docker-compose docker-machine docker-machine-nfs
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
  --virtualbox-cpu-count -1 \
  --virtualbox-memory ${MEM} \
  --virtualbox-disk-size 40000 \
  --virtualbox-no-share \
  --virtualbox-boot2docker-url ${ISO}
echo "===> OK"
echo

echo "=== Setting up NFS mount..."
docker-machine-nfs ${VMNAME}
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

echo "=== Adding docker config to .bash_profile"
touch $HOME/.bash_profile
if ! grep -q "${ENV_LINE}" $HOME/.bash_profile; then
  echo "${EVAL_LINE}" >> $HOME/.bash_profile
 fi
echo "===> OK"
echo

echo "=== Adding docker config to .zsh_profile"
touch $HOME/.zsh_profile
if ! grep -q "${ENV_LINE}" $HOME/.zsh_profile; then
  echo "${EVAL_LINE}" >> $HOME/.zsh_profile
 fi
echo "===> OK"
echo

echo "=== Testing docker..."
docker run docker/whalesay cowsay meow
echo "=== Finished. It works!"
echo
