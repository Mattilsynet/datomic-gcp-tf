VERSION = $$(git rev-parse --short=10 HEAD)

build: Dockerfile
	docker buildx build --platform=linux/amd64 -t $(IMAGE):$(VERSION) .

push: build
	docker push $(IMAGE):$(VERSION)
	docker tag $(IMAGE):$(VERSION) $(IMAGE):latest
	docker push $(IMAGE):latest
