# Using Ubuntu 20.04 as the base image
FROM ubuntu:20.04

LABEL maintainer="lastname@gmail.com" \
      version="0.1" \
      description=""

# Set the working directory
WORKDIR /root/

# Set the environment variables
ENV LANG=C.UTF-8 \
    TZ=Etc/UTC \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONLIBPATH=/usr/lib/python3.8 \
    PYTHONINCLUDEPATH=/usr/include/python3.8

# Setting the timezone and installing essential packages
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt-get update \
    && apt-get install -y lsb-release software-properties-common wget python3-pip python3-dev git build-essential cmake g++ make nasm curl unzip libgl1-mesa-dev \
    && bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" \
    && apt-get install -y lv2-c++-tools libgtkmm-2.4-1v5 pkg-config lv2-dev libgtkmm-2.4-dev \
       libsndfile1 libx11-dev libxrandr-dev libxinerama-dev libxrender-dev libxcomposite-dev libxcursor-dev libfreetype6-dev libsndfile1-dev \
       libvorbis-dev libopus-dev libflac-dev libasound2-dev alsa-utils


RUN wget https://github.com/grame-cncm/faust/releases/download/2.69.3/faust-2.69.3.tar.gz \
    && tar zxvf faust-2.69.3.tar.gz

#    && cd faust-2.69.3 \
#    && make \
#    && make install

#RUN apt-get install -y libpolly-17-dev faust
RUN apt-get install -y libpolly-17-dev

# Set up symlink for llvm-config if necessary
RUN ln -s /usr/bin/llvm-config-17 /usr/bin/llvm-config

RUN mkdir faust-2.69.3/build/lib
##RUN cd faust-2.69.3/build/lib && ln -s /usr/lib/aarch64-linux-gnu/libfaust.a
#RUN cd faust-2.69.3/build/
# cmake . -DINCLUDE_LLVM=ON -DINCLUDE_STATIC=ON && make && make -f Make.llvm.static && make install
# make install

# Clone repositories and install Python packages
RUN git clone https://github.com/zynthian/moog.git \
    && pip3 install pedalboard \
    && git clone https://github.com/DBraun/DawDreamer.git \
    && cd DawDreamer \
    && git submodule init \
    && git submodule update

# Build libsamplerate
RUN cd DawDreamer/thirdparty/libsamplerate \
    && cmake -DCMAKE_BUILD_TYPE=Release -Bbuild_release -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    && cd build_release \
    && make CONFIG=Release

# Build DawDreamer
#RUN cd DawDreamer/Builds/LinuxMakefile \
#    && make VERBOSE=1 CONFIG=Release LIBS="-lstdc++fs" LDFLAGS="-L/__w/DawDreamer/DawDreamer/alsa-lib/src -L$PYTHONLIBPATH -L/root/faust-2.69.3/lib -L/root/faust-2.69.3/build/lib/" CXXFLAGS="-I../../alsa-lib/include -I/usr/include/python3.8 -I$PYTHONINCLUDEPATH" \
#    && mv build/libdawdreamer.so ../../dawdreamer/dawdreamer.so
#    && cd ../.. && python3 setup.py build  && python3 setup.py install

# Build moog
RUN cd moog \
    && CXXFLAGS="-I/usr/include/lv2-c++-tools" CFLAGS="-I/usr/include/lv2-c++-tools" make \
    && make install

# Print environment variables (for debugging)
RUN echo "PYTHONLIBPATH: $PYTHONLIBPATH" \
    && echo "PYTHONINCLUDEPATH: $PYTHONINCLUDEPATH"

# Final command
CMD ["echo", "build_linux.sh is done!"]
