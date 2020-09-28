#!/bin/bash -e

if [ "$1" == "boot" ]; then
  # wait a bit before starting the VM to prevent NFS mount issues...
  sleep 30
fi

/Applications/VirtualBox.app/Contents/MacOS/VBoxManage startvm mobymac --type headless
