# FROM ubuntu:focal
FROM intel/oneapi-hpckit:devel-ubuntu22.04 AS builder

WORKDIR /tmp

# Build HDF5 with intel
RUN wget --no-check-certificate https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_12_2.tar.gz && \
    tar zxvf hdf5-1_12_2.tar.gz && rm -f hdf5-1_12_2.tar.gz && \
    cd hdf5-hdf5-1_12_2 && \
    ./configure --prefix=/opt/apps/hdf5/intel-1.12.2 --enable-fortran --enable-static --enable-parallel \
    --with-pic CC=mpiicc FC=mpiifort CXX=mpiicpc CFLAGS="-fPIC -O3 -xHost -ip -fno-alias -align" \
    FFLAGS="-fPIC -O3 -xHost -ip -fno-alias -align -I/opt/intel/oneapi/mpi/latest/include -L/opt/intel/oneapi/mpi/latest/lib" \
    CXXFLAGS="-fPIC -O3 -xHost -ip -fno-alias -align" && \
    make && make install

WORKDIR /opt

RUN wget --no-check-certificate http://github.com/QEF/q-e/releases/download/qe-7.0/qe-7.0-ReleasePack.tgz && \
    tar zxvf qe-7.0-ReleasePack.tgz && rm -f qe-7.0-ReleasePack.tgz

WORKDIR /opt/qe-7.0

RUN ./configure --with-scalapack=intel --with-hdf5=/opt/apps/hdf5/intel-1.12.2 \
    FCFLAGS="-I${MKLROOT}/include/intel64/lp64 -i8  -I${MKLROOT}/include" \
    LAPACK_LIBS=${MKLROOT}/lib/intel64/libmkl_lapack95_lp64.a SCALAPACK_LIBS=${MKLROOT}/lib/intel64/libmkl_scalapack_lp64.a \
    BLAS_LIBS="-Wl,--start-group ${MKLROOT}/lib/intel64/libmkl_cdft_core.a ${MKLROOT}/lib/intel64/libmkl_intel_lp64.a ${MKLROOT}/lib/intel64/libmkl_sequential.a ${MKLROOT}/lib/intel64/libmkl_core.a ${MKLROOT}/lib/intel64/libmkl_blacs_intelmpi_lp64.a -Wl,--end-group -lpthread -lm -ldl" &&\
    make pw ph


# FROM fulvwen/intel-mpi-runtime:main
FROM ghcr.io/lyuwen/intel-mpi-runtime:main

ARG NB_USER=tester
ARG NB_UID=1000
RUN useradd -u $NB_UID -m $NB_USER && \
    echo 'tester ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

COPY --from=builder /opt/qe-7.0 /opt/qe-7.0

ENV PATH=/opt/qe-7.0/bin:$PATH

USER $NB_USER

RUN mkdir /home/$NB_USER/workspace

WORKDIR /home/$NB_USER/workspace

CMD ["bash", "-l"]
