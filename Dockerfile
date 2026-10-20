FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

ENV INSTALL_BEHAVIORAL_MODEL_SOURCE_VERSION="0bf80968bbd533e5bb58f849743001ae8221b715"
ENV INSTALL_PI_SOURCE_VERSION="04bf8ac8a0c00cd8a663f1f936fdaadc8b7a658c"
ENV INSTALL_P4C_SOURCE_VERSION="3bc092a2119951f86a554adda592a754edfc134e"
ENV INSTALL_PTF_SOURCE_VERSION="95a05315668b4e002166186f387fd2a15549f42f"

RUN apt update
RUN apt install -y sudo

RUN useradd -r -g sudo -m -s /bin/bash p4 \
    && sudo groupadd p4 \
    && echo "p4:p4" | chpasswd \
    && echo "p4 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_p4 \
    && chmod 440 /etc/sudoers.d/99_p4 \
    && mkdir -p /home/p4/src \
    && chown -R p4:p4 /home/p4

WORKDIR /home/p4

RUN apt install -y vim git build-essential \
    ca-certificates iproute2 libpcap-dev \
    tcpdump wget autoconf automake libtool curl cmake unzip \
	pkg-config python3 python3-pip python3-venv \
    xcscope-el libprotobuf-dev protobuf-compiler \
    protobuf-compiler-grpc libgrpc-dev libgrpc++-dev \
    libthrift-dev \
    libssl-dev libreadline-dev valgrind libtool-bin \
    libboost-dev libboost-system-dev libboost-thread-dev \
    libboost-iostreams-dev libboost-graph-dev \
    llvm libelf-dev clang libgflags-dev net-tools

RUN git clone https://github.com/p4lang/PI.git \
    && cd PI \
    && git checkout ${INSTALL_PI_SOURCE_VERSION} \
    && git submodule update --init --recursive \
    && git log -n 1 \
    && ./autogen.sh \
    && ./configure --with-proto --with-bmv2 \
    && make -j$(nproc) \
    && make install