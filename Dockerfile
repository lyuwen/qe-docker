FROM ubuntu:focal

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      sudo \
      wget \
      make \
      curl \
      gcc gfortran \
      libopenblas-dev \
      libhdf5-openmpi-dev \
      libscalapack-openmpi-dev \
      openmpi-bin \
      libopenmpi-dev \
      libgomp1 \
      libfftw3-dev \
      openssl \
      ca-certificates \
      && \
    apt-get autoremove --purge -y && \
    apt-get autoclean -y && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*

ARG NB_USER=tester
ARG NB_UID=1000
RUN useradd -u $NB_UID -m $NB_USER && \
    echo 'tester ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $NB_USER

WORKDIR /home/$NB_USER

RUN wget --no-check-certificate http://github.com/QEF/q-e/releases/download/qe-7.0/qe-7.0-ReleasePack.tgz && \
    tar zxvf qe-7.0-ReleasePack.tgz && rm -f qe-7.0-ReleasePack.tgz

WORKDIR /home/$NB_USER/qe-7.0

RUN ./configure --enable-openmp --with-scalapack --with-hdf5 --with-hdf5-include=/usr/include/hdf5/openmpi && \
    make pw ph

ENV PATH=/home/$NB_USER/qe-7.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN mkdir /home/$NB_USER/workspace

WORKDIR /home/$NB_USER/workspace

CMD ["bash", "-l"]
