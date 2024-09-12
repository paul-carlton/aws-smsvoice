
FROM pcarlton/go-builder:0.0.2 as builder

ARG VERSION

WORKDIR /go/src/github.com/paul-carlton/example-prog
ADD . .
ENV GOPROXY=https://proxy.golang.org,direct
RUN GIT_SSL_NO_VERIFY=True make

FROM alpine:3.8

ENV TAG=$TAG \
  GIT_SHA=$GIT_SHA \
  BUILD_DATE=$BUILD_DATE \
  SRC_REPO=$SRC_REPO

LABEL TAG=$TAG \
  GIT_SHA=$GIT_SHA \
  BUILD_DATE=$BUILD_DATE \
  SRC_REPO=$SRC_REPO

ADD pkg/main/liveness.sh /bin/

COPY --from=builder /go/bin/example-prog /bin/

RUN apk -q add --no-cache --virtual .build-deps upx && \
    addgroup -S example-prog && \
    adduser -S -G example-prog example-prog && \
    upx -qqq /bin/example-prog && \
    apk -q del .build-deps

# Lock down system to example-prog user (no code changes).
USER example-prog

ENTRYPOINT ["example-prog"]
