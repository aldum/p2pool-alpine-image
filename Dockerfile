ARG P2POOL_BRANCH=v4.11

FROM alpine:latest as build

RUN apk add --no-cache \
  git build-base cmake \
  libuv-dev libzmq czmq-dev libsodium-dev curl-dev linux-headers \
  ca-certificates

ENV CFLAGS='-fPIC'
ENV CXXFLAGS='-fPIC'
ENV USE_SINGLE_BUILDDIR 1
ENV BOOST_DEBUG         1
ENV GRPC_PYTHON_BUILD_WITH_SYSTEMD 0

WORKDIR /p2pool

ARG P2POOL_BRANCH
RUN git clone --recursive --branch ${P2POOL_BRANCH} \
  --depth=1 --shallow-submodules https://github.com/SChernykh/p2pool .
RUN apk add --no-cache

#ARG NPROC
RUN test -z "$NPROC" && nproc > /nproc || echo -n "$NPROC" > /nproc && \
    mkdir -p build && cd build && \
    cmake .. && make -j"$(cat /nproc)"

FROM alpine:latest

RUN apk add --no-cache \
  libuv-dev libzmq libsodium-dev libcurl

RUN adduser -D -s /bin/sh p2pool
USER p2pool

WORKDIR /home/p2pool
COPY --chown=p2pool:p2pool --from=build /p2pool/build/p2pool /usr/local/bin/p2pool

# Expose p2p and restricted RPC ports
EXPOSE 3333
EXPOSE 37889

ENTRYPOINT ["p2pool"]
CMD ["--host p2pool", \
  "--stratum 0.0.0.0:3333", \
  "--p2p 0.0.0.0:37889", \
]
