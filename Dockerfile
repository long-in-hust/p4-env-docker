FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

ENV INSTALL_BEHAVIORAL_MODEL_SOURCE_VERSION="4d5ac3b4d25b7a60b31d1808132cb89a7837d0cc"
ENV INSTALL_PI_SOURCE_VERSION="04bf8ac8a0c00cd8a663f1f936fdaadc8b7a658c"
ENV INSTALL_P4C_SOURCE_VERSION="fa467df37c1d42e6928340468875536a20ec3d66"
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

WORKDIR /home/p4/src

RUN apt install -y vim git gh build-essential libgmp-dev \
    ca-certificates iproute2 libpcap-dev libjsoncpp-dev \
    tcpdump wget autoconf automake libtool curl cmake unzip \
	pkg-config python3 python3-pip python3-venv libnanomsg-dev \
    xcscope-el libprotobuf-dev protobuf-compiler \
    protobuf-compiler-grpc libgrpc-dev libgrpc++-dev \
    libthrift-dev libboost-program-options-dev libboost-test-dev libevent-dev \
    libssl-dev libreadline-dev valgrind libtool-bin \
    libboost-dev libboost-system-dev libboost-thread-dev \
    libboost-iostreams-dev libboost-graph-dev libboost-filesystem-dev \
    llvm libelf-dev clang libgflags-dev net-tools flex bison libxxhash-dev

RUN git clone https://github.com/p4lang/PI.git

RUN cd PI \
    && git checkout ${INSTALL_PI_SOURCE_VERSION} \
    && git submodule update --init --recursive

RUN cd PI \
    && git log -n 1 \
    && ./autogen.sh \
    && ./configure --with-proto --without-internal-rpc --without-cli --without-bmv2 \
    && make -j$(nproc) \
    && make install

RUN git clone https://github.com/nanomsg/nanomsg.git

RUN cd nanomsg \
    && git checkout 1.2.2 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install

RUN git clone https://github.com/apache/thrift.git

RUN cd thrift \
    && git checkout 0.13.0 \
    && ./bootstrap.sh \
    && ./configure --without-java --without-erlang --without-php --without-ruby --without-haskell --without-go --without-d \
    && make -j$(nproc) \
    && make install

RUN git clone https://github.com/long-in-hust/behavioral-model.git

RUN cd behavioral-model \
    && git checkout ${INSTALL_BEHAVIORAL_MODEL_SOURCE_VERSION} \
    && git log -n 1 \
    && ./autogen.sh \
    && ./configure \
    && cmake -S . -B build -DWITH_PI=ON -DENABLE_PACKET_TRACE=ON -DENABLE_LOGGING_MACROS=OFF -DENABLE_ELOGGER=OFF \
    && cmake --build build --parallel $(nproc) \
    && cmake --install build

RUN git clone https://github.com/p4lang/p4c

RUN cd p4c \
    && git checkout ${INSTALL_P4C_SOURCE_VERSION} \
    && git log -n 1 \
    && mkdir build \
    && cmake -B build \
    && cmake --build build --target install --parallel $(nproc)

USER p4
WORKDIR /home/p4/
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
