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
    && apt-get install -y lv2-c++-tools libgtkmm-2.4-1v5 pkg-config lv2-dev libgtkmm-2.4-dev \
       libsndfile1 libx11-dev libxrandr-dev libxinerama-dev libxrender-dev libxcomposite-dev libxcursor-dev libfreetype6-dev libsndfile1-dev \
       libvorbis-dev libopus-dev libflac-dev libasound2-dev alsa-utils


# Install additional packages
RUN apt-get install -y lv2-c++-tools libgtkmm-2.4-1v5 pkg-config lv2-dev libgtkmm-2.4-dev \
   libsndfile1 libx11-dev libxrandr-dev libxinerama-dev libxrender-dev libxcomposite-dev libxcursor-dev libfreetype6-dev libsndfile1-dev \
   libvorbis-dev libopus-dev libflac-dev libasound2-dev alsa-utils


# Download and extract Faust
RUN wget https://github.com/grame-cncm/faust/releases/download/2.69.3/faust-2.69.3.tar.gz \
    && tar zxvf faust-2.69.3.tar.gz

# Add LLVM repository and install LLVM-17
# ALL=1 needed for libpolly
RUN wget https://apt.llvm.org/llvm.sh \
    && sed -i 's/^ALL=0/ALL=1/' llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 17 \
    && apt-get update
#
#RUN echo apt-cache search llvm
#RUN apt-get install -y llvm-17 llvm-17-dev llvm-17-tools libllvm17

# Set up symlink for llvm-config if necessary
RUN ln -sf /usr/bin/llvm-config-17 /usr/bin/llvm-config

# Log LLVM version and installations
RUN echo "LLVM Versions Installed:" > /root/build_logs.txt \
    && apt list --installed | grep llvm >> /root/build_logs.txt \
    && echo "\nllvm-config version:" >> /root/build_logs.txt \
    && llvm-config --version >> /root/build_logs.txt

# Clone repositories and install Python packages
RUN echo "\nCloning repositories and installing Python packages..." >> /root/build_logs.txt \
    && git clone https://github.com/zynthian/moog.git \
    && pip3 install pedalboard \
    && git clone https://github.com/DBraun/DawDreamer.git \
    && cd DawDreamer \
    && git submodule init \
    && git submodule update

# Build Faust and log the process
RUN echo "\nBuilding Faust..." >> /root/build_logs.txt \
    && mkdir faust-2.69.3/build/lib \
    && cd faust-2.69.3/build/ \
    && cmake . -DINCLUDE_LLVM=ON -DINCLUDE_STATIC=ON \
    && make \
    && make -f Make.llvm.static \
    && make install \
    >> /root/build_logs.txt 2>&1

# Ensure the DawDreamer/Builds/LinuxMakefile directory exists and list its contents for verification
RUN echo "\nChecking DawDreamer/Builds/LinuxMakefile directory..." >> /root/build_logs.txt \
    && ls -la DawDreamer/Builds/LinuxMakefile >> /root/build_logs.txt 2>&1

# Copy the diagnostic script into the container
COPY diagnostic_build.sh /root/diagnostic_build.sh
RUN chmod +x /root/diagnostic_build.sh

# Final command
CMD ["bash"]
