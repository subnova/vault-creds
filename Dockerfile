FROM golang:alpine as build

RUN apk update && \
    apk add make git ca-certificates

ADD . /go/src/github.com/subnova/vault-creds
RUN cd /go/src/github.com/subnova/vault-creds && make

FROM scratch

COPY --from=build /go/src/github.com/subnova/vault-creds/bin/vaultcreds /vaultcreds

ENTRYPOINT ["/vaultcreds"]
CMD []
