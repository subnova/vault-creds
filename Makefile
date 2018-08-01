bin/vault-creds: $(shell find . -name '*.go')
	go build -a -installsuffix cgo -ldflags="-w -s" -o bin/vaultcreds cmd/*.go
