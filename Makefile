CLUSTER_NAME ?= taskflow
KUBECONFIG_FILE ?= taskflow-kubeconfig

KUBE_VOLUME ?= jenkins-kubeconfig
AGENT_IMAGE ?= jenkins-agent-node2

AGENT1 ?= linux-agent-1
AGENT2 ?= linux-agent-2

# Must match the volume mounted at /home/jenkins/agent in jenkins-docker.
# docker.image(...).inside() needs the agent and daemon to see the same workspace.
AGENT1_WORK_VOLUME ?= jenkins-agent-work

.PHONY: \
	kubeconfig \
	create-kube-volume \
	update-kubeconfig \
	test-kube \
	test-kube-all \
	build-image \
	remove-agent \
	run-agent-1 \
	run-agent-2 \
	new-ver-agent


# ==================================================
# Kubeconfig
# ==================================================

kubeconfig:
	kind get kubeconfig --name $(CLUSTER_NAME) --internal > $(KUBECONFIG_FILE)


create-kube-volume:
	docker volume create $(KUBE_VOLUME)


update-kubeconfig: kubeconfig create-kube-volume
	-docker rm -f kubeconfig-helper

	docker create \
		--name kubeconfig-helper \
		--volume $(KUBE_VOLUME):/kube \
		alpine:latest

	docker cp $(KUBECONFIG_FILE) kubeconfig-helper:/kube/config

	docker rm kubeconfig-helper

	rm -f $(KUBECONFIG_FILE)


# ==================================================
# Test Kubernetes
# ==================================================

test-kube:
	docker exec $(AGENT_NAME) kubectl cluster-info
	docker exec $(AGENT_NAME) kubectl get nodes


test-kube-all:
	$(MAKE) test-kube AGENT_NAME=$(AGENT1)
	$(MAKE) test-kube AGENT_NAME=$(AGENT2)


# ==================================================
# Jenkins Agent Image
# ==================================================

build-image:
	docker build \
		-t $(AGENT_IMAGE) \
		-f dockerfile.agent6 \
		.


# ==================================================
# Remove Agents
# ==================================================

remove-agent:
	-docker rm -f $(AGENT1)
	-docker rm -f $(AGENT2)

run-agent-1:
	docker run \
		--name $(AGENT1) \
		--restart=on-failure \
		--detach \
		--network jenkins \
		--env DOCKER_HOST=tcp://docker:2376 \
		--env DOCKER_CERT_PATH=/certs/client \
		--env DOCKER_TLS_VERIFY=1 \
		--env JENKINS_URL=http://jenkins-blueocean:8080 \
		--env JENKINS_SECRET=$(AGENT1_SECRET) \
		--env JENKINS_AGENT_NAME=$(AGENT1) \
		--volume jenkins-docker-certs:/certs/client:ro \
		--volume $(AGENT1_WORK_VOLUME):/home/jenkins/agent \
		--volume $(KUBE_VOLUME):/home/jenkins/.kube:ro \
		$(AGENT_IMAGE)

run-agent-2:
	docker run \
		--name $(AGENT2) \
		--restart=on-failure \
		--detach \
		--network jenkins \
		--env DOCKER_HOST=tcp://docker:2376 \
		--env DOCKER_CERT_PATH=/certs/client \
		--env DOCKER_TLS_VERIFY=1 \
		--env JENKINS_URL=http://jenkins-blueocean:8080 \
		--env JENKINS_SECRET=$(AGENT2_SECRET) \
		--env JENKINS_AGENT_NAME=$(AGENT2) \
		--volume jenkins-docker-certs:/certs/client:ro \
		--volume jenkins-agent-work-2:/home/jenkins/agent \
		--volume $(KUBE_VOLUME):/home/jenkins/.kube:ro \
		$(AGENT_IMAGE)

# ==================================================
# Recreate Agents
# ==================================================

new-ver-agent: build-image remove-agent run-agent-1 run-agent-2
	-docker network connect kind $(AGENT1)
	-docker network connect kind $(AGENT2)
# 	$(MAKE) test-kube-all

upload-image:
	docker pull --platform linux/amd64 $(TARGET_IMAGE)
	docker image save \
		--platform linux/amd64 \
		-o .kind-image.tar \
		$(TARGET_IMAGE)
	kind load image-archive .kind-image.tar --name $(CLUSTER_NAME)
	rm -f .kind-image.tar
#make upload-image TARGET_IMAGE=ghcr.io/google/osv-scanner TARGET_TAG=latest CLUSTER_NAME=taskflow
#make upload-image TARGET_IMAGE=ghcr.io/google/osv-scanner:latest CLUSTER_NAME=taskflow

# make update-kubeconfig
# set AGENT1_SECRET=
# set AGENT2_SECRET=
# make new-ver-agent
