#!/bin/bash

# Diagnostic Build Script for Debugging Linking Errors with Parallel Building

# Define log file paths
FAUST_BUILD_LOG="/root/faust_build_log.txt"
DAWDREAMER_BUILD_LOG="/root/dawdreamer_build_log.txt"
DAWDREAMER_TEST_LOG="/root/dawdreamer_test_log.txt"

# Step 1: Build Faust with Detailed Logging and Parallel Building
echo "Building Faust with parallel jobs..." | tee -a $FAUST_BUILD_LOG
mkdir -p /root/faust-2.69.3/build/lib
cd /root/faust-2.69.3/build/
cmake . -DINCLUDE_LLVM=ON -DINCLUDE_STATIC=ON 2>&1 | tee -a $FAUST_BUILD_LOG
make -j8 VERBOSE=1 2>&1 | tee -a $FAUST_BUILD_LOG
make -f Make.llvm.static VERBOSE=1 2>&1 | tee -a $FAUST_BUILD_LOG
make install 2>&1 | tee -a $FAUST_BUILD_LOG

# Step 2: Verify DawDreamer Directory
echo "Verifying DawDreamer directory..." | tee -a $DAWDREAMER_BUILD_LOG
ls -la /root/DawDreamer/Builds/LinuxMakefile | tee -a $DAWDREAMER_BUILD_LOG

# Build libsamplerate
echo "Build libsamplerate" | tee -a $DAWDREAMER_BUILD_LOG
cd /root/DawDreamer/thirdparty/libsamplerate
cmake -DCMAKE_BUILD_TYPE=Release -Bbuild_release -DCMAKE_POSITION_INDEPENDENT_CODE=ON
cd build_release
make CONFIG=Release 2>&1 | tee -a $DAWDREAMER_BUILD_LOG

# Step 3: Build DawDreamer with Verbose Output and Parallel Building
echo "Building DawDreamer with parallel jobs..." | tee -a $DAWDREAMER_BUILD_LOG
cd /root/DawDreamer/Builds/LinuxMakefile
make -j8 VERBOSE=1 CONFIG=Release LIBS="-lstdc++fs" \
     CXXFLAGS="-I../../alsa-lib/include -I/usr/include/python3.10 -I$PYTHONINCLUDEPATH" \
     LDFLAGS="-L/__w/DawDreamer/DawDreamer/alsa-lib/src -L$PYTHONLIBPATH -L/root/faust-2.69.3/lib -L/root/faust-2.69.3/build/lib/" 2>&1 | tee -a $DAWDREAMER_BUILD_LOG
cp /root/DawDreamer/Builds/LinuxMakefile/build/libdawdreamer.so /root/DawDreamer/dawdreamer/dawdreamer.so

# Step 4: Install and Test DawDreamer
echo "Installing and testing DawDreamer..." | tee -a $DAWDREAMER_TEST_LOG
cd /root/DawDreamer
python3 setup.py build 2>&1 | tee -a $DAWDREAMER_TEST_LOG
python3 setup.py install 2>&1 | tee -a $DAWDREAMER_TEST_LOG
python3 -c "import dawdreamer" 2>&1 | tee -a $DAWDREAMER_TEST_LOG || echo "Import failed" | tee -a $DAWDREAMER_TEST_LOG

# Output Logs (Commented out as they are no longer necessary)
# echo "Copying build logs to output directory..."
# cp /root/*.txt /output/
