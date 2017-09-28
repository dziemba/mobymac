# mobymac

Automagically install Docker in a VirtualBox VM with super-fast NFS mounts.

## What does it do?

- Uninstall Docker for Mac
- Install Virtualbox
- Install docker client binaries
- Create a boot2docker VM
- Set up NFS mounts for VM
- Set up docker environment in `.bash_profile` and `.zsh_profile`

## Installation (easy)

Use the latest docker version and 4GB RAM for the VM:
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
# ./mobymac.sh [VM memory in MB] [Docker version]
./mobymac.sh 2048
./mobymac.sh 2048 v17.06.0-ce
```

## Notes

- Yes, the name *mobymac* is very confusing.
- This will destroy all your existing docker data, be careful!
- NFS mounts have less guarantees regarding FS consistency - in practise it should just work (tm)
- Ports are not mapped to localhost - run `docker-machine ip mobymac` to find out the docker VM IP

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
