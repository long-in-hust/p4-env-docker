IMAGE := p4env-docker:v0.1
CONTAINER := p4-research-env
WORKDIR := /home/p4/longdev

build:
	docker build --network=host -t $(IMAGE) .

run:
	docker run \
	--name $(CONTAINER) --user p4 \
	-e DISPLAY=host.docker.internal:0 -v /tmp/.X11-unix:/tmp/.X11-unix \
	-v `pwd`/longdev:$(WORKDIR) -w $(WORKDIR) \
	--privileged --network=host \
	-it --rm $(IMAGE) bash

join:
	docker exec -it $(CONTAINER) bash

stop:
	docker stop $(CONTAINER) || true

delcont:
	docker rm -f $(CONTAINER) || true

delimg:
	docker rmi -f $(IMAGE) || true
