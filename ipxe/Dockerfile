FROM --platform=amd64 alpine:3.18.4

RUN apk add git make gcc perl libc-dev xz-dev

WORKDIR /src

ADD ./build.sh /src/build.sh

RUN git clone https://github.com/ipxe/ipxe.git && \
    chmod +x /src/build.sh

ENTRYPOINT [ "/src/build.sh" ]

