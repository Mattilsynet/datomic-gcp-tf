VERSION = $$(git rev-parse --short=10 HEAD)
IMAGE = europe-north1-docker.pkg.dev/artifacts-352708/mat/datomic

build: Dockerfile
	docker buildx build --platform=linux/amd64 -t $(IMAGE):$(VERSION) .

push: build
	docker push $(IMAGE):$(VERSION)
	docker tag $(IMAGE):$(VERSION) $(IMAGE):latest
	docker push $(IMAGE):latest
