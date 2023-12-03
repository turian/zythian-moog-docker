# Using Ubuntu 22.04 as the base image
FROM ubuntu:22.04

LABEL maintainer="lastname@gmail.com" \
      version="0.1" \
      description=""

# Set the working directory
WORKDIR /root/

# Set the environment variables
ENV LANG=C.UTF-8 \
    TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONLIBPATH=/usr/lib/python3.10 \
    PYTHONINCLUDEPATH=/usr/include/python3.10

# Setting the timezone and installing essential packages
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get install -y lsb-release software-properties-common wget python3-pip python3-dev git build-essential cmake g++ make nasm curl unzip libgl1-mesa-dev \
    && apt-get install -y lv2-c++-tools libgtkmm-2.4-1v5 pkg-config lv2-dev libgtkmm-2.4-dev \
       libsndfile1 libx11-dev libxrandr-dev libxinerama-dev libxrender-dev libxcomposite-dev libxcursor-dev libfreetype6-dev libsndfile1-dev \
       libvorbis-dev libopus-dev libflac-dev libasound2-dev alsa-utils
#    && bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" \

# Clone repositories and install Python packages
RUN git clone https://github.com/zynthian/moog.git \
    && pip3 install pedalboard \
    && git clone https://github.com/DBraun/DawDreamer.git \
    && cd DawDreamer \
    && git submodule init \
    && git submodule update

# Modify Makefile
RUN perl -i -pe 's/ -lfaustwithllvm//' DawDreamer/Builds/LinuxMakefile/Makefile
RUN perl -i -pe 's/ "-DBUILD_DAWDREAMER_FAUST"//' DawDreamer/Builds/LinuxMakefile/Makefile

# Build libsamplerate
RUN cd DawDreamer/thirdparty/libsamplerate && \
	cmake -DCMAKE_BUILD_TYPE=Release -Bbuild_release -DCMAKE_POSITION_INDEPENDENT_CODE=ON && \
	cd build_release && \
	make CONFIG=Release

# Build DawDreamer
RUN cd DawDreamer/Builds/LinuxMakefile \
    && make -j8 VERBOSE=1 CONFIG=Release LIBS="-lstdc++fs" CXXFLAGS="-I../../alsa-lib/include -I/usr/include/python3.10 -I$PYTHONINCLUDEPATH"  LDFLAGS="-L/__w/DawDreamer/DawDreamer/alsa-lib/src -L$PYTHONLIBPATH -L/root/faust-2.69.3/lib -L/root/faust-2.69.3/build/lib/"

# Move the built library
RUN cd DawDreamer/Builds/LinuxMakefile && mv build/libdawdreamer.so ../../dawdreamer/dawdreamer.so

# Build and install the Python package
RUN cd DawDreamer && python3 setup.py build && python3 setup.py install

# Test import of DawDreamer
RUN { python3 -c "import dawdreamer"; }
