# --------------------------------------------------
# Base container
# --------------------------------------------------
FROM docker.io/ubuntu:jammy AS base

RUN set -e

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt install -y clang llvm

# --------------------------------------------------
# Build container
# --------------------------------------------------
FROM base as build

# Install build dependencies
RUN apt install -y cmake ninja-build llvm-dev python3

WORKDIR /dg
COPY . /dg

# libfuzzer does not like the container environment
RUN cmake -S. -GNinja -Bbuild -DCMAKE_INSTALL_PREFIX=/opt/dg \
          -DCMAKE_CXX_COMPILER=clang++ -DENABLE_FUZZING=OFF
RUN cmake --build build --parallel 16

# Install
RUN cmake --build build --target install/strip

# -------------------------------------------------
# Release container
# -------------------------------------------------
FROM base AS release

COPY --from=build /opt/dg /opt/dg
ENV PATH="/opt/dg/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/dg/lib"

COPY example /opt/dg/example

# Verify it works
RUN llvm-slicer --version

WORKDIR /opt/dg/example

# RUN clang -g -O0 -c -emit-llvm -fPIC -fPIE test.c
RUN clang -O0 -c -emit-llvm -fPIC -fPIE test.c

# Create test.ll
RUN llvm-dis test.bc

# Run slicer
RUN llvm-slicer -sc clflush -dump-dg-only test.bc -cutoff-diverging=false -consider-threads=true 2>&1 > /opt/dg/log.txt
