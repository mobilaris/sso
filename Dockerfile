# =============================================================================
# build stage
#
# install golang dependencies & build binaries
# =============================================================================
FROM golang:1.10 AS build

ENV GOFLAGS='-ldflags="-s -w"'
ENV CGO_ENABLED=0

# use gpm to install dependencies
COPY Godeps gpm /tmp/
RUN cd /tmp && ./gpm install

WORKDIR /go/src/github.com/buzzfeed/sso

COPY cmd ./cmd
COPY internal ./internal
RUN go get -u github.com/derekparker/delve/cmd/dlv
RUN cd cmd/sso-auth && go build -gcflags "all=-N -l" -o /bin/sso-auth
RUN cd cmd/sso-proxy && go build -gcflags "all=-N -l" -o /bin/sso-proxy


# =============================================================================
# final stage
#
# add static assets and copy binaries from build stage
# =============================================================================
FROM debian:stable-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /sso
COPY --from=build /bin/sso-* /bin/
COPY --from=build /go/bin/dlv /dlv

