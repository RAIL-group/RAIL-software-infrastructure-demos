MAJOR ?= 0
MINOR ?= 1
VERSION = $(MAJOR).$(MINOR)
APP_NAME ?= template-docker-make

# Docker args
DISPLAY ?= :0.0
XPASSTHROUGH ?= false
DOCKER_FILE_DIR = "."
DOCKERFILE = ${DOCKER_FILE_DIR}/Dockerfile
NUM_BUILD_CORES ?= 1
IMAGE_NAME = ${APP_NAME}
UNITY_DIR ?= "$(PWD)/unity/"
UNITY_DBG_BASENAME ?= "ei_base_unity"
DATA_BASE_DIR ?= "$(PWD)/data/"

DOCKER_CORE_VOLUMES = \
	--env XPASSTHROUGH=$(XPASSTHROUGH) \
	--volume="$(UNITY_DIR):/unity/:rw" \
	--volume="$(DATA_BASE_DIR):/data/:rw" \
	--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw"


.PHONY: help
help:
	@echo ''
	@echo 'Usage: make [TARGET] [EXTRA_ARGUMENTS]'
	@echo 'Targets:'
	@echo '  help		display this help message'
	@echo '  build		build docker image (incremental)'
	@echo '  rebuild	build docker image from scratch'
	@echo '  kill		close all project-related docker containers'


.PHONY: build
build:
	@docker build -t ${IMAGE_NAME}:${VERSION} \
		--build-arg NUM_BUILD_CORES=$(NUM_BUILD_CORES) \
		$(DOCKER_ARGS) -f ./${DOCKERFILE} .

.PHONY: rebuild
rebuild:
	@docker build -t ${IMAGE_NAME}:${VERSION} --no-cache \
		--build-arg NUM_BUILD_CORES=$(NUM_BUILD_CORES) \
		$(DOCKER_ARGS) -f ./${DOCKERFILE} .

.PHONY: kill
kill:
	@echo "Closing all running docker containers:"
	@docker kill $(shell docker ps -q --filter ancestor=${IMAGE_NAME}:${VERSION})


# ===== Demo scripts =====

# Create directory where outputs will be saved
.PHONY: demo-make-data-dir
	@echo "Creating Data Directory"
	@-mkdir $(DATA_BASE_DIR)

.PHONY: demo-plotting
demo-plotting: demo-make-data-dir
	@echo "Demo: Plotting from within Docker"
	@docker run --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
		${IMAGE_NAME}:${VERSION} \
		python3 -m scripts.plotting_demo \
		--output_image /data/demo_plotting.png \
		--xpassthrough $(XPASSTHROUGH)

.PHONY: demo-unity-env
demo-unity-env: demo-make-data-dir
	@echo "Demo: Interfacing with Unity"
	@docker run --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
		${IMAGE_NAME}:${VERSION} \
		python3 -m scripts.unity_env_demo \
		--unity_exe_path /unity/$(UNITY_DBG_BASENAME).x86_64 \
		--output_image /data/demo_unity_env.png \
		--xpassthrough $(XPASSTHROUGH)
