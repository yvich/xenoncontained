FROM debian:buster-slim

ENV XENON_BCORE=j4
ENV DEBIAN_FRONTEND noninteractive

# Install dependencies and tools
RUN apt-get update && \
    apt-get install -y \
        gcc \
        make \
        git \
        build-essential \
        wget \
        lsb-release \
        libgmp3-dev \
        libmpfr-dev \
        libmpc-dev \
        git-core \
        gettext \
        ncurses-dev \
        fish \
        vim \
        sudo \
        flex \
        bison \
        gcc-multilib \
        tzdata

# Set the system time zone and remove unnecessary packages
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata                  
RUN apt-get autoremove

# Clone the libxenon repository and change to the toolchain directory
RUN git clone https://github.com/unluckybudget/libxenon /tmp/libxenon
WORKDIR /tmp/libxenon/toolchain

# Build and install the Xenon toolchain
RUN ./build-xenon-toolchain toolchain - set PARALLEL=${XENON_BCORE}

# Set the DEVKITXENON and PATH environment variables
ENV DEVKITXENON /usr/local/xenon
ENV PATH $DEVKITXENON/bin:$DEVKITXENON/usr/bin:$PATH

# Build and install the libxenon library and other libraries
RUN ./build-xenon-toolchain libxenon - set PARALLEL=${XENON_BCORE}
RUN ./build-xenon-toolchain libs - set PARALLEL=${XENON_BCORE}

# Create the libxenon user and set its password
RUN adduser --home /mnt/share libxenon --shell /bin/bash && \
    printf "xenon\nxenon" | passwd libxenon

# Copy the libxenon.sh and disable.history.sh scripts to the container
COPY libxenon.sh /etc/profile.d/libxenon.sh
COPY disable.history.sh /etc/profile.d/disable.history.sh

# Set the default working directory and switch to the libxenon user
WORKDIR /mnt/share
USER libxenon

# Set the default command
ENTRYPOINT ["/bin/bash"]
