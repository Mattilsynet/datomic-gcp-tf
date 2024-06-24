VERSION = $$(git rev-parse --short=10 HEAD)
IMAGE = europe-north1-docker.pkg.dev/artifacts-352708/mat/datomic:$(VERSION)

build: Dockerfile
	docker buildx build --platform=linux/amd64 -t $(IMAGE) .

push: build
	docker push $(IMAGE)
