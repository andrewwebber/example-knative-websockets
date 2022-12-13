export COMMIT_HASH := $(shell git rev-parse --short=8 HEAD)
export PKG_CONFIG_ALLOW_CROSS=1
export NAMESPACE := "default"
export PROJECT_NAME := example-websockets
export REGISTRY := docker.io/andrewvwebber

all: deploy

audit:
	mkdir -p ./target/audit || true
	cargo audit --ignore RUSTSEC-2020-0159 --ignore RUSTSEC-2020-0071
	cargo audit --ignore RUSTSEC-2020-0159 --ignore RUSTSEC-2020-0071 -c never | tee ./target/audit/static_analysis_log

build: audit
	cargo clippy --tests -- -Dwarnings

release:
	cargo build --release --target=x86_64-unknown-linux-musl

run:
	cargo run

docker-image:
	docker build --network=host --no-cache -t ${REGISTRY}/example-websockets:${COMMIT_HASH} .
	trivy image --exit-code 1 --severity HIGH,CRITICAL ${REGISTRY}/example-websockets:${COMMIT_HASH}

docker-push: docker-image
	docker push ${REGISTRY}/example-websockets:${COMMIT_HASH}


deploy:
	helm upgrade --install websockets -f ./chart/values.yaml ./chart
