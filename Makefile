# workspace discovery variables
mkfile_path:=$(abspath $(lastword $(MAKEFILE_LIST)))
WORKSPACE:=$(realpath -f $(dir $(mkfile_path)))
LOCALHOST:=$(shell hostname -f)
GIT_COMMIT:=$(shell cd ${WORKSPACE} && git log -1 --pretty=%h ${DIR} 2>/dev/null)
DOCKER_REGISTRY:=docker.repo.eng.netapp.com
DOCKER_IMAGE_NAME:=mcp-atlassian
PREFIX=usercicd/jroussin
DOCKER_IMAGE_TAG=$(GIT_COMMIT)
DOCKER_IMAGE_PREFIX:=$(DOCKER_REGISTRY)/$(PREFIX)
DOCKER_IMAGE=$(DOCKER_IMAGE_PREFIX)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)

CRI_TOOLKIT=docker

build: ## -- Build the container image for playground
	@echo "Building $(DOCKER_IMAGE_NAME)..."
	DOCKER_BUILDKIT=1 $(CRI_TOOLKIT) build -t $(DOCKER_IMAGE)  \
		--progress=plain \
		--file $(WORKSPACE)/Dockerfile \
		$(WORKSPACE)

start-confluence:
	@echo "Starting $(DOCKER_IMAGE_NAME) confluence ..."
	DOCKER_BUILDKIT=1 $(CRI_TOOLKIT) run -d \
			--name confluence \
			-e MCP_VERBOSE=true \
			-e CONFLUENCE_URL=https://confluence.ngage.netapp.com \
			-e ATLASSIAN_OAUTH_ENABLE=true \
			-p 9000:9000 \
		       $(DOCKER_IMAGE) --transport streamable-http --port 9000	

stop-confluence:
	@echo "Stopping $(DOCKER_IMAGE_NAMGE) confluence ..."
	$(CRI_TOOLKIT) stop confluence || true && $(CRI_TOOLKIT) rm confluence || true 

restart-confluence: build stop-confluence start-confluence

start-inspector:
	docker run --rm -p 6274:6274 -p 6277:6277 -e HOST=0.0.0.0 -e DANGEROUSLY_OMIT_AUTH=true -e MCP_AUTO_OPEN_ENABLED=false -e ALLOWED_ORIGINS=http://$(LOCALHOST):6274 ghcr.io/modelcontextprotocol/inspector:latest
