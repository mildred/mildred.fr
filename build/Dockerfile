FROM debian:stable
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y wget curl procps git golang make; \
    apt-get clean;
RUN export GOPATH=/usr/local/gopath; \
    mkdir -p $GOPATH; \
    ln -s /usr/local/bin $GOPATH/bin;
ENV GOPATH /usr/local/gopath
