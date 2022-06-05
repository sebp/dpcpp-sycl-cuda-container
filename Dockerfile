FROM nvidia/cuda:11.5.1-devel-ubuntu20.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ccache \
    cmake \
    cppcheck \
    gdb \
    git \
    libffi-dev \
    ninja-build \
    ocl-icd-libopencl1 \
    pkg-config \
    python3 \
    python3-pip \
    python-is-python3 \
    zstd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/sycl/source
COPY llvm /opt/sycl/source/llvm

# Remove cuda from PATH and LD_LIBRARY_PATH
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LD_LIBRARY_PATH=

# Build DPC++ compiler
ENV CUDA_LIB_PATH=/usr/local/cuda/lib64/stubs
RUN mkdir -p /opt/sycl/source/llvm/build \
    && python3 /opt/sycl/source/llvm/buildbot/configure.py \
      --cuda \
      --cmake-gen "Ninja" \
      --cmake-opt="-DCMAKE_INSTALL_PREFIX=/opt/sycl" \
      --cmake-opt="-DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda" \
      -t release \
      -o /opt/sycl/source/llvm/build \
    && python3 /opt/sycl/source/llvm/buildbot/compile.py -o /opt/sycl/source/llvm/build -j `nproc` \
    && rm -fr /opt/sycl/source/llvm/

ENV PATH=/opt/sycl/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/sycl/lib:$LD_LIBRARY_PATH

# Install fish shell
RUN apt-get update && apt-get install -y --no-install-recommends fish \
	  && rm -rf /var/lib/apt/lists/*

# setup non-root user
# https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_creating-a-nonroot-user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && apt-get update \
    && apt-get install -y sudo \
    && echo ${USERNAME} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && chsh -s $(which fish) ${USERNAME} \
    && rm -rf /var/lib/apt/lists/*

USER vscode
