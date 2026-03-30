.PHONY: build push login all clean

# =============================================================================
# Build Vars
# =============================================================================
ACR_NAME    ?= $(error 請設定 ACR_NAME，例如: make build ACR_NAME=myacr)
IMAGE_NAME  ?= debug-container-ms
VERSION     ?= 0.1
FULL_IMAGE  = $(ACR_NAME).azurecr.io/$(IMAGE_NAME)

.DEFAULT_GOAL := build

# =============================================================================
# Targets
# =============================================================================

build:
	@echo "==> Building $(FULL_IMAGE):$(VERSION) (amd64)..."
	@docker build --platform linux/amd64 -t $(FULL_IMAGE):$(VERSION) -t $(FULL_IMAGE):latest .

login:
	@echo "==> Logging in to $(ACR_NAME).azurecr.io..."
	@az acr login --name $(ACR_NAME)

push: login
	@echo "==> Pushing $(FULL_IMAGE):$(VERSION)..."
	@docker push $(FULL_IMAGE):$(VERSION)
	@docker push $(FULL_IMAGE):latest

all: build push

clean:
	@echo "==> Removing local images..."
	@docker rmi $(FULL_IMAGE):$(VERSION) $(FULL_IMAGE):latest 2>/dev/null || true
