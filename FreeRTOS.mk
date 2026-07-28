# 获取当前 Makefile 所在目录的绝对路径
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
FREERTOS_PORT_DIR := $(dir $(MAKEFILE_PATH))

# 获取工程根目录 (FreeRTOS_port 的上级目录)
PROJECT_DIR := $(patsubst %/,%,$(dir $(FREERTOS_PORT_DIR:%/=%)))

# 目标文件路径
FREERTOS_CONFIG_TEMPLATE := $(FREERTOS_PORT_DIR)templates/FreeRTOSConfig.h
FREERTOS_CONFIG := $(PROJECT_DIR)/FreeRTOSConfig.h
CMAKE_LISTS := $(PROJECT_DIR)/CMakeLists.txt

# 防止make默认命令为rtos_init
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

.PHONY: rtos_init rtos_clone create_config update_cmakelists

rtos_init: create_config update_cmakelists
	@echo "------------------------"
	@echo "FreeRTOS 初始化完成"
	@echo "------------------------"

# 创建 FreeRTOSConfig.h
create_config:
	@if [ -f "$(FREERTOS_CONFIG)" ]; then \
		echo "FreeRTOSConfig.h 已存在，跳过创建"; \
	elif [ ! -f "$(FREERTOS_CONFIG_TEMPLATE)" ]; then \
		echo "错误：找不到模板 $(FREERTOS_CONFIG_TEMPLATE)"; \
		exit 1; \
	else \
		echo "创建 FreeRTOSConfig.h..."; \
		cp "$(FREERTOS_CONFIG_TEMPLATE)" "$(FREERTOS_CONFIG)"; \
		echo "FreeRTOSConfig.h 创建完成"; \
	fi

# 更新 CMakeLists.txt
update_cmakelists:
	@if [ -f "$(CMAKE_LISTS)" ]; then \
		if ! grep -q "FreeRTOS Configuration" $(CMAKE_LISTS); then \
			echo "添加 FreeRTOS 配置到 CMakeLists.txt..."; \
			echo "" >> $(CMAKE_LISTS); \
			echo "# FreeRTOS Configuration" >> $(CMAKE_LISTS); \
			echo "# Set FreeRTOS port (替换__TODO_REPLACE_PORT__为工程使用的,可以参考FreeRTOS_port/ReadMe.md)" >> $(CMAKE_LISTS); \
			echo "set(FREERTOS_PORT __TODO_REPLACE_PORT__ CACHE STRING \"FreeRTOS port\" FORCE)" >> $(CMAKE_LISTS); \
			echo "" >> $(CMAKE_LISTS); \
			echo "# Set heap implementation (替换__TODO_REPLACE_HEAP__为工程使用的,可以参考FreeRTOS_port/ReadMe.md)" >> $(CMAKE_LISTS); \
			echo "set(FREERTOS_HEAP __TODO_REPLACE_HEAP__ CACHE STRING \"FreeRTOS heap implementation\" FORCE)" >> $(CMAKE_LISTS); \
			echo "add_subdirectory(FreeRTOS_port)" >> $(CMAKE_LISTS); \
			echo "CMakeLists.txt 更新完成"; \
		else \
			echo "CMakeLists.txt 已配置FreeRTOS,跳过更新"; \
		fi; \
	else \
		echo "未检测到 CMakeLists.txt,跳过"; \
	fi

# GNU Make 和 CMake 统一使用 FreeRTOS 官方配置名称
SUPPORTED_FREERTOS_PORTS := GCC_ARM_CM0 \
                            GCC_ARM_CM3 \
                            GCC_ARM_CM3_MPU \
                            GCC_ARM_CM4F \
                            GCC_ARM_CM4_MPU \
                            GCC_ARM_CM7 \
                            GCC_ARM_CM33_SECURE \
                            GCC_ARM_CM33_NONSECURE \
                            GCC_ARM_CM33_NTZ_NONSECURE \
                            GCC_ARM_CM55_SECURE \
                            GCC_ARM_CM55_NONSECURE \
                            GCC_ARM_CM55_NTZ_NONSECURE

SUPPORTED_FREERTOS_HEAPS := 1 2 3 4 5

# 仅纯辅助目标允许两个变量都不设置；GNU Make 构建必须同时设置并通过校验
FREERTOS_HELPER_GOALS := rtos_init rtos_clone create_config update_cmakelists
FREERTOS_NON_HELPER_GOALS := $(filter-out $(FREERTOS_HELPER_GOALS),$(MAKECMDGOALS))
FREERTOS_HELPER_ONLY := $(if $(strip $(MAKECMDGOALS)),$(if $(FREERTOS_NON_HELPER_GOALS),,1),)
FREERTOS_MAKE_CONFIGURED := $(strip $(FREERTOS_PORT)$(FREERTOS_HEAP))

ifneq ($(FREERTOS_MAKE_CONFIGURED),)
  ifeq ($(strip $(FREERTOS_PORT)),)
    $(error FREERTOS_PORT is required when FREERTOS_HEAP is set)
  endif
  ifneq ($(words $(strip $(FREERTOS_PORT))),1)
    $(error FREERTOS_PORT must contain exactly one value)
  endif
  ifeq ($(filter $(strip $(FREERTOS_PORT)),$(SUPPORTED_FREERTOS_PORTS)),)
    $(error Unsupported FREERTOS_PORT '$(FREERTOS_PORT)'. Supported values: $(SUPPORTED_FREERTOS_PORTS))
  endif

  ifeq ($(strip $(FREERTOS_HEAP)),)
    $(error FREERTOS_HEAP is required when FREERTOS_PORT is set)
  endif
  ifneq ($(words $(strip $(FREERTOS_HEAP))),1)
    $(error FREERTOS_HEAP must contain exactly one value)
  endif
  ifeq ($(filter $(strip $(FREERTOS_HEAP)),$(SUPPORTED_FREERTOS_HEAPS)),)
    $(error Unsupported FREERTOS_HEAP '$(FREERTOS_HEAP)'. Supported values: $(SUPPORTED_FREERTOS_HEAPS))
  endif
else
  ifeq ($(FREERTOS_HELPER_ONLY),)
    $(error FREERTOS_PORT and FREERTOS_HEAP are required for GNU Make builds)
  endif
endif

# 公共 FreeRTOS 源文件
FREERTOS_SOURCES = FreeRTOS_port/FreeRTOS-Kernel/croutine.c \
                   FreeRTOS_port/FreeRTOS-Kernel/event_groups.c \
                   FreeRTOS_port/FreeRTOS-Kernel/list.c \
                   FreeRTOS_port/FreeRTOS-Kernel/queue.c \
                   FreeRTOS_port/FreeRTOS-Kernel/stream_buffer.c \
                   FreeRTOS_port/FreeRTOS-Kernel/tasks.c \
                   FreeRTOS_port/FreeRTOS-Kernel/timers.c \
                   FreeRTOS_port/freertos_callbacks.c \
                   FreeRTOS_port/FreeRTOS-Kernel/portable/MemMang/heap_$(FREERTOS_HEAP).c

# 公共头文件路径
FREERTOS_INCLUDES = FreeRTOS_port/FreeRTOS-Kernel \
                    FreeRTOS_port/FreeRTOS-Kernel/include \
                    $(PROJECT_DIR)

# 各 core 类型对应的 port 文件 + 头文件路径
PORTABLE_DIR = FreeRTOS_port/FreeRTOS-Kernel/portable
PORT_DIR = $(PORTABLE_DIR)/GCC
MPU_COMMON_SOURCES = $(PORTABLE_DIR)/Common/mpu_wrappers.c \
                     $(PORTABLE_DIR)/Common/mpu_wrappers_v2.c

ifeq ($(FREERTOS_PORT),GCC_ARM_CM0)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM0/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM0/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM0/portasm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM0
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM3)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM3/port.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM3
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM3_MPU)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM3_MPU/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM3_MPU/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(MPU_COMMON_SOURCES)
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM3_MPU
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM4F)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM4F/port.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM4F
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM4_MPU)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM4_MPU/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM4_MPU/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(MPU_COMMON_SOURCES)
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM4_MPU
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM7)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM7/r0p1/port.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM7/r0p1
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM33_SECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_context_port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_context.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_heap.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_init.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM33/secure
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM33_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(MPU_COMMON_SOURCES)
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM33/non_secure
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM33_NTZ_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(MPU_COMMON_SOURCES)
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM55_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(MPU_COMMON_SOURCES)
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM55/non_secure
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM55_SECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_context_port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_context.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_heap.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_init.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM55/secure
else ifeq ($(FREERTOS_PORT),GCC_ARM_CM55_NTZ_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(MPU_COMMON_SOURCES)
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure
endif

EXTRA_C_SOURCES += $(FREERTOS_SOURCES)
EXTRA_INCLUDES += $(FREERTOS_INCLUDES)

# 验证 port 目录存在
ifeq ($(wildcard $(FREERTOS_PORT_DIR)),)
$(error Port directory not found: $(FREERTOS_PORT_DIR))
endif

rtos_clone:
	cd $(PROJECT_DIR)/FreeRTOS_port && \
	git submodule init && \
	git submodule update
