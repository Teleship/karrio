SHELL := /bin/bash

GIT_SHA := $(shell git rev-parse --short=8 HEAD)

SANDBOX_ECR_REGISTRY := 329954237540.dkr.ecr.eu-west-2.amazonaws.com
PRODUCTION_ECR_REGISTRY := 817715292426.dkr.ecr.eu-west-2.amazonaws.com

SANDBOX_KARRIO_API_ECR_REPOSITORY_URL ?= $(SANDBOX_ECR_REGISTRY)/teleship/karrio-api
SANDBOX_KARRIO_API_IMAGE_URI ?= $(SANDBOX_KARRIO_API_ECR_REPOSITORY_URL):$(GIT_SHA)
SANDBOX_KARRIO_API_ECSPRESSO_CONFIG := aws/ecspresso/api/ecspresso-sandbox.yml
SANDBOX_KARRIO_WORKER_ECSPRESSO_CONFIG := aws/ecspresso/worker/ecspresso-sandbox.yml

PRODUCTION_KARRIO_API_ECR_REPOSITORY_URL ?= $(PRODUCTION_ECR_REGISTRY)/teleship/karrio-api
PRODUCTION_KARRIO_API_IMAGE_URI ?= $(PRODUCTION_KARRIO_API_ECR_REPOSITORY_URL):$(GIT_SHA)
PRODUCTION_KARRIO_API_ECSPRESSO_CONFIG := aws/ecspresso/api/ecspresso-production.yml
PRODUCTION_KARRIO_WORKER_ECSPRESSO_CONFIG := aws/ecspresso/worker/ecspresso-production.yml

KARRIO_API_REQUIREMENTS ?= source.requirements.txt

SANDBOX_KARRIO_DASHBOARD_ECR_REPOSITORY_URL ?= $(SANDBOX_ECR_REGISTRY)/teleship/karrio-dashboard
SANDBOX_KARRIO_DASHBOARD_IMAGE_URI ?= $(SANDBOX_KARRIO_DASHBOARD_ECR_REPOSITORY_URL):$(GIT_SHA)
SANDBOX_KARRIO_DASHBOARD_ECSPRESSO_CONFIG := aws/ecspresso/dashboard/ecspresso-sandbox.yml

PRODUCTION_KARRIO_DASHBOARD_ECR_REPOSITORY_URL ?= $(PRODUCTION_ECR_REGISTRY)/teleship/karrio-dashboard
PRODUCTION_KARRIO_DASHBOARD_IMAGE_URI ?= $(PRODUCTION_KARRIO_DASHBOARD_ECR_REPOSITORY_URL):$(GIT_SHA)
PRODUCTION_KARRIO_DASHBOARD_ECSPRESSO_CONFIG := aws/ecspresso/dashboard/ecspresso-production.yml

# ECS task CPU uses CPU units (1024 = 1 vCPU); memory uses MiB per task.
SANDBOX_KARRIO_API_TASK_CPU ?= 1024
SANDBOX_KARRIO_API_TASK_MEMORY ?= 2048
PRODUCTION_KARRIO_API_TASK_CPU ?= 1024
PRODUCTION_KARRIO_API_TASK_MEMORY ?= 3072
SANDBOX_KARRIO_WORKER_TASK_CPU ?= 1024
SANDBOX_KARRIO_WORKER_TASK_MEMORY ?= 2048
PRODUCTION_KARRIO_WORKER_TASK_CPU ?= 1024
PRODUCTION_KARRIO_WORKER_TASK_MEMORY ?= 2048
SANDBOX_KARRIO_DASHBOARD_TASK_CPU ?= 256
SANDBOX_KARRIO_DASHBOARD_TASK_MEMORY ?= 512
PRODUCTION_KARRIO_DASHBOARD_TASK_CPU ?= 256
PRODUCTION_KARRIO_DASHBOARD_TASK_MEMORY ?= 512

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'
	@printf '%s\n' 'ECS: make <deploy|render|diff|verify>_<sandbox|production>_<api|worker|dashboard>'

.PHONY: ecr_login_sandbox
ecr_login_sandbox: ## Login to sandbox ECR API registry
	AWS_PROFILE=teleship-sandbox aws ecr get-login-password --region "eu-west-2" | docker login --username AWS --password-stdin $(SANDBOX_ECR_REGISTRY)

.PHONY: ecr_login_production
ecr_login_production: ## Login to production ECR API registry
	AWS_PROFILE=teleship-production aws ecr get-login-password --region "eu-west-2" | docker login --username AWS --password-stdin $(PRODUCTION_ECR_REGISTRY)

.PHONY: build_and_push_sandbox_api
build_and_push_sandbox_api: ecr_login_sandbox ## Build sandbox Karrio API image
	docker build \
		--platform linux/amd64 \
		-f docker/api/Dockerfile \
		--build-arg REQUIREMENTS=$(KARRIO_API_REQUIREMENTS) \
		-t $(SANDBOX_KARRIO_API_IMAGE_URI) \
		.
	docker push $(SANDBOX_KARRIO_API_IMAGE_URI)

.PHONY: build_and_push_production_api
build_and_push_production_api: ecr_login_production ## Build production Karrio API image
	docker build \
		--platform linux/amd64 \
		-f docker/api/Dockerfile \
		--build-arg REQUIREMENTS=$(KARRIO_API_REQUIREMENTS) \
		-t $(PRODUCTION_KARRIO_API_IMAGE_URI) \
		.
	docker push $(PRODUCTION_KARRIO_API_IMAGE_URI)

.PHONY: build_and_push_sandbox_dashboard
build_and_push_sandbox_dashboard: ecr_login_sandbox ## Build sandbox Karrio Dashboard image
	docker build \
		--platform linux/amd64 \
		-f docker/dashboard/Dockerfile \
		-t $(SANDBOX_KARRIO_DASHBOARD_IMAGE_URI) \
		.
	docker push $(SANDBOX_KARRIO_DASHBOARD_IMAGE_URI)

.PHONY: build_and_push_production_dashboard
build_and_push_production_dashboard: ecr_login_production ## Build production Karrio Dashboard image
	docker build \
		--platform linux/amd64 \
		-f docker/dashboard/Dockerfile \
		-t $(PRODUCTION_KARRIO_DASHBOARD_IMAGE_URI) \
		.
	docker push $(PRODUCTION_KARRIO_DASHBOARD_IMAGE_URI)

# Arguments: environment, service, variable prefix, image variable prefix.
# All commands share the same resource, image, profile, and config inputs.
define karrio_ecs_targets
.PHONY: deploy_$(1)_$(2) render_$(1)_$(2) diff_$(1)_$(2) verify_$(1)_$(2)
deploy_$(1)_$(2) render_$(1)_$(2) diff_$(1)_$(2) verify_$(1)_$(2): export TASK_CPU = $$($(3)_TASK_CPU)
deploy_$(1)_$(2) render_$(1)_$(2) diff_$(1)_$(2) verify_$(1)_$(2): export TASK_MEMORY = $$($(3)_TASK_MEMORY)
deploy_$(1)_$(2) render_$(1)_$(2) diff_$(1)_$(2) verify_$(1)_$(2): export IMAGE_URI = $$($(4)_IMAGE_URI)
deploy_$(1)_$(2) render_$(1)_$(2) diff_$(1)_$(2) verify_$(1)_$(2): export AWS_PROFILE = teleship-$(1)
deploy_$(1)_$(2) render_$(1)_$(2) diff_$(1)_$(2) verify_$(1)_$(2): KARRIO_ECSPRESSO_CONFIG = $$($(3)_ECSPRESSO_CONFIG)

deploy_$(1)_$(2):
	ecspresso deploy \
		--config $$(KARRIO_ECSPRESSO_CONFIG) \
		--tasks 1 \
		--wait-until stable

render_$(1)_$(2):
	@ecspresso render taskdef --config $$(KARRIO_ECSPRESSO_CONFIG)

diff_$(1)_$(2):
	ecspresso diff --config $$(KARRIO_ECSPRESSO_CONFIG)

verify_$(1)_$(2):
	ecspresso verify --no-get-secrets --no-put-logs --config $$(KARRIO_ECSPRESSO_CONFIG)
endef

$(eval $(call karrio_ecs_targets,sandbox,api,SANDBOX_KARRIO_API,SANDBOX_KARRIO_API))
$(eval $(call karrio_ecs_targets,sandbox,worker,SANDBOX_KARRIO_WORKER,SANDBOX_KARRIO_API))
$(eval $(call karrio_ecs_targets,sandbox,dashboard,SANDBOX_KARRIO_DASHBOARD,SANDBOX_KARRIO_DASHBOARD))
$(eval $(call karrio_ecs_targets,production,api,PRODUCTION_KARRIO_API,PRODUCTION_KARRIO_API))
$(eval $(call karrio_ecs_targets,production,worker,PRODUCTION_KARRIO_WORKER,PRODUCTION_KARRIO_API))
$(eval $(call karrio_ecs_targets,production,dashboard,PRODUCTION_KARRIO_DASHBOARD,PRODUCTION_KARRIO_DASHBOARD))
