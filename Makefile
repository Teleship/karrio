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

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

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

.PHONY: deploy_sandbox_api
deploy_sandbox_api: ## Deploy sandbox API ECS service
	AWS_PROFILE=teleship-sandbox IMAGE_URI=$(SANDBOX_KARRIO_API_IMAGE_URI) ecspresso deploy \
		--config $(SANDBOX_KARRIO_API_ECSPRESSO_CONFIG) \
		--tasks 1 \
		--wait-until stable

.PHONY: deploy_sandbox_worker
deploy_sandbox_worker: ## Deploy sandbox Worker ECS service
	AWS_PROFILE=teleship-sandbox IMAGE_URI=$(SANDBOX_KARRIO_API_IMAGE_URI) ecspresso deploy \
		--config $(SANDBOX_KARRIO_WORKER_ECSPRESSO_CONFIG) \
		--tasks 1 \
		--wait-until stable

.PHONY: deploy_sandbox_dashboard
deploy_sandbox_dashboard: ## Deploy sandbox Dashboard ECS service
	AWS_PROFILE=teleship-sandbox IMAGE_URI=$(SANDBOX_KARRIO_DASHBOARD_IMAGE_URI) ecspresso deploy \
		--config $(SANDBOX_KARRIO_DASHBOARD_ECSPRESSO_CONFIG) \
		--tasks 1 \
		--wait-until stable

.PHONY: deploy_production_api
deploy_production_api: ## Deploy production API ECS service
	AWS_PROFILE=teleship-production IMAGE_URI=$(PRODUCTION_KARRIO_API_IMAGE_URI) ecspresso deploy \
		--config $(PRODUCTION_KARRIO_API_ECSPRESSO_CONFIG) \
		--tasks 1 \
		--wait-until stable

.PHONY: deploy_production_worker
deploy_production_worker: ## Deploy production Worker ECS service
	AWS_PROFILE=teleship-production IMAGE_URI=$(PRODUCTION_KARRIO_API_IMAGE_URI) ecspresso deploy \
		--config $(PRODUCTION_KARRIO_WORKER_ECSPRESSO_CONFIG) \
		--tasks 1 \
		--wait-until stable

.PHONY: deploy_production_dashboard
deploy_production_dashboard: ## Deploy production Dashboard ECS service
	AWS_PROFILE=teleship-production IMAGE_URI=$(PRODUCTION_KARRIO_DASHBOARD_IMAGE_URI) ecspresso deploy \
		--config $(PRODUCTION_KARRIO_DASHBOARD_ECSPRESSO_CONFIG) \
		--tasks 1 \
		--wait-until stable
