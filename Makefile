CLUSTER_NAME ?= taskflow
KUBECONFIG_FILE ?= taskflow-kubeconfig

KUBE_VOLUME ?= jenkins-kubeconfig
AGENT_IMAGE ?= jenkins-agent-node2

AGENT1 ?= linux-agent-1
AGENT2 ?= linux-agent-2

CI_AGENT_VERSION ?= 1.0.0
FLUTTER_AGENT_VERSION ?= 1.0.0

CI_AGENT_IMAGE ?= jenkins-ci-agent:$(CI_AGENT_VERSION)
FLUTTER_AGENT_IMAGE ?= jenkins-flutter-ci:$(FLUTTER_AGENT_VERSION)
# Must match the volume mounted at /home/jenkins/agent in jenkins-docker.
# docker.image(...).inside() needs the agent and daemon to see the same workspace.
AGENT1_WORK_VOLUME ?= jenkins-agent-work
include ci/tool-versions.env
include ci/image-versions.env
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
	new-ver-agent \
	kind-agent \
	build-images \
	build-agent \
	build-flutter


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
build-agent:
	docker build \
		-t $(CI_AGENT_IMAGE) \
		-f ci/Dockerfiles/dockerfile.agent \
		--build-arg JENKINS_BASE_IMAGE=$(JENKINS_BASE_IMAGE) \
		--build-arg JENKINS_BASE_DIGEST=$(JENKINS_BASE_DIGEST) \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg NODE_SHA256=$(NODE_SHA256) \
		--build-arg YQ_VERSION=$(YQ_VERSION) \
		--build-arg YQ_SHA256=$(YQ_SHA256) \
		--build-arg DOCKER_COMPOSE_VERSION=$(DOCKER_COMPOSE_VERSION) \
		--build-arg DOCKER_COMPOSE_SHA256=$(DOCKER_COMPOSE_SHA256) \
		--build-arg BUILDX_VERSION=$(BUILDX_VERSION) \
		--build-arg BUILDX_SHA256=$(BUILDX_SHA256) \
		--build-arg HELM_VERSION=$(HELM_VERSION) \
		--build-arg HELM_SHA256=$(HELM_SHA256) \
		--build-arg COSIGN_VERSION=$(COSIGN_VERSION) \
		--build-arg COSIGN_SHA256=$(COSIGN_SHA256) \
		--build-arg TRIVY_VERSION=$(TRIVY_VERSION) \
		--build-arg TRIVY_SHA256=$(TRIVY_SHA256) \
		--build-arg SYFT_VERSION=$(SYFT_VERSION) \
		--build-arg SYFT_SHA256=$(SYFT_SHA256) \
		--build-arg OPA_VERSION=$(OPA_VERSION) \
		--build-arg OPA_SHA256=$(OPA_SHA256) \
		--build-arg GITLEAKS_VERSION=$(GITLEAKS_VERSION) \
		--build-arg GITLEAKS_SHA256=$(GITLEAKS_SHA256) \
		--build-arg OSV_SCANNER_VERSION=$(OSV_SCANNER_VERSION) \
		--build-arg OSV_SCANNER_SHA256=$(OSV_SCANNER_SHA256) \
		--build-arg SEMGREP_VERSION=$(SEMGREP_VERSION) \
		--build-arg SONAR_SCANNER_VERSION=$(SONAR_SCANNER_VERSION) \
		--build-arg SONAR_SCANNER_SHA256=$(SONAR_SCANNER_SHA256) \
		.


# =========================================================
# Build Flutter agent
# =========================================================

build-flutter:
	docker build \
		-f ci/Dockerfiles/dockerfile.flutter \
		-t $(FLUTTER_AGENT_IMAGE) \
		--build-arg FLUTTER_BASE_IMAGE=$(FLUTTER_BASE_IMAGE) \
		--build-arg FLUTTER_BASE_DIGEST=$(FLUTTER_BASE_DIGEST) \
		.


# =========================================================
# Load images into kind
# =========================================================

load-agent: build-agent
	kind load docker-image \
		$(CI_AGENT_IMAGE) \
		--name $(CLUSTER_NAME)


load-flutter: build-flutter
	kind load docker-image \
		$(FLUTTER_AGENT_IMAGE) \
		--name $(CLUSTER_NAME)


# =========================================================
# Individual image workflows
# =========================================================

agent-ci-image: load-agent

flutter-ci-image: load-flutter


# =========================================================
# Build + load both agents
# =========================================================

kind-agent: agent-ci-image flutter-ci-image
# make -j2 kind-agent
get-checksums:
	bash ci/scripts/get-tool-checksums.sh
	bash ci/scripts/get-image-digests.sh

where-cluster:
	kind get clusters
	kubectl config current-context
	kubectl cluster-info
	kubectl get ns

# kubectl config use-context kind-taskflow
# kubectl get pvc -n jenkins-agents
# kubectl get storageclass