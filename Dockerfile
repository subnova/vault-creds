FROM golang:alpine as build

RUN apk update && \
    apk add make git ca-certificates

ADD . $GOPATH/src/github.com/subnova/vault-creds
RUN cd $GOPATH/src/github.com/subnova/vault-creds && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 make

FROM scratch

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /go/src/github.com/subnova/vault-creds/bin/vaultcreds /vaultcreds

ENTRYPOINT ["/vaultcreds"]
CMD []
