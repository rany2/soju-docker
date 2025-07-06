FROM alpine:latest AS builder

ARG SOJU_VERSION=master
ARG SOJU_COMMIT=HEAD

RUN apk add --no-cache \
    make \
    git \
    go \
    sqlite \
    sqlite-libs \
    sqlite-dev \
    scdoc

ENV GOFLAGS='-tags=libsqlite3'

WORKDIR /build

RUN git clone https://github.com/emersion/soju.git . && \
    if [ "$SOJU_VERSION" != "master" ]; then \
        git checkout "$SOJU_VERSION"; \
    elif [ "$SOJU_COMMIT" != "HEAD" ]; then \
        git checkout "$SOJU_COMMIT"; \
    fi

RUN make GOFLAGS="$GOFLAGS" RUNDIR="/etc" && \
    make install && \
    mkdir -p /contrib_build

RUN find ./contrib -type f -executable -exec cp {} /contrib_build/ \; && \
    find ./contrib -type f -name "main.go" -exec sh -c 'dir=$(dirname "{}"); go build "$GOFLAGS" -o /contrib_build/$(basename "$dir") "$dir"' \;

FROM alpine:latest

RUN apk add --no-cache \
    sqlite-libs \
    ca-certificates

RUN mkdir -p /etc/soju /var/lib/soju

COPY --from=builder /usr/local/bin/* /usr/local/bin/
COPY --from=builder /usr/local/share/man/man1/* /usr/local/share/man/man1/
COPY --from=builder /contrib_build/* /usr/local/bin/

EXPOSE 6697
VOLUME ["/etc/soju", "/var/lib/soju"]
WORKDIR /etc/soju

CMD ["soju"]
