# mobymac

Automagically install Docker in a VirtualBox VM with super-fast NFS mounts.

## What does it do?

- Uninstall Docker for Mac
- Install Virtualbox
- Install docker client binaries
- Create a Vagrant VM with Docker installed
- Set up NFS mounts for VM
- Set up docker environment in `.bash_profile`, `.zprofile` or `fish.config` (optional!)

## Installation

1. Clone this repo
  ```bash
  git clone https://github.com/dziemba/mobymac.git ~/.mobymac
  cd ~/.mobymac
  ```

2. Run the installer
  ```bash
  # Install with default settings
  # (4096MB RAM, 50GB data disk, automatic shell integration, VM IP: 192.168.42.2)
  ./install.sh

  # Or run the installer with custom settings
  # ./install.sh [VM memory in MB] [data disk size in GB] [shell integration] [VM IP subnet]
  ./install.sh 2048
  ./install.sh 2048 30
  ./install.sh 2048 30 manual
  ./install.sh 2048 30 manual 192.168.142
  ```

- Shell integration can be either `auto` (default) or `manual`.
- IP subnet must be in the form of `a.b.c`.
- The host will use `a.b.c.1`, the VM will use `a.b.c.2`.

## Updating / Reinstallation

It's the same as installing - just run it again!

## Known Limitations

- Filesystem watching (inotify) [does not work](https://stackoverflow.com/questions/4231243/inotify-with-nfs).
  Please use polling instead if possible. See https://github.com/dziemba/mobymac/issues/6
- NFS mounts have less guarantees regarding FS consistency - in practise it should just work (tm)
- Ports are not mapped to localhost - use `192.168.42.2` to access docker ports

## Why?

- File system access is still slow in Docker for Mac: https://github.com/docker/roadmap/issues/7
- DNS queries with large responses are extremely slow: https://github.com/docker/for-mac/issues/4430

Docker for Mac is an awesome project - use it if you can.
Once the above issues have been resolved, this project will become obsolete.

## Troubleshooting

### `Cannot connect to the Docker daemon at tcp://192.168.42.2:2376. Is the docker daemon running?`

1. Start the VM: `VBoxManage startvm mobymac --type headless`
2. If that doesn't help, re-install mobymac.

### Virtualbox Installation fails

1. Uninstall virtualbox: `brew cask uninstall virtualbox`
2. If the above step failed: reboot and try again
3. Install virtualbox: `brew cask install virtualbox`
4. If the above step failed: Open *System Preferences -> Security & Privacy -> General*, then allow the kernel extension.
   Reboot and try step 3 again.
5. Run the mobymac installer (again).
6. If that still fails, try the whole process one more time and reboot generously.
   Open an Issue on this project if you're still having trouble.

### Creating the VM fails (VirtualBox error)

1. If the above step failed: Open *System Preferences -> Security & Privacy -> General*, then allow the kernel extension.
2. Reboot your computer.
2. Run the mobymac installer (again).

### `exports: ... conflicts with existing export ...`

1. Open /etc/exports: `sudo vim /etc/exports`
2. Delete all content
3. Run the mobymac installer (again).

### Other Problems

Please open an issue if you're stuck.

## Contributing

Feel free to open issues about feature requests or create PRs.

## License

MIT, see [LICENSE](LICENSE)
