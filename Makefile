.DEFAULT_GOAL := help

inventory ?= environments/hosts
provider-state-backend-dir = providers/azure-state-backend/$(env)
tags ?= all
user ?= $(shell whoami)

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	docker_ssh_opts =  -e SSH_AUTH_SOCK=$(SSH_AUTH_SOCK) \
	-v $(SSH_AUTH_SOCK):$(SSH_AUTH_SOCK)
endif
ifeq ($(UNAME_S),Darwin)
	docker_ssh_opts = -v $(HOME)/.ssh:/root/.ssh:ro
endif

base-docker-run = docker run \
	--rm \
	-e ARM_CLIENT_ID=$(AZURE_CLIENT_ID) \
	-e ARM_CLIENT_SECRET=$(AZURE_CLIENT_SECRET) \
	-e ARM_SUBSCRIPTION_ID=$(AZURE_SUBSCRIPTION_ID) \
	-e ARM_TENANT_ID=$(AZURE_TENANT_ID) \
	-e AZURE_CLIENT_ID=$(AZURE_CLIENT_ID) \
	-e AZURE_CLIENT_SECRET=$(AZURE_CLIENT_SECRET) \
	-e AZURE_SECRET=$(AZURE_CLIENT_SECRET) \
	-e AZURE_SERVICE_PRINCIPAL=$(AZURE_SERVICE_PRINCIPAL) \
	-e AZURE_SUBSCRIPTION_ID=$(AZURE_SUBSCRIPTION_ID) \
	-e AZURE_TENANT=$(AZURE_TENANT_ID) \
	-e AZURE_TENANT_ID=$(AZURE_TENANT_ID) \
	-v $(shell pwd):/docker-env \
	$(docker_ssh_opts) \

ansible-docker-run = $(base-docker-run) \
	-w  /docker-env/ansible \
	-it docker-env

terraform-docker-run = $(base-docker-run) \
	-v $(HOME)/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub:ro \
	-w  /docker-env/terraform/ \
	-it docker-env

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Variable '$*' not set"; \
		exit 1; \
	fi

.PHONY: ansible-playbook
ansible-playbook: ## Execute Ansible playbooks
	$(ansible-docker-run) \
		ansible-playbook $(playbook).yml \
			-c ssh \
			-e 'env=$(env)' \
			-i $(inventory) \
			-t $(tags) \
			-u $(user) \
			$(ansible-args)
			-vvv

.PHONY: ansible-edit-vault
ansible-edit-vault: guard-vault ## Edit Ansible vault file
	$(ansible-docker-run) \
		ansible-vault edit ../$(vault)

.PHONY: bash
bash: ## Run arbitrary commands inside the container
	$(base-docker-run) -it docker-env /bin/bash

.PHONY: clean
clean: ## Clean runtime files, configurations and docker image
	find . -name ".terraform" -exec rm -rf {} +
	docker rmi docker-env

.PHONY: help
help: ## Show help
	@IFS=$$'\n' ; \
		help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
		printf "%-30s %s\n" Target "Help message" ; \
		printf "%-30s %s\n" ------ ------------ ; \
		for help_line in $${help_lines[@]}; do \
			IFS=$$'#' ; \
			help_split=($$help_line) ; \
			help_command=`echo $${help_split[0]} | echo $${help_split[0]} | cut -d: -f1` ; \
			help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
			printf "%-30s %s\n" $$help_command $$help_info ; \
		done

.PHONY: terraform-apply
terraform-apply: ## Apply Terraform providers
	$(terraform-docker-run) \
		terraform apply \
			-auto-approve=false \
			-parallelism=100 \
			$(terraform-args) \
			.

.PHONY: terraform-destroy
terraform-destroy: ## Destroy Terraform providers
	$(terraform-docker-run) \
		terraform destroy \
		-parallelism=100 \
		$(terraform-args) \
		.

.PHONY: terraform-init
terraform-init:  ## Initialize Terraform providers
	$(terraform-docker-run) \
		terraform init \
			.

.PHONY: setup
setup: ## Setup development environment
	@echo "Copying git hooks"
	cp -v githooks/pre-commit .git/hooks/pre-commit && \
	chmod +x .git/hooks/pre-commit
	@echo "Updating submodules"
	git submodule update --init --recursive
	@echo "Building docker image"
	docker build . -t docker-env
	@echo "Done!"
