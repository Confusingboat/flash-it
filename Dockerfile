FROM ubuntu:18.04

COPY . /tmp/flash-it/
RUN add-apt-repository universe multiverse && \
    apt update && \
    apt install git-core build-essential python3 pciutils p7zip-full sysfsutils unzip -y
    
CMD tail -f /dev/null
