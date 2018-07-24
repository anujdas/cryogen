FROM alpine:3.8
MAINTAINER Anuj Das "anujdas@gmail.com"

ENV EDITOR=nano
RUN apk add --no-cache $EDITOR

COPY bin/cryogen /cryogen
ENTRYPOINT ["/cryogen"]
