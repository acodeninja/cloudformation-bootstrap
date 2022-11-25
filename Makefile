DEFAULT_GOAL := help
SHELL := bash

ifeq ($(OS),Windows_NT)
    OPERATING_SYSTEM = WIN
    BIN_AWS = aws-vault exec $(PROFILE) -- docker run --rm -it -v $env:userprofile\.aws:/root/.aws -v $pwd:/aws amazon/aws-cli
    BIN_CFN_LINT = docker run --rm -v $pwd:/aws cfn-python-lint:latest
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
    	OPERATING_SYSTEM = LINUX
    endif
    ifeq ($(UNAME_S),Darwin)
    	OPERATING_SYSTEM = MACOS
    endif

    BIN_AWS_REMOTE = docker run --rm -it -v ~/.aws:/root/.aws -v `pwd`:/project --env-file <(aws-vault exec ${PROFILE} -- env) amazon/aws-cli
    BIN_AWS_LOCAL = docker run --rm -it -v ~/.aws:/root/.aws -v `pwd`:/project -e AWS_ACCESS_KEY_ID="test" -e AWS_SECRET_ACCESS_KEY="test" -e AWS_DEFAULT_REGION="us-east-1" amazon/aws-cli --endpoint-url=http://`docker network inspect bridge | jq -rc '.[0].Containers | to_entries[] | .value | select(.Name == "localstack") | .IPv4Address | split("/") | .[0]'`:4566
	BIN_CFN_LINT = docker run --rm -v `pwd`:/project cfn-python-lint:latest
endif

.PHONY: help
help: ## Display this help message
	@echo
	@echo "Usage: make <action> PROFILE=<aws-vault profile>"
	@echo
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo

.PHONY: install
install: .installed/aws .installed/cfn-lint .installed/localstack .installed/aws-vault .installed/jq ## Install deployment and development dependencies

.PHONY: lint
lint: install localstack-start ## Check cloudformation templates for syntax and config errors
	@echo "CFN Lint"
	@$(BIN_CFN_LINT) /project/templates/*
	@for f in templates/*; do echo "AWS Validate Template: $$f"; $(BIN_AWS_LOCAL) cloudformation validate-template --template-body file:///project/$$f; done

deploy-dev: localstack-start ## Deploy to a locally running development environment

.PHONY: clean
clean: ## Return the local project back to it's initial state
	@rm -rf .installed/

.PHONY: localstack-start
localstack-start: ## Start the localstack service for testing aws deployments locally
	@[[ `docker ps | grep localstack | grep '(healthy)' | wc -l` == "1" ]] && docker kill localstack 2> /dev/null && echo "Restarting Localstack" || echo "Starting Localstack"
	@docker run --rm -it -d --name localstack -p 4566:4566 -p 4510-4559:4510-4559 localstack/localstack > /dev/null
	@sleep 5
	@$(BIN_AWS_LOCAL) sts get-caller-identity

.PHONY: localstack-stop
localstack-stop: ## Stop the localstack service if it is running
	@[[ `docker ps | grep localstack | grep '(healthy)' | wc -l` == "1" ]] && docker kill localstack 2> /dev/null && echo "Stopped Localstack" || echo "Localstack was not running"

.installed/aws:
	@echo "Installing AWS CLI"
	@docker pull amazon/aws-cli
	@mkdir -p .installed/
	@echo "INSTALLED" > .installed/aws

.installed/localstack:
	@echo "Installing LocalStack"
	@docker pull localstack/localstack
	@mkdir -p .installed/
	@echo "INSTALLED" > .installed/localstack

.installed/cfn-lint:
	@echo "Installing Cloudformation Lint"
	@mkdir -p .installed/
	@git clone --depth=1 https://github.com/aws-cloudformation/cfn-lint.git .installed/cfn-lint
	@cd .installed/cfn-lint && docker build --tag cfn-python-lint:latest .
	@rm -rf .installed/cfn-lint
	@echo "INSTALLED" > .installed/cfn-lint

.installed/aws-vault:
	@mkdir -p .installed/
ifeq ($(OPERATING_SYSTEM), MACOS)
	@brew install --cask aws-vault
endif
ifeq ($(OPERATING_SYSTEM), WIN)
	@choco install aws-vault
endif
ifeq ($(OPERATING_SYSTEM), LINUX)
	@aws-vault --version || exit 1 && echo "AWS Vault is not installed. See https://github.com/99designs/aws-vault for installation and setup instructions"
endif
	@echo "INSTALLED" > .installed/aws-vault

.installed/jq:
	@mkdir -p .installed/
ifeq ($(OPERATING_SYSTEM), MACOS)
	@brew install jq
endif
ifeq ($(OPERATING_SYSTEM), WIN)
	@choco install jq
endif
ifeq ($(OPERATING_SYSTEM), LINUX)
	@jq --version || exit 1 && echo "JQ is not installed"
endif
	@echo "INSTALLED" > .installed/jq

