#!/bin/bash

arma_version=$1
boost_version=$2
llvm_version=$3

cat > Dockerfile <<EOF
# Using debian:stretch image as base-image plus mlpack prereqs.
FROM mlpack-docker-base:latest

# Installing clang from source.
WORKDIR /
RUN wget http://masterblaster.mlpack.org:5005/$llvm_version.tar.xz && \
    tar xvf $llvm_version.tar.xz && \
    rm -f $llvm_version.tar.xz && \
    cd $llvm_version && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr ../ && \
    make -j32 && \
    make install && \
    apt-get purge -y gcc && \
    cd ../../ && \
    rm -rf $llvm_version

# Installing armadillo via source-code.
WORKDIR /
RUN wget --no-check-certificate \
      "http://masterblaster.mlpack.org:5005/$arma_version.tar.gz" && \
    tar xvzf $arma_version.tar.gz && \
    rm -f $arma_version.tar.gz && \
    cd $arma_version && \
    cmake -DINSTALL_LIB_DIR=/usr/lib/ . && \
    make -j32 && \
    make install && \
    cd .. && \
    rm -rf $arma_version


# Installing boost from source.
WORKDIR /
RUN wget \
      http://masterblaster.mlpack.org:5005/$boost_version.tar.gz && \
    tar xvzf $boost_version.tar.gz && \
    rm -f $boost_version.tar.gz && \
    cd $boost_version && \
    ./bootstrap.sh --with-toolset=clang --prefix=/usr/ \
        --with-libraries=math,program_options,serialization,test && \
    ./bjam install -j32 && \
    rm -f $boost_version/
EOF

cat >> Dockerfile << 'EOF'
# Creating a non-root user.
RUN adduser --system --disabled-password --disabled-login \
   --shell /bin/sh mlpack

# Hardening the containers by unsetting all SUID tags.
RUN for i in `find / -perm 6000 -type f`; do chmod a-s $i; done

# Changing work directory and user to mlpack.
WORKDIR /home/mlpack
USER mlpack
EOF
