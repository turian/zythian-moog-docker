# zythian-moog-docker

docker pull turian/zynthian-moog
# Or, build the docker yourself
#docker build -t turian/zynthian-moog .

This is specifically for ARM architectures, and might need to be tweaked slightly for intel.
For intel, the asm moog can be built.

docker build -t turian/zynthian-moog-gentoo -f Dockerfile-gentoo ../

