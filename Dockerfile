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

# Download and extract Faust
RUN wget https://github.com/grame-cncm/faust/releases/download/2.69.3/faust-2.69.3.tar.gz \
    && tar zxvf faust-2.69.3.tar.gz

# Install additional dependencies
RUN apt-get install -y libpolly-17-dev

# Set up symlink for llvm-config if necessary
RUN ln -s /usr/bin/llvm-config-17 /usr/bin/llvm-config


# Log LLVM version and installations
RUN echo "LLVM Versions Installed:" > /root/build_logs.txt \
    && apt list --installed | grep llvm >> /root/build_logs.txt \
    && echo "\nllvm-config version:" >> /root/build_logs.txt \
    && llvm-config --version >> /root/build_logs.txt

# Build Faust and log the process
RUN echo "\nBuilding Faust..." >> /root/build_logs.txt \
    && mkdir faust-2.69.3/build/lib \
    && cd faust-2.69.3/build/ \
    && { cmake . -DINCLUDE_LLVM=ON -DINCLUDE_STATIC=ON && make && make -f Make.llvm.static && make install; } >> /root/build_logs.txt 2>&1

# Clone repositories and install Python packages
RUN echo "\nCloning repositories and installing Python packages..." >> /root/build_logs.txt \
    && git clone https://github.com/zynthian/moog.git \
    && pip3 install pedalboard \
    && git clone https://github.com/DBraun/DawDreamer.git \
    && cd DawDreamer \
    && git submodule init \
    && git submodule update

# Ensure the DawDreamer/Builds/LinuxMakefile directory exists and list its contents for verification
RUN echo "\nChecking DawDreamer/Builds/LinuxMakefile directory..." >> /root/build_logs.txt \
    && ls -la DawDreamer/Builds/LinuxMakefile >> /root/build_logs.txt 2>&1


# Copy the log file to the accessible location after the build step
RUN cp /root/build_logs.txt /

# Run make with VERBOSE and CONFIG in the DawDreamer build directory and log the output
RUN echo "\nBuilding DawDreamer..." >> /root/build_logs.txt \
    && cd DawDreamer/Builds/LinuxMakefile \
    && make VERBOSE=1 CONFIG=Release LIBS="-lstdc++fs" CXXFLAGS="-I../../alsa-lib/include -I/usr/include/python3.8 -I$PYTHONINCLUDEPATH"  LDFLAGS="-L/__w/DawDreamer/DawDreamer/alsa-lib/src -L$PYTHONLIBPATH -L/root/faust-2.69.3/lib -L/root/faust-2.69.3/build/lib/" >> /root/build_logs.txt 2>&1

# Move the built library
RUN cd DawDreamer/Builds/LinuxMakefile && mv build/libdawdreamer.so ../../dawdreamer/dawdreamer.so

# Build and install the Python package and log the output
RUN cd DawDreamer && python3 setup.py build >> /root/build_logs.txt 2>&1
RUN cd DawDreamer && python3 setup.py install >> /root/build_logs.txt 2>&1

# Test import of DawDreamer and log the output
RUN { python3 -c "import dawdreamer"; } >> /root/build_logs.txt 2>&1 || echo "Import failed" >> /root/build_logs.txt

# Final command
CMD ["cat", "/root/build_logs.txt"]
