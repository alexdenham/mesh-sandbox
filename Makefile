SHELL:=/bin/bash -O globstar
.SHELLFLAGS = -ec
.PHONY: build dist
.DEFAULT_GOAL := list
# this is just to try and supress errors caused by poetry run
export PYTHONWARNINGS=ignore:::setuptools.command.install

list:
	@grep '^[^#[:space:]].*:' Makefile

guard-%:
	@ if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi


########################################################################################################################
##
## Makefile for this project things
##
########################################################################################################################
pwd := ${PWD}
dirname := $(notdir $(patsubst %/,%,$(CURDIR)))
DOCKER_BUILDKIT ?= 1

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

BUILDKIT_ARGS := COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) BUILDKIT_PROGRESS=plain

delete-hooks:
	rm .git/hooks/pre-commit 2>/dev/null || true
	rm .git/hooks/commit-msg 2>/dev/null || true

.git/hooks/pre-commit:
	cp scripts/hooks/pre-commit.sh .git/hooks/pre-commit

.git/hooks/commit-msg:
	cp scripts/hooks/commit-msg.sh .git/hooks/commit-msg

refresh-hooks: delete-hooks .git/hooks/pre-commit .git/hooks/commit-msg


install:
	poetry install --sync

install-ci:
	poetry install --without local,ipython --sync

update:
	poetry update

.docker.env:
	echo "MESH_PERSISTANCE=YES" >> .docker.env

down: .docker.env
	poetry run docker-compose --env-file .docker.env down --remove-orphans || true
	make -C terraform/stacks/local clean

up-ci:
up:
	$(BUILDKIT_ARGS) poetry run docker-compose --env-file .docker.env up -d --remove-orphans


docker-build:
	$(BUILDKIT_ARGS) poetry run docker-compose build

mypy:
	poetry run mypy . --exclude '(^|/)(build|dist)/.*\.py'

pylint:
	poetry run pylint .

pylint-ci:
	poetry run pylint --output-format=parseable --score=no .

shellcheck:
	@# Only swallow checking errors (rc=1), not fatal problems (rc=2)
	docker run --rm -i -v ${PWD}:/mnt:ro koalaman/shellcheck -f gcc -e SC1090,SC1091 `find . \( -path "*/.venv/*" -prune -o -path "*/build/*" -prune \) -o -type f -name '*.sh' -print` || test $$? -eq 1

hadolint:
	@echo "hadolint --config=docker/hadolint.yml docker/*/Dockerfile"
	@# The pipe swallows return code, so no need for "|| true".
	@docker run --rm -i -v ${PWD}/docker:/docker:ro hadolint/hadolint hadolint --config=docker/hadolint.yml Dockerfile | sed 's/:\([0-9]\+\) /:\1:0 /'

clean:
	rm -rf ./dist || true
	rm -rf ./reports || true
	rm -f docker-compose.override.yml || true
	rm -f .docker.env || true
	find . -type d -name '.mypy_cache' | xargs rm -rf || true
	find . -type d -name '.pytest_cache' | xargs rm -rf || true
	find . -type d -name '__pycache__' | xargs rm -rf || true
	find . -type f -name '.coverage' | xargs rm -rf || true


purge: clean
	rm -rf .venv || true
	find . -type f -name '.lock-hash' | xargs rm
	make -C devops purge
	make -C docker purge
	make -C lambda purge


black-check:
	poetry run black . --check

isort-check:
	poetry run isort . -c

black:
	poetry run isort .
	poetry run black .


run-local:
	poetry run uvicorn src.mesh_sandbox.api:app --reload --port 5201 --proxy-headers