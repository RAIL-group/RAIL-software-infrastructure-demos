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
	--env DISPLAY=$(DISPLAY) \
	--volume="$(UNITY_DIR):/unity/:rw" \
	--volume="$(DATA_BASE_DIR):/data/:rw" \
	--volume="/tmp/.X11-unix:/tmp/.X11-unix:rw"
DOCKER_DEVEL_VOLUMES = \
	--volume="$(PWD)/requirements.txt:/requirements.txt:rw" \
	--volume="$(PWD)/scripts:/scripts:rw" \
	--volume="$(PWD)/src/unitybridge:/unitybridge:rw"
	--volume="$(PWD)/tests:/tests:rw"


.PHONY: help
help:
	@echo ''
	@echo 'Usage: make [TARGET] [EXTRA_ARGUMENTS]'
	@echo 'Core Targets:'
	@echo '  help		display this help message'
	@echo '  build		build docker image (incremental)'
	@echo '  rebuild	build docker image from scratch'
	@echo '  kill		close all project-related docker containers'
	@echo '  term		open a terminal in the docker container'
	@echo '  devel		term, but with local code folders mounted'
	@echo 'Demo Targets:'
	@echo '  all 		(or "all-demos") runs all demos'
	@echo '  demo-batch-parallel (run with "-j6") shows off parallel job running with make'
	@echo '  demo-plotting  plots via matplotlib inside the container'
	@echo '  demo-pybind	runs C++ code in python via pybind'
	@echo '  demo-unity-env runs Unity in headless mode, generates plot'


unity:
	@echo "Unzipping the Unity environment."
	@unzip unity.zip

.PHONY: build
build: unity
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

.PHONY: format
format:
	@echo "Formatting python code via yapf"
	@docker run --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) $(DOCKER_DEVEL_VOLUMES)\
		${IMAGE_NAME}:${VERSION} yapf --recursive --in-place /unitybridge /scripts /src /test


.PHONY: xhost-activate
xhost-activate:
	@echo "Enabling local xhost sharing:"
	@echo "  Display: $(DISPLAY)"
	@-DISPLAY=$(DISPLAY) xhost  +
	@- xhost  +


# ===== Development targets =====

.PHONY: term devel test
term:
	@docker run -it --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
		${IMAGE_NAME}:${VERSION} /bin/bash
devel:
	@docker run -it --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) $(DOCKER_DEVEL_VOLUMES)\
		${IMAGE_NAME}:${VERSION} /bin/bash
test:
	@docker run --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
		${IMAGE_NAME}:${VERSION} python3 -m py.test \
			-rsx \
			--unity_exe_path /unity/$(UNITY_DBG_BASENAME).x86_64 \
			tests


# ===== Demo scripts =====

.PHONY: all all-demos
all all-demos: test demo-pybind demo-batch-parallel demo-unity-env demo-plotting

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
demo-unity-env: xhost-activate demo-make-data-dir
	@echo "Demo: Interfacing with Unity"
	@docker run --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
		${IMAGE_NAME}:${VERSION} \
		python3 -m scripts.unity_env_demo \
		--unity_exe_path /unity/$(UNITY_DBG_BASENAME).x86_64 \
		--output_image /data/demo_unity_env.png \
		--xpassthrough $(XPASSTHROUGH)


# PyBind11 Examples

.PHONY: demo-pybind
demo-pybind: demo-make-data-dir
	@echo "Demo: Running code via PyBind"
	@docker run --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
		${IMAGE_NAME}:${VERSION} \
		python3 -m scripts.pybind_demo

# ===== targets for batch operation =====

.PHONY: batch-parallel-seeds batch-parallel
batch-parallel-seeds = $(shell for ii in $$(seq 100 140); do echo "batch-parallel-$$ii"; done)
demo-batch-parallel: $(batch-parallel-seeds)

$(batch-parallel-seeds):
	@docker run --init --gpus all --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_VOLUMES) \
		${IMAGE_NAME}:${VERSION} \
		python3 -m scripts.simple_wait \
		--seed $(shell echo '$@' | grep -Eo '[0-9]+') \
