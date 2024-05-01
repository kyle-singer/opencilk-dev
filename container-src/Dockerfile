# TODO: This file has some extra packages (copied from a research project)
FROM ubuntu:22.04

# NOTE: Don't use ADD; ADD will decompress the file
#COPY opencilk.tar.gz /usr/local/src/opencilk.tar.gz

# Note that it is possible to specify a sequence of RUN commands, but there
# are various issues with this practice. The first issue is that each separate
# RUN command creates an extra layer of information that is stored with the
# container, which significantly bloats the image. Essentially these layers are
# diffs, so if we extract the opencilk tar in a step separate from removing the
# extracted files then Docker still stores those files in one of the layers, thus
# causing the Docker image to increase in size.

# Step 1: Install build dependencies (TODO: may be possible to install less)
# Step 2: Untar, build, and install OpenCilk
# Step 3: Remove the build files and apt-get cache files
RUN echo "Installing packages..." \
  && apt-get update -qq > /dev/null \
  && apt-get install -qqy --no-install-recommends \
    bazel-bootstrap \
    clang \
    cmake \
    curl \
    git \
    git-lfs \
    libjemalloc-dev \
    libgoogle-perftools-dev \
    libopenmpi-dev \
    libpowercap-dev \
    libpython3-stdlib \
    libpython3-dev \
    libssl-dev \
    lld \
    make \
    python-is-python3 \
    python3 \
    python3-pip \
    sudo \
    zlib1g-dev \
    > /dev/null \
  && python -m pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 python -m pip install -U  \
  && echo "Cleaning temporary files..." \
  && rm -rf /var/lib/apt/lists/* \
  && echo "DOCKER IMAGE BUILT"

# entrypoint is used to update uid/gid and then run the users command
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD /bin/bash

COPY apt-recording-funcs /etc/skel/.apt-recording
