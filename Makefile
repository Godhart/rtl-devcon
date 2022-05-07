_E ?= default.env

include $(_E)
export $(shell sed 's/=.*//' $(_E))

.PHONY: show-env
show-env:
	env

all: docker-oss docker-network

.PHONY: clean-all
clean-all: clean-network
	docker rmi $(docker images --filter=reference="hdl-code-questa-*:*" -q) || echo "" && \
	docker image rm hdl-code-oss		|| echo "" && \
	docker image rm hdl-code-base		|| echo ""

.PHONY: clean-network
clean-network:
	docker network rm $(NETNAME)		|| echo ""

.PHONY: docker-network
docker-network:
	docker network create -d macvlan \
		--subnet=192.168.1.0/30 --gateway=192.168.1.1 \
		--ip-range 192.168.1.0/30 \
		$(NETNAME)						|| echo ""

.PHONY: docker-base
docker-base:
	docker build -t hdl-code-base:latest -f Dockerfile.base .

.PHONY: docker-oss
docker-oss: docker-base
	docker build -t hdl-code-oss:latest -f Dockerfile.oss .

.PHONY: docker-questa
docker-questa: docker-base
	docker build -t hdl-code-questa-${QVER}:latest -f Dockerfile.questa ${QBLOB}-${QVER}

.PHONY: X11
X11:
	touch $(XAUTH)
	xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $(XAUTH) nmerge -

DOCKER_RUN = docker run --rm -it \
		$(NETWORK) $(NETNAME) \
		--env="DISPLAY=${DISPLAY}" \
		--env="XAUTHORITY=$(XAUTH)" \
		--volume="$(XSOCK):$(XSOCK)" \
		--volume="$(XAUTH):$(XAUTH)" \
		--volume="${CODE_HOME}:/home/code" \
		--volume="${CODE_PROJECT}:/data/project" \
		-u `id -u ${USER}`:`id -g ${USER}` \

DOCKER_MAKE = docker run --rm -it \
		$(NETWORK) $(NETNAME) \
		--env="DISPLAY=${DISPLAY}" \
		--env="XAUTHORITY=$(XAUTH)" \
		--volume="$(XSOCK):$(XSOCK)" \
		--volume="$(XAUTH):$(XAUTH)" \
		--volume="${CODE_PROJECT}:/data/project" \
		--workdir="/data/project" \
		-u `id -u ${USER}`:`id -g ${USER}` \

.PHONY: run
run: X11
		$(DOCKER_RUN) \
		hdl-code-${IMG}:latest \
		${RUN}

.PHONY: make
make: X11
		$(DOCKER_MAKE) \
		hdl-code-${IMG}:latest \
		make ${TARGET}
