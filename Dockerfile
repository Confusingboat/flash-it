FROM ubuntu:18.04
ARG DEBIAN_FRONTEND noninteractive
COPY . /tmp/flash-it/
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    rm -rf /var/lib/apt/lists/* && \
    add-apt-repository universe multiverse && \
    apt update && \
    apt install git-core build-essential python3 pciutils p7zip-full sysfsutils unzip -y
ENV DEBIAN_FRONTEND teletype
CMD tail -f /dev/null
