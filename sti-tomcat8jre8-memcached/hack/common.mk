SKIP_SQUASH?=0

build = hack/build.sh

script_env = \
	SKIP_SQUASH=$(SKIP_SQUASH)                      \
	UPDATE_BASE=$(UPDATE_BASE)                      \
	BASE_IMAGE_NAME=$(BASE_IMAGE_NAME)              \
	DOCKER_VERSION=$(DOCKER_VERSION)                \
	DOCKER_NAMESPACE=$(DOCKER_NAMESPACE)            

.PHONY: build
build:
	$(script_env) $(build)

.PHONY: test
test:
	$(script_env) TAG_ON_SUCCESS=$(TAG_ON_SUCCESS) TEST_MODE=true $(build)