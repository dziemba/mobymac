# mobymac

Automagically install Docker in a VirtualBox VM with super-fast NFS mounts.

## What does it do?

- Uninstall Docker for Mac
- Install Virtualbox
- Install docker client binaries
- Create a boot2docker VM
- Set up NFS mounts for VM
- Set up docker environment in `.bash_profile`, `.zprofile` or `fish.config` (optional!)

## Installation (easy)

Use the latest docker version, 4GB RAM for the VM and auto-detect shell integration:
```bash
curl -sfSL https://github.com/dziemba/mobymac/raw/master/install.sh |bash -s 4096
```

## Installation (advanced, recommended)

```bash
# download installer
curl -sfSL https://github.com/dziemba/mobymac/raw/master/install.sh -o mobymac.sh
chmod +x mobymac.sh

# verify that it does what you want
less mobymac.sh

# run it
./mobymac.sh

# ... or run it with more params:
# ./mobymac.sh [VM memory in MB] [shell integration] [Docker version]
./mobymac.sh 2048
./mobymac.sh 2048 zsh
./mobymac.sh 2048 zsh v18.09.1
```

Shell integration can be one of the following: `auto` (default), `bash`, `zsh`, `fish` or `manual`.

## Updating / Reinstallation

It's the same as installing - just run it again!

## Known Limitations

- Filesystem watching (inotify) [does not work](https://stackoverflow.com/questions/4231243/inotify-with-nfs).
  Please use polling instead if possible. See https://github.com/dziemba/mobymac/issues/6
- NFS mounts have less guarantees regarding FS consistency - in practise it should just work (tm)
- Ports are not mapped to localhost - run `docker-machine ip` to find out the docker VM IP

## Why?

- File system access is still slow in Docker for Mac: https://github.com/docker/roadmap/issues/7
- DNS queries with large responses are extremely slow: https://github.com/docker/for-mac/issues/4430

Docker for Mac is an awesome project - use it if you can.
Once the above issues have been resolved, this project will become obsolete.

## Troubleshooting

### Virtualbox Installation fails

1. Uninstall virtualbox: `brew cask uninstall virtualbox`
2. If the above step failed: reboot and try again
3. Install virtualbox: `brew cask install virtualbox`
4. If the above step failed: Open *System Preferences -> Security & Privacy -> General*, then allow the kernel extension.
   Reboot and try step 3 again.
5. Run the mobymac installer (again).
6. If that still fails, try the whole process one more time and reboot generously.
   Open an Issue on this project if you're still having trouble.

### Other Problems

Please open an issue if you're stuck.

## Contributing

Feel free to open issues about feature requests or create PRs.

## License

MIT, see [LICENSE](LICENSE)
