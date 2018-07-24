FROM crystallang/crystal:0.25.1

ADD . /workspace
WORKDIR /workspace
RUN make build-release
ENTRYPOINT ["./bin/cryogen"]
