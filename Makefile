.PHONY: test lint vuln fuzz golden run cli pki build

GO       ?= go
FUZZTIME ?= 60s
FUZZ_TARGETS := \
	./internal/pdf:FuzzParsePDF \
	./internal/pdf:FuzzByteRange \
	./internal/cms:FuzzParseCMS \
	./pkg/verify:FuzzVerify

test:
	$(GO) test -race ./...

lint:
	golangci-lint run

vuln:
	govulncheck ./...

fuzz:
	@for t in $(FUZZ_TARGETS); do \
		pkg=$${t%%:*}; name=$${t##*:}; \
		if ! grep -qs "^func $$name(" $$pkg/*_test.go; then \
			echo "==> $$name ($$pkg): not implemented yet, skipping"; continue; \
		fi; \
		echo "==> $$name ($$pkg)"; \
		$(GO) test $$pkg -run=^$$ -fuzz=^$$name$$ -fuzztime=$(FUZZTIME) || exit 1; \
	done

golden:
	UPDATE=$(UPDATE) $(GO) test ./pkg/verify -run TestGoldenCorpus -v

run:
	$(GO) run ./cmd/server

cli:
	$(GO) run ./cmd/inkproof $(ARGS)

pki:
	$(GO) run ./testdata/pki/gen

build:
	CGO_ENABLED=0 $(GO) build -trimpath -ldflags="-s -w" -o bin/inkproof ./cmd/inkproof
	CGO_ENABLED=0 $(GO) build -trimpath -ldflags="-s -w" -o bin/server ./cmd/server
