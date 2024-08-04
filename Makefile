.PHONY: setup build test

CI_COMMIT_TAG ?= $(shell git describe --tags --abbrev=0)
CI_COMMIT_SHORT_SHA ?= $(shell git rev-parse --short HEAD)
OPTS := -ldflags="-X main.Commit=$(CI_COMMIT_SHORT_SHA) -X main.Tag=$(CI_COMMIT_TAG)" -tags=jsoniter

all: build

setup:
	@go install go.uber.org/mock/mockgen@v0.4.0
	@go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.26
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1
	@go install honnef.co/go/tools/cmd/staticcheck@v0.4.7
	@go install github.com/air-verse/air@v1.52.3
	@go install github.com/joho/godotenv/cmd/godotenv@v1.4.0
	@go install golang.org/x/vuln/cmd/govulncheck@latest

watch:
	air -build.pre_cmd="make migrate" -build.args_bin "$(OPTS)" .

build:
	@go build $(OPTS)

genmock:
	@bash generate_mocks.sh

genproto:
	@protoc --go_out=. --go_opt=paths=source_relative \
		--go-grpc_out=. --go-grpc_opt=paths=source_relative \
		proto/proto.proto

generate:
	@go generate ./...

test: test-setup testunit testintegration

test-setup:
	@go clean -testcache
	@[ ! -e ".env.testing" ] && cp .env.default .env.testing

testintegration:
	@godotenv -f .env.testing go test -cover -tags="integration" -p 1 ./...

testunit:
	@godotenv -f .env.testing go test -cover -tags="unit" ./...

lint:
	@staticcheck ./...

vuln:
	@govulncheck .

migrate:
	@godotenv -f .env go run ./migrate
