# Using Gentoo as the base image
FROM gentoo/stage3

LABEL maintainer="lastname@gmail.com" \
      version="0.1" \
      description=""

# Set the working directory
WORKDIR /root/

# Update system
RUN emerge-webrsync

# Install essential tools
RUN emerge dev-vcs/git 
RUN emerge dev-lang/python:3.8 
RUN emerge dev-util/cmake 
RUN emerge sys-devel/gcc 
RUN emerge sys-devel/make 
RUN emerge sys-libs/ncurses 
RUN emerge dev-libs/libxml2 
RUN emerge x11-libs/libX11 
RUN emerge media-libs/libsndfile 
RUN emerge x11-libs/libXrender 
RUN emerge x11-libs/libXcomposite 
RUN emerge x11-libs/libXcursor 
RUN emerge media-libs/libvorbis 
RUN emerge media-libs/libogg 
RUN emerge media-libs/flac 
RUN emerge media-libs/alsa-lib

# Install LLVM and Clang (replace with specific version if needed)
RUN emerge sys-devel/llvm 
RUN emerge sys-devel/clang

# Set Python and LLVM config
ENV PYTHONLIBPATH=/usr/lib/python3.8 \
    PYTHONINCLUDEPATH=/usr/include/python3.8 \
    CC=clang \
    CXX=clang++

# Download and build Faust
RUN git clone --branch v2.69.3 https://github.com/grame-cncm/faust.git \
    && cd faust \
    && mkdir build && cd build \
    && cmake . -DINCLUDE_LLVM=ON -DINCLUDE_STATIC=ON \
    && make && make install

# Modify DawDreamer Makefile
RUN sed -i '/-DBUILD_DAWDREAMER_FAUST/d' /root/DawDreamer/Builds/LinuxMakefile/Makefile

# Clone and build DawDreamer
RUN git clone https://github.com/DBraun/DawDreamer.git \
    && cd DawDreamer \
    && git submodule update --init --recursive \
    && mkdir Builds/LinuxMakefile/build \
    && cd Builds/LinuxMakefile/build \
    && cmake ../../.. \
    && make

CMD ["bash"]

