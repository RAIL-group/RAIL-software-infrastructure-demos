MAJOR ?= 0
MINOR ?= 1
VERSION = $(MAJOR).$(MINOR)
APP_NAME ?= rail-software-infrastructure-demos

# Docker args
DISPLAY ?= :0.0
XPASSTHROUGH ?= false
DOCKER_FILE_DIR = .
DOCKERFILE = ${DOCKER_FILE_DIR}/Dockerfile
NUM_BUILD_CORES ?= 1
IMAGE_NAME = ${APP_NAME}
UNITY_DIR ?= $(shell pwd)/unity/
UNITY_DBG_BASENAME ?= ei_base_unity
DATA_BASE_DIR ?= $(shell pwd)/data

# Handle Optional GPU
ifeq ($(USE_GPU),true)
	DOCKER_GPU_ARG = --gpus all
endif

DOCKER_CORE_ARGS = \
	--env XPASSTHROUGH=$(XPASSTHROUGH) \
	--env DISPLAY=$(DISPLAY) \
	--volume="$(UNITY_DIR):/unity/:rw" \
	--volume="$(DATA_BASE_DIR):/data/:rw" \
	$(DOCKER_GPU_ARG)

DOCKER_DEVEL_VOLUMES = \
	--volume="$(shell pwd)/requirements.txt:/requirements.txt:rw" \
	--volume="$(shell pwd)/scripts:/scripts:rw" \
	--volume="$(shell pwd)/src/unitybridge:/unitybridge:rw"
	--volume="$(shell pwd)/tests:/tests:rw"

DOCKER_PYTHON = @docker run --rm --init --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_ARGS) \
		${IMAGE_NAME}:${VERSION} python3 \


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

# === Helper functions ===

define xhost_activate
	@echo "Enabling local xhost sharing:"
	@echo "  Display: $(DISPLAY)"
	@-DISPLAY=$(DISPLAY) xhost  +
	@-xhost  +
endef

.PHONY: kill
kill:
	@echo "Closing all running docker containers:"
	@docker kill $(shell docker ps -q --filter ancestor=${IMAGE_NAME}:${VERSION})


# === Build Targets ===

unity:
	@echo "Unzipping the Unity environment."
	@unzip unity.zip

.PHONY: build
build: unity
	@-mkdir $(DATA_BASE_DIR)
	@docker build -t ${IMAGE_NAME}:${VERSION} \
		--build-arg NUM_BUILD_CORES=$(NUM_BUILD_CORES) \
		$(DOCKER_ARGS) -f ./${DOCKERFILE} .

.PHONY: rebuild
rebuild:
	@docker build -t ${IMAGE_NAME}:${VERSION} --no-cache \
		--build-arg NUM_BUILD_CORES=$(NUM_BUILD_CORES) \
		$(DOCKER_ARGS) -f ./${DOCKERFILE} .

# ===== Development targets =====

.PHONY: term devel test
term:
	@docker run -it --init $(DOCKER_GPU) --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_ARGS) \
		${IMAGE_NAME}:${VERSION} /bin/bash
devel:
	@docker run -it --init --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_ARGS) $(DOCKER_DEVEL_VOLUMES)\
		${IMAGE_NAME}:${VERSION} /bin/bash

test: build
	$(DOCKER_PYTHON) -m py.test \
		-rsx \
		--unity_exe_path /unity/$(UNITY_DBG_BASENAME).x86_64 \
		tests


# ===== Demo scripts =====

# === Parallel Execution ===

.PHONY: demo-batch-parallel-seeds demo-batch-parallel-all an-example-dependency

an-example-dependency:
	@echo "Running dependency."

demo-batch-parallel-seeds = $(shell for ii in $$(seq 100 120); do echo "demo-batch-parallel-$$ii"; done)
$(demo-batch-parallel-seeds): an-example-dependency
	@echo "Seed: $(shell echo '$@' | grep -Eo '[0-9]+'). Waiting..."
	@sleep $(shell echo '$@' | grep -Eo '[0-9]+' | awk '{print $$0%3 + 1}')
	@echo "...Done"

demo-batch-parallel-all: $(demo-batch-parallel-seeds)

# === Plotting ===
demo-plotting-image-name = $(DATA_BASE_DIR)/demo_plotting.png
$(demo-plotting-image-name):
	@echo "Demo: Write a plot from within Docker"
	@$(DOCKER_PYTHON) -m scripts.plotting_demo \
		--output_image /data/demo_plotting.png

# A high-level target that calls other targets with a more convenient name
.PHONY: demo-plotting
demo-plotting: $(demo-plotting-image-name)

demo-plotting-clean:
	@echo "Cleaning products from the plotting demo."
	@echo "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@rm -rf $(demo-plotting-image-name)

# A target that plots to the screen
.PHONY: demo-plotting-visualize
demo-plotting-visualize: XPASSTHROUGH=true
demo-plotting-visualize:
	@echo "Demo: Plotting from within Docker"
	@$(DOCKER_PYTHON) -m scripts.plotting_demo \
		--xpassthrough $(XPASSTHROUGH)

# A target that runs the Unity3D enviornment and generates an image
.PHONY: demo-unity-env
demo-unity-env:
	@echo "Demo: Interfacing with Unity"
	@$(call xhost-activate)
	@docker run --init --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_ARGS) \
		${IMAGE_NAME}:${VERSION} \
		python3 -m scripts.unity_env_demo \
		--unity_exe_path /unity/$(UNITY_DBG_BASENAME).x86_64 \
		--output_image /data/demo_unity_env.png \
		--xpassthrough $(XPASSTHROUGH)

# PyBind11 Examples
.PHONY: demo-pybind
demo-pybind:
	@echo "Demo: Running code via PyBind"
	@docker run --init --net=host \
		$(DOCKER_ARGS) $(DOCKER_CORE_ARGS) \
		${IMAGE_NAME}:${VERSION} \
		python3 -m scripts.pybind_demo

.PHONY: all-demos
all-demos: demo-pybind demo-batch-parallel demo-unity-env demo-plotting
	@echo "Completed all demos successfully."
