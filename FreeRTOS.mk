# 获取当前 Makefile 所在目录的绝对路径
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
FREERTOS_PORT_DIR := $(dir $(MAKEFILE_PATH))

# 获取工程根目录 (FreeRTOS_port 的上级目录)
PROJECT_DIR := $(patsubst %/,%,$(dir $(FREERTOS_PORT_DIR:%/=%)))

# 目标文件路径
FREERTOS_CONFIG := $(PROJECT_DIR)/FreeRTOSConfig.h
CMAKE_LISTS := $(PROJECT_DIR)/CMakeLists.txt

# 防止make默认命令为rtos_init
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

.PHONY: rtos_init create_config update_cmakelists

rtos_init: create_config update_cmakelists
	@echo "------------------------"
	@echo "FreeRTOS 初始化完成"
	@echo "------------------------"

# 创建 FreeRTOSConfig.h
create_config:
	@if [ -f "$(FREERTOS_CONFIG)" ]; then \
		echo "FreeRTOSConfig.h 已存在，跳过创建"; \
	else \
		echo "创建 FreeRTOSConfig.h..."; \
		printf '%s\n' \
		'/* USER CODE BEGIN Header */' \
		'/*' \
		' * FreeRTOS Kernel V11.2.0' \
		' * Copyright (C) 2021 Amazon.com, Inc. or its affiliates.  All Rights Reserved.' \
		' *' \
		' * Permission is hereby granted, free of charge, to any person obtaining a copy of' \
		' * this software and associated documentation files (the "Software"), to deal in' \
		' * the Software without restriction, including without limitation the rights to' \
		' * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of' \
		' * the Software, and to permit persons to whom the Software is furnished to do so,' \
		' * subject to the following conditions:' \
		' *' \
		' * The above copyright notice and this permission notice shall be included in all' \
		' * copies or substantial portions of the Software.' \
		' *' \
		' * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR' \
		' * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS' \
		' * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR' \
		' * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER' \
		' * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN' \
		' * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.' \
		' *' \
		' * https://www.FreeRTOS.org' \
		' * https://github.com/FreeRTOS' \
		' */' \
		'/* USER CODE END Header */' \
		'' \
		'#ifndef FREERTOS_CONFIG_H' \
		'#define FREERTOS_CONFIG_H' \
		'' \
		'/*----------------------------------------------------------' \
		' * Application specific definitions.' \
		' *' \
		' * These definitions should be adjusted for your particular hardware and' \
		' * application requirements.' \
		' *' \
		' * See http://www.freertos.org/a00110.html' \
		' *----------------------------------------------------------*/' \
		'' \
		'/* USER CODE BEGIN Includes */' \
		'/* Section where include file can be added */' \
		'/* USER CODE END Includes */' \
		'' \
		'/* Ensure definitions are only used by the compiler, and not by the assembler. */' \
		'#if defined(__ICCARM__) || defined(__CC_ARM) || defined(__GNUC__)' \
		'  #include <stdint.h>' \
		'  extern uint32_t SystemCoreClock;' \
		'#endif' \
		'#ifndef CMSIS_device_header' \
		'#define CMSIS_device_header "stm32f4xx.h"' \
		'#endif /* CMSIS_device_header */' \
		'' \
		'#define configENABLE_FPU                         0' \
		'#define configENABLE_MPU                         0' \
		'' \
		'#define configUSE_PREEMPTION                     1' \
		'#define configSUPPORT_STATIC_ALLOCATION          1' \
		'#define configSUPPORT_DYNAMIC_ALLOCATION         1' \
		'#define configUSE_IDLE_HOOK                      0' \
		'#define configUSE_TICK_HOOK                      0' \
		'#define configCPU_CLOCK_HZ                       ( SystemCoreClock )' \
		'#define configTICK_RATE_HZ                       ( 1000 )' \
		'#define configMAX_PRIORITIES                     ( 56 )' \
		'#define configMINIMAL_STACK_SIZE                 ( ( uint16_t ) 128 )' \
		'#define configTOTAL_HEAP_SIZE                    ((size_t)15360)' \
		'#define configMAX_TASK_NAME_LEN                  ( 16 )' \
		'#define configUSE_TRACE_FACILITY                 1' \
		'#define configUSE_16_BIT_TICKS                   0' \
		'#define configUSE_MUTEXES                        1' \
		'#define configQUEUE_REGISTRY_SIZE                8' \
		'#define configUSE_RECURSIVE_MUTEXES              1' \
		'#define configUSE_COUNTING_SEMAPHORES            1' \
		'#define configUSE_PORT_OPTIMISED_TASK_SELECTION  0' \
		'' \
		'/* USER CODE BEGIN MESSAGE_BUFFER_LENGTH_TYPE */' \
		'/* Defaults to size_t for backward compatibility, but can be changed' \
		'   if lengths will always be less than the number of bytes in a size_t. */' \
		'#define configMESSAGE_BUFFER_LENGTH_TYPE         size_t' \
		'/* USER CODE END MESSAGE_BUFFER_LENGTH_TYPE */' \
		'' \
		'/* Co-routine definitions. */' \
		'#define configUSE_CO_ROUTINES                    0' \
		'#define configMAX_CO_ROUTINE_PRIORITIES          ( 2 )' \
		'' \
		'/* Software timer definitions. */' \
		'#define configUSE_TIMERS                         1' \
		'#define configTIMER_TASK_PRIORITY                ( 2 )' \
		'#define configTIMER_QUEUE_LENGTH                 10' \
		'#define configTIMER_TASK_STACK_DEPTH             256' \
		'' \
		'/* Set the following definitions to 1 to include the API function, or zero' \
		'to exclude the API function. */' \
		'#define INCLUDE_vTaskPrioritySet             1' \
		'#define INCLUDE_uxTaskPriorityGet            1' \
		'#define INCLUDE_vTaskDelete                  1' \
		'#define INCLUDE_vTaskCleanUpResources        0' \
		'#define INCLUDE_vTaskSuspend                 1' \
		'#define INCLUDE_vTaskDelayUntil              1' \
		'#define INCLUDE_vTaskDelay                   1' \
		'#define INCLUDE_xTaskGetSchedulerState       1' \
		'#define INCLUDE_xTimerPendFunctionCall       1' \
		'#define INCLUDE_xQueueGetMutexHolder         1' \
		'#define INCLUDE_uxTaskGetStackHighWaterMark  1' \
		'#define INCLUDE_xTaskGetCurrentTaskHandle    1' \
		'#define INCLUDE_eTaskGetState                1' \
		'' \
		'/* Cortex-M specific definitions. */' \
		'#ifdef __NVIC_PRIO_BITS' \
		' /* __NVIC_PRIO_BITS will be specified when CMSIS is being used. */' \
		' #define configPRIO_BITS         __NVIC_PRIO_BITS' \
		'#else' \
		' #define configPRIO_BITS         4' \
		'#endif' \
		'' \
		'/* The lowest interrupt priority that can be used in a call to a "set priority"' \
		'function. */' \
		'#define configLIBRARY_LOWEST_INTERRUPT_PRIORITY   15' \
		'' \
		'/* The highest interrupt priority that can be used by any interrupt service' \
		'routine that makes calls to interrupt safe FreeRTOS API functions.  DO NOT CALL' \
		'INTERRUPT SAFE FREERTOS API FUNCTIONS FROM ANY INTERRUPT THAT HAS A HIGHER' \
		'PRIORITY THAN THIS! (higher priorities are lower numeric values. */' \
		'#define configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY 5' \
		'' \
		'/* Interrupt priorities used by the kernel port layer itself.  These are generic' \
		'to all Cortex-M ports, and do not rely on any particular library functions. */' \
		'#define configKERNEL_INTERRUPT_PRIORITY 		( configLIBRARY_LOWEST_INTERRUPT_PRIORITY << (8 - configPRIO_BITS) )' \
		'/* !!!! configMAX_SYSCALL_INTERRUPT_PRIORITY must not be set to zero !!!!' \
		'See http://www.FreeRTOS.org/RTOS-Cortex-M3-M4.html. */' \
		'#define configMAX_SYSCALL_INTERRUPT_PRIORITY 	( configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY << (8 - configPRIO_BITS) )' \
		'' \
		'/* Normal assert() semantics without relying on the provision of an assert.h' \
		'header file. */' \
		'/* USER CODE BEGIN 1 */' \
		'#define configASSERT( x ) if ((x) == 0) {taskDISABLE_INTERRUPTS(); for( ;; );}' \
		'/* USER CODE END 1 */' \
		'' \
		'/* Definitions that map the FreeRTOS port interrupt handlers to their CMSIS' \
		'standard names. */' \
		'#define vPortSVCHandler    SVC_Handler' \
		'#define xPortPendSVHandler PendSV_Handler' \
		'#define xPortSysTickHandler SysTick_Handler' \
		'' \
		'/* USER CODE BEGIN Defines */' \
		'/* Section where parameter definitions can be added (for instance, to override default ones in FreeRTOS.h) */' \
		'/* USER CODE END Defines */' \
		'' \
		'#endif /* FREERTOS_CONFIG_H */' \
		> $(FREERTOS_CONFIG); \
		echo "FreeRTOSConfig.h 创建完成"; \
	fi

# 更新 CMakeLists.txt
update_cmakelists:
	@if [ -f "$(CMAKE_LISTS)" ]; then \
		if ! grep -q "FreeRTOS Configuration" $(CMAKE_LISTS); then \
			echo "添加 FreeRTOS 配置到 CMakeLists.txt..."; \
			echo "" >> $(CMAKE_LISTS); \
			echo "# FreeRTOS Configuration" >> $(CMAKE_LISTS); \
			echo "# Set FreeRTOS port for MCU Core (替换__TODO_REPLACE_CORE__为工程使用的,可以参考FreeRTOS_port/ReadMe.md)" >> $(CMAKE_LISTS); \
			echo "set(FREERTOS_PORT __TODO_REPLACE_CORE__ CACHE STRING \"FreeRTOS port\" FORCE)" >> $(CMAKE_LISTS); \
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

# 公共 FreeRTOS 源文件
FREERTOS_SOURCES = FreeRTOS_port/FreeRTOS-Kernel/croutine.c \
                   FreeRTOS_port/FreeRTOS-Kernel/event_groups.c \
                   FreeRTOS_port/FreeRTOS-Kernel/list.c \
                   FreeRTOS_port/FreeRTOS-Kernel/queue.c \
                   FreeRTOS_port/FreeRTOS-Kernel/stream_buffer.c \
                   FreeRTOS_port/FreeRTOS-Kernel/tasks.c \
                   FreeRTOS_port/FreeRTOS-Kernel/timers.c \
                   FreeRTOS_port/freertos_callbacks.c \
                   FreeRTOS_port/FreeRTOS-Kernel/portable/MemMang/heap_$(CFG_HEAP).c

# 公共头文件路径
FREERTOS_INCLUDES = FreeRTOS_port/FreeRTOS-Kernel \
                    FreeRTOS_port/FreeRTOS-Kernel/include \
                    $(PROJECT_DIR)

# 各 core 类型对应的 port 文件 + 头文件路径
PORT_DIR = FreeRTOS_port/FreeRTOS-Kernel/portable/GCC

ifeq ($(CFG_CORE),ARM_CM0)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM0/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM0/mpu_wrappers_v2_asm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM0/portasm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM0
else ifeq ($(CFG_CORE),ARM_CM3)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM3/port.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM3
else ifeq ($(CFG_CORE),ARM_CM3_MPU)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM3_MPU/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM3_MPU/mpu_wrappers_v2_asm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM3_MPU
else ifeq ($(CFG_CORE),ARM_CM4F)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM4F/port.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM4F
else ifeq ($(CFG_CORE),ARM_CM4_MPU)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM4_MPU/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM4_MPU/mpu_wrappers_v2_asm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM4_MPU
else ifeq ($(CFG_CORE),ARM_CM7)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM4F/port.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM4F
else ifeq ($(CFG_CORE),ARM_CM33_SECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_context_port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_context.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_heap.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/secure/secure_init.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM33/secure
else ifeq ($(CFG_CORE),ARM_CM33_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM33/non_secure
else ifeq ($(CFG_CORE),ARM_CM33_NTZ_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM33_NTZ/non_secure
else ifeq ($(CFG_CORE),ARM_CM55_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM55/non_secure
else ifeq ($(CFG_CORE),ARM_CM55_SECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_context_port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_context.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_heap.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55/secure/secure_init.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM55/secure
else ifeq ($(CFG_CORE),ARM_CM55_NTZ_NONSECURE)
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure/port.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure/portasm.c
  FREERTOS_SOURCES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure/mpu_wrappers_v2_asm.c
  FREERTOS_INCLUDES += $(PORT_DIR)/ARM_CM55_NTZ/non_secure
else ifeq ($(wildcard $(CMAKE_LISTS)),)
  $(error Unknown CFG_CORE: $(CFG_CORE))
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



