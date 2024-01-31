# --------------------------------------------------
# Base container
# --------------------------------------------------
FROM docker.io/ubuntu:jammy AS base

RUN set -e

# Install packages
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -yq --no-install-recommends clang llvm
RUN apt install -yq pstack

# --------------------------------------------------
# Build container
# --------------------------------------------------
FROM base as build

# Can be used to specify which git ref to checkout
ARG GIT_REF=master
ARG GIT_REPO=mchalupa/dg

# Install build dependencies
RUN apt-get install -yq --no-install-recommends cmake \
                                                ninja-build llvm-dev python3

# Clone
# RUN git clone https://github.com/$GIT_REPO
WORKDIR /dg
# RUN git fetch origin $GIT_REF:build
# RUN git checkout build

COPY . /dg

# libfuzzer does not like the container environment
RUN cmake -S. -GNinja -Bbuild -DCMAKE_INSTALL_PREFIX=/opt/dg \
          -DCMAKE_CXX_COMPILER=clang++ -DENABLE_FUZZING=OFF
RUN cmake --build build --parallel 16

# RUN apt-get install -yq make
# RUN cmake . -DCMAKE_INSTALL_PREFIX=/opt/dg -DCMAKE_CXX_COMPILER=clang++ -DENABLE_FUZZING=OFF
# RUN make -j4
# RUN cmake --build build --target check

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
# COPY . /opt/dg

# RUN ls /opt/dg

# # Verify it works
RUN llvm-slicer --version

WORKDIR /opt/dg/example

# RUN clang -g -O0 -c -emit-llvm -fPIC -fPIE test.c
RUN clang -O0 -c -emit-llvm -fPIC -fPIE test.c

RUN llvm-dis test.bc


RUN llvm-slicer -sc clflush -dump-dg-only test.bc -cutoff-diverging=false -consider-threads=true 2>&1 > /opt/dg/log.txt

