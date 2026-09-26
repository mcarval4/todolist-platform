SHELL := /bin/sh

CLUSTER_NAME ?= todolist-demo
TF_CLUSTER := stacks/local-kind/cluster
TF_PLATFORM := stacks/local-kind/platform

.PHONY: preflight cluster-up platform-up bootstrap destroy fmt validate

preflight:
	sh ./scripts/preflight.sh

cluster-up: preflight
	terraform -chdir=$(TF_CLUSTER) init
	terraform -chdir=$(TF_CLUSTER) apply -auto-approve
	kind export kubeconfig --name $(CLUSTER_NAME)

platform-up: preflight
	helm repo update
	terraform -chdir=$(TF_PLATFORM) init
	terraform -chdir=$(TF_PLATFORM) apply -auto-approve

bootstrap: cluster-up platform-up

destroy:
	terraform -chdir=$(TF_PLATFORM) destroy -auto-approve
	terraform -chdir=$(TF_CLUSTER) destroy -auto-approve

fmt:
	terraform -chdir=$(TF_CLUSTER) fmt -recursive
	terraform -chdir=$(TF_PLATFORM) fmt -recursive

validate:
	terraform -chdir=$(TF_CLUSTER) init -backend=false
	terraform -chdir=$(TF_CLUSTER) validate
	terraform -chdir=$(TF_PLATFORM) init -backend=false
	terraform -chdir=$(TF_PLATFORM) validate
