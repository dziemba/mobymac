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

## Reinstallation

Reinstalling is the same as installing!

## Notes

- Yes, the name *mobymac* is very confusing.
- This will destroy all your existing docker data, be careful!
- NFS mounts have less guarantees regarding FS consistency - in practise it should just work (tm)
- Ports are not mapped to localhost - run `docker-machine ip` to find out the docker VM IP
- If the script fails with an error message like
`Error creating machine: Error in driver during machine creation...`,
make sure to check Settings > Security & Privacy, and allow an install from Oracle,
if prompted in that panel.

## Why?

Docker for Mac is an awesome project - use it if you can. It is however still slower than this
approach. Also there are some weird DNS issues that do not occur with a VBox solution.
When Docker for Mac is stable enough, this project will become obsolete.

## Further Reading

- https://github.com/adlogix/docker-machine-nfs
- https://github.com/docker/for-mac/issues/77
- https://forums.docker.com/t/file-access-in-mounted-volumes-extremely-slow-cpu-bound/8076/256

## Contributing
I'm happy about any feedback! Feel free to open issues or create PRs.

## License

MIT, see [LICENSE](LICENSE)
