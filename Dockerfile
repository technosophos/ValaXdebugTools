FROM ubuntu:bionic

ENV VALA_VERSION 0.56.7

RUN apt-get update && apt-get install -y curl xz-utils gcc file flex bison libglib2.0-dev libgraphviz-dev unzip libgee-0.8

RUN export VALA_MINOR_VERSION=$(echo $VALA_VERSION | sed -E 's/^([0-9]+)\.([0-9]+)\.([0-9]+)$/\1.\2/') && \
    curl -fsSLO "https://download.gnome.org/sources/vala/$VALA_MINOR_VERSION/vala-$VALA_VERSION.tar.xz"

RUN unxz "vala-$VALA_VERSION.tar.xz" \
    && tar xvf "vala-$VALA_VERSION.tar" \
    && cd "vala-$VALA_VERSION/" \
    && ./configure --prefix=/usr \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && cd .. \
    && rm -r "vala-$VALA_VERSION" "vala-$VALA_VERSION.tar"

COPY src /tmp/src

RUN cd /tmp && \
    valac --pkg gio-2.0 --pkg gee-0.8 src/*.vala -o /usr/local/bin/trace_analyzer && \
    cd .. && \
    rm -r /tmp/src


