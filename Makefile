define find.functions
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[31m%20s\033[0m\t%s\n", $$1, $$2}'
endef

gitsha := $(shell git rev-parse HEAD | cut -c 1-7)

.PHONY: help
help:  ## help
	@echo 'The following commands can be used.'
	@echo ''
	$(call find.functions)

.PHONY: prj-init
prj-init: ## project initialisation
	poetry install
	poetry run pre-commit install
	poetry run pre-commit run --all check-added-large-files
	poetry run pre-commit run --all check-merge-conflict
	poetry run pre-commit run --all check-yaml
	poetry run pre-commit run --all detect-private-key
	poetry run pre-commit run --all end-of-file-fixer
	poetry run pre-commit run --all trailing-whitespace
	poetry run pre-commit run --all isort
	poetry run pre-commit run --all black
	poetry run pre-commit run --all flake8
	poetry run pytest

.PHONY: test
test:  ## run pytest
	pytest . -p no:logging -p no:warnings

.PHONY: lint
lint:  ## run linting
	isort image_sorting
	black image_sorting
	flake8 image_sorting

.PHONY: clear-cache
clear-cache: ## clear python cache
	find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete

.PHONY: pre-commit
pre-commit: .git/hooks/pre-commit  ## Run all pre-commit checks
	pre-commit run --all

.PHONY: requirements
requirements: ## create requirements.txt with dev dependencies
	poetry export --without-hashes --format=requirements.txt --without dev > requirements.txt
	