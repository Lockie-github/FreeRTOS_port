# 目录
- [目录](#目录)
- [项目概述](#项目概述)
- [目录结构](#目录结构)
- [移植](#移植)
  - [移植之前](#移植之前)
  - [使用 GNU Make](#使用-gnu-make)
  - [使用 Cube-CMake](#使用-cube-cmake)
  - [用户手动配置参数参考](#用户手动配置参数参考)
  - [FreeRTOSConfig.h 关键配置项](#freertosconfigh-关键配置项)
    - [参数单位和内存归属](#参数单位和内存归属)
    - [调度和时间参数](#调度和时间参数)
    - [内存分配和调试参数](#内存分配和调试参数)
    - [同步、Timer 和可选 API](#同步timer-和可选-api)
    - [中断和处理器特性](#中断和处理器特性)
    - [按 SRAM 容量选择起始配置](#按-sram-容量选择起始配置)
    - [调整和验证步骤](#调整和验证步骤)
- [常见问题](#常见问题)
- [测试状态](#测试状态)
- [修订记录](#修订记录)
- [更新记录](#更新记录)
  - [\[11.3.0-2.0.0\] - 2026-07-28](#1130-200---2026-07-28)
  - [\[11.3.0-1.0.0\] - 2026-04-04](#1130-100---2026-04-04)

---

# 项目概述

本项目为 STM32CubeMX 生成的工程提供一套兼容 **GNU Make** 和 **STM32 for VSCode 插件的 Cube-CMake** 双构建系统的 FreeRTOS 移植方案。项目直接使用 FreeRTOS 官方内核源码，避免同时引入 CubeMX 自带的 FreeRTOS/CMSIS-RTOS middleware，适用于基于 ARM Cortex-M 系列的 MCU。HAL 和 CMSIS 设备头仍由 CubeMX 工程提供。

---

# 目录结构

```
项目根目录/
├── FreeRTOS_port/
│   ├── FreeRTOS-Kernel/          # FreeRTOS 内核源码 (Git 子模块)
│   ├── templates/
│   │   └── FreeRTOSConfig.h      # STM32CubeMX 通用配置模板
│   ├── freertos_callbacks.c      # 静态内存分配回调函数
│   ├── FreeRTOS.mk               # Make 构建配置
│   └── CMakeLists.txt            # CMake 构建配置
├── FreeRTOSConfig.h              # FreeRTOS 配置文件 (位于项目根目录)
├── Makefile                      # 主 Makefile
└── CMakeLists.txt                # 主 CMakeLists.txt (若存在)
```

---

# 移植
## 移植之前
首先建议配置ARM_SEGGER_RTT作为烧录、调试工具,仓库为[RTT](https://github.com/Lockie-github/ARM_SEGGER_RTT.git),此仓库同样适配了**GNU Make** 和 **STM32 for VSCode插件的cube-CMake**,请前往github仓库阅读readme进行配置,或直接clone到本地,参照`ARM_SEGGER_RTT/readme.md`进行配置
```bash
git clone https://github.com/Lockie-github/ARM_SEGGER_RTT.git
```

## 使用 GNU Make
1. 拉取本仓库到STM32CubeMX生成的Makefile工程路径下
```bash
git clone https://github.com/Lockie-github/FreeRTOS_port.git
```
2. 在主Makefile中引用FreeRTOS_port模块
在主 Makefile 中 `# compile gcc flags` 前添加以下内容，并将占位符替换为实际值，可参考[配置参数](#用户手动配置参数参考)。
```makefile
# *** FreeRTOS config ***
# Set heap implementation (heap_1...5 are supported)
FREERTOS_HEAP = __TODO_REPLACE_HEAP__

# Set FreeRTOS port
FREERTOS_PORT = __TODO_REPLACE_PORT__

include FreeRTOS_port/FreeRTOS.mk
EXTRA_INCLUDES := $(patsubst %,-I%,$(EXTRA_INCLUDES))
C_SOURCES += $(EXTRA_C_SOURCES)
C_INCLUDES += $(EXTRA_INCLUDES)
# compile gcc flags
```
3. 初始化配置文件
运行命令
```bash
make rtos_clone
make rtos_init
```
以上命令会将 `FreeRTOS_port/templates/FreeRTOSConfig.h` 复制到工程根目录。若目标文件已经存在则不会覆盖，应用参数可以直接在工程根目录的配置文件中修改。

4. 编译验证
编写测试文件:
在main.c中对应位置添加:
```C
/* USER CODE BEGIN Includes */
#include "rtt_log.h"
#include "FreeRTOS.h"
#include "task.h"
/* USER CODE END Includes */

/* USER CODE BEGIN PV */
static TaskHandle_t xTestTaskHandle;
/* USER CODE END PV */

/* USER CODE BEGIN PFP */
static void vTestTask(void *pvParameters);
/* USER CODE END PFP */

  /* USER CODE BEGIN Init */
  SEGGER_RTT_Init();
  /* USER CODE END Init */

  /* USER CODE BEGIN 2 */
  /* Create Test FreeRTOS Task */
  xTaskCreate(vTestTask,           /* Task function */
              "TestTask",          /* Task name */
              128,/* Stack size (words) */
              NULL,                   /* Task parameter */
              2,  /* Task priority */
              &xTestTaskHandle);   /* Task handle */

  /* Start scheduler */
  vTaskStartScheduler();

  /* USER CODE END 2 */

  /* USER CODE BEGIN 4 */
/**
  * @brief  Test Task implementation Outputs RTT log messages
  * @param  pvParameters: Not used
  * @retval None
  */
static void vTestTask(void *pvParameters)
{
  (void)pvParameters;
  
  for(;;)
  {
    log_info("Hello World...");
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}
/* USER CODE END 4 */
```
编译
```bash
make -j

```
其他相关命令请查阅Makefile

---
   
## 使用 Cube-CMake
1. 拉取本仓库到STM32CubeMX生成的CMake工程路径下
```bash
git clone https://github.com/Lockie-github/FreeRTOS_port.git
```
2. 在主Makefile中引用FreeRTOS_port模块
```
include FreeRTOS_port/FreeRTOS.mk
```
3. 初始化配置文件
运行命令
```bash
make rtos_clone
make rtos_init
```
以上命令会初始化 FreeRTOS-Kernel 子模块、从模板创建工程根目录下的 `FreeRTOSConfig.h`，并向根目录的 `CMakeLists.txt` 追加 FreeRTOS 配置。已有的 `FreeRTOSConfig.h` 不会被覆盖。

> **不要同时启用 CubeMX 自带的 FreeRTOS/CMSIS-RTOS middleware**。如果 `cmake/stm32cubemx/CMakeLists.txt` 中仍包含 `FreeRTOS_Src`、`add_library(FreeRTOS OBJECT)` 或旧 FreeRTOS include 路径，应先在 CubeMX 中关闭对应 middleware 并重新生成工程，否则可能重复编译 `tasks.c`、`queue.c`、`port.c`，或混用不同版本的 `FreeRTOS.h`。

配置工程参数:
在根目录的 `CMakeLists.txt` 中找到脚本追加的数据，将 `__TODO_REPLACE_PORT__` 和 `__TODO_REPLACE_HEAP__` 替换为实际值，可参考[配置参数](#用户手动配置参数参考)。

> **CMake 添加顺序必须正确**：`FreeRTOS_port` 会继承 CubeMX 的 `stm32cubemx` INTERFACE target，以获得 `main.h`、HAL/CMSIS 头文件路径和 MCU 宏。因此必须先执行 `add_subdirectory(cmake/stm32cubemx)`，再设置 FreeRTOS 参数并添加 `FreeRTOS_port`。

```cmake
# CubeMX generated sources, include paths and MCU definitions
add_subdirectory(cmake/stm32cubemx)

# FreeRTOS Configuration
set(FREERTOS_PORT GCC_ARM_CM4F CACHE STRING "FreeRTOS port" FORCE)
set(FREERTOS_HEAP 4 CACHE STRING "FreeRTOS heap implementation" FORCE)
add_subdirectory(FreeRTOS_port)
```

不要把 `add_subdirectory(FreeRTOS_port)` 放在 `add_subdirectory(cmake/stm32cubemx)` 之前，否则 CMake 会报告 `stm32cubemx target must be defined before adding FreeRTOS_port`。

4. 构建、编译验证
编写测试文件:
在main.c中对应位置添加:
```C
/* USER CODE BEGIN Includes */
#include "rtt_log.h"
#include "FreeRTOS.h"
#include "task.h"
/* USER CODE END Includes */

/* USER CODE BEGIN PV */
static TaskHandle_t xTestTaskHandle;
/* USER CODE END PV */

/* USER CODE BEGIN PFP */
static void vTestTask(void *pvParameters);
/* USER CODE END PFP */

  /* USER CODE BEGIN Init */
  SEGGER_RTT_Init();
  /* USER CODE END Init */

  /* USER CODE BEGIN 2 */
  /* Create Test FreeRTOS Task */
  xTaskCreate(vTestTask,           /* Task function */
              "TestTask",          /* Task name */
              128,/* Stack size (words) */
              NULL,                   /* Task parameter */
              2,  /* Task priority */
              &xTestTaskHandle);   /* Task handle */

  /* Start scheduler */
  vTaskStartScheduler();

  /* USER CODE END 2 */

  /* USER CODE BEGIN 4 */
/**
  * @brief  Test Task implementation Outputs RTT log messages
  * @param  pvParameters: Not used
  * @retval None
  */
static void vTestTask(void *pvParameters)
{
  (void)pvParameters;
  
  for(;;)
  {
    log_info("Hello World...");
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}
/* USER CODE END 4 */
```

构建:

```Bash
make preset_debug
```

编译:

```Bash
make d
```
其他相关命令请查阅Makefile

---


## 用户手动配置参数参考

Make 和 CMake 使用相同的参数名与参数值。构建系统只需要设置 `FREERTOS_PORT` 和 `FREERTOS_HEAP` 两个参数；生成后仍必须检查工程根目录下 `FreeRTOSConfig.h` 的内存、时钟、中断、MPU 和 TrustZone 配置。

1. `FREERTOS_PORT` / `__TODO_REPLACE_PORT__`

指定你的 MCU 对应的 FreeRTOS port 目录。

| `FREERTOS_PORT` (Make / CMake) | 适用芯片 | 额外说明 |
|--------------------------------|---------|---------|
| `GCC_ARM_CM0` | Cortex-M0 / M0+ | 源码映射已实现，尚未使用实际工程验证 |
| `GCC_ARM_CM3` | Cortex-M3 | 已使用 STM32F103 工程参数通过编译检查 |
| `GCC_ARM_CM3_MPU` | Cortex-M3 (带 MPU) | 映射已实现；必须配置系统调用栈和内核对象池大小 |
| `GCC_ARM_CM4F` | Cortex-M4 (带 FPU) | 已使用 STM32F411 完成编译和基本功能验证 |
| `GCC_ARM_CM4_MPU` | Cortex-M4 (带 MPU) | 映射已实现；必须配置系统调用栈和内核对象池大小 |
| `GCC_ARM_CM7` | Cortex-M7 | 使用官方 `ARM_CM7/r0p1` port，已使用 STM32H7 工程参数通过编译检查 |
| `GCC_ARM_CM33_SECURE` | Cortex-M33 (TrustZone 安全侧支持组件) | 映射已实现，尚未使用完整安全工程验证 |
| `GCC_ARM_CM33_NONSECURE` | Cortex-M33 (TrustZone 非安全侧) | 映射已实现，尚未使用完整实际工程验证 |
| `GCC_ARM_CM33_NTZ_NONSECURE` | Cortex-M33 (不使用 TrustZone) | 映射已实现，尚未使用完整实际工程验证 |
| `GCC_ARM_CM55_SECURE` | Cortex-M55 (TrustZone 安全侧支持组件) | 映射已实现，尚未使用完整安全工程验证 |
| `GCC_ARM_CM55_NONSECURE` | Cortex-M55 (TrustZone 非安全侧) | 映射已实现，尚未使用完整实际工程验证 |
| `GCC_ARM_CM55_NTZ_NONSECURE` | Cortex-M55 (不使用 TrustZone) | 映射已实现，尚未使用完整实际工程验证 |

> **常见选型参考**：
> - STM32F1xx → `GCC_ARM_CM3`
> - STM32F4xx / STM32G4xx → `GCC_ARM_CM4F`
> - STM32F7xx (带 FPU) → `GCC_ARM_CM7`
> - STM32L0xx → `GCC_ARM_CM0`
> - STM32U5xx（TrustZone 非安全侧并使用安全服务）→ `GCC_ARM_CM33_NONSECURE`
> - STM32U5xx（不使用 TrustZone）→ `GCC_ARM_CM33_NTZ_NONSECURE`
> - STM32U5xx（安全侧支持组件）→ `GCC_ARM_CM33_SECURE`

使用 `GCC_ARM_CM3_MPU`、`GCC_ARM_CM4_MPU`，或在 ARMv8-M port 中启用 MPU wrappers v2 时，必须在工程的 `FreeRTOSConfig.h` 中根据应用规模定义：

```c
#define configSYSTEM_CALL_STACK_SIZE             __TODO_REPLACE_STACK_WORDS__
#define configPROTECTED_KERNEL_OBJECT_POOL_SIZE  __TODO_REPLACE_OBJECT_COUNT__
```

`configSYSTEM_CALL_STACK_SIZE` 的单位为字，`configPROTECTED_KERNEL_OBJECT_POOL_SIZE` 是最大受保护内核对象数量。以上两个值无法根据 MCU 自动推导，模板不会提供可能误导的默认值。

2. `FREERTOS_HEAP` / `__TODO_REPLACE_HEAP__`

指定 FreeRTOS 堆管理策略。

| 值 | 名称 | 特点 | 推荐场景 |
|----|------|------|---------|
| `1` | `heap_1` | 只分配，不释放 | 极简应用，创建后不删除任务 |
| `2` | `heap_2` | 可分配和释放，但不合并碎片 | 固定大小内存块 |
| `3` | `heap_3` | 封装标准库 `malloc`/`free` | 线程安全要求简单 |
| `4` | `heap_4` | 可分配释放，**自动合并碎片** | **最常用，推荐** |
| `5` | `heap_5` | 同 `heap_4`，支持多个不连续内存区 | 分散 RAM 的复杂系统 |

> **默认推荐**：Make 使用 `FREERTOS_HEAP = 4`，CMake 使用 `set(FREERTOS_HEAP 4 ...)`。

使用 `heap_5` 时，应用必须在首次动态分配之前调用 `vPortDefineHeapRegions()` 定义可用内存区域。

---

## FreeRTOSConfig.h 关键配置项

`make rtos_init` 从 `FreeRTOS_port/templates/FreeRTOSConfig.h` 创建工程根目录下的 `FreeRTOSConfig.h`。模板通过 `main.h` 获取 CubeMX 的 HAL/CMSIS 设备定义。模板只提供能够启动评估的保守基线，不可能自动知道应用会创建多少任务、队列和缓冲区；生成后必须编辑工程根目录下的副本。

### 参数单位和内存归属

- `configTOTAL_HEAP_SIZE` 的单位是字节。使用 `heap_1`、`heap_2` 或 `heap_4` 时，它对应链接进 `.bss` 的 FreeRTOS heap；`heap_3` 使用 C library `malloc/free`，`heap_5` 则以 `vPortDefineHeapRegions()` 提供的实际区域为准。
- `configMINIMAL_STACK_SIZE`、`configTIMER_TASK_STACK_DEPTH` 和 `xTaskCreate()` 的 stack depth 单位都是 `StackType_t`，不是字节。当前 Cortex-M port 中一个 stack word 为 4 字节，因此 `128 words` 等于 `512 bytes`。
- 动态创建的任务会从 FreeRTOS heap 中分配任务栈和 TCB；静态创建的任务由应用提供栈和 TCB，它们仍占 RAM，但不计入 FreeRTOS heap 的已用空间。
- 同时启用静态和动态分配只是同时提供两组 API，不会让每个任务自动分配两份内存；实际占用由应用选择的创建函数决定。
- CubeMX 链接脚本中的 `_Min_Heap_Size` 是 C library heap，`_Min_Stack_Size` 是启动和中断使用的主栈。它们与 FreeRTOS heap、各任务栈分别占用 RAM，不能当作同一块内存重复计算。
- `configMAX_PRIORITIES` 定义的是任务优先级数量，与 NVIC 中断优先级无关。每增加一级任务优先级，内核都会增加一个 ready list 的静态开销。

### 调度和时间参数

| 宏定义 | 默认值 | 意义及调整原则 |
|--------|--------|----------------|
| `configUSE_PREEMPTION` | `1` | `1` 使用抢占式调度；`0` 使用协作式调度。一般保持抢占式，协作式任务必须主动阻塞或让出 CPU。 |
| `configCPU_CLOCK_HZ` | `SystemCoreClock` | 内核时钟频率。模板直接使用 CMSIS 维护的 `SystemCoreClock`；修改系统时钟后必须确保该变量同步更新。 |
| `configTICK_RATE_HZ` | `1000` | RTOS tick 频率。`1000 Hz` 提供 1 ms 粒度但增加中断和功耗；低功耗 L0/G0 应评估 `100` 或 `250 Hz` 是否足够。 |
| `configMAX_PRIORITIES` | `8` | 可用任务优先级为 `0` 至 `7`。任务模型简单时使用 `4` 至 `8`；增加该值会增加 ready list 的静态 RAM。 |
| `configMINIMAL_STACK_SIZE` | `128 words` | Idle 任务栈深度，不是所有任务的统一栈大小。只能根据 `uxTaskGetStackHighWaterMark()` 的实测结果谨慎降低。 |
| `configTICK_TYPE_WIDTH_IN_BITS` | `TICK_TYPE_WIDTH_32_BITS` | 32 位 tick 计数。16 位可节省少量 RAM，但会显著缩短 tick 回绕周期，通常保持 32 位。 |
| `configUSE_PORT_OPTIMISED_TASK_SELECTION` | `0` | 是否使用 port 优化的最高优先级查找。只有对应 port 明确支持且优先级数量满足限制时才启用。 |
| `configUSE_IDLE_HOOK` | `0` | 启用 `vApplicationIdleHook()`。Hook 不得阻塞，可用于低功耗入口或轻量后台处理。 |
| `configUSE_TICK_HOOK` | `0` | 启用 `vApplicationTickHook()`。它运行在 tick ISR 中，必须短小且只能调用允许在 ISR 中使用的 API。 |
| `configMAX_TASK_NAME_LEN` | `16` | 每个 TCB 中任务名缓冲区长度。任务多且 RAM 紧张时可降低，但会截断调试名称。 |

### 内存分配和调试参数

| 宏定义 | 默认值 | 意义及调整原则 |
|--------|--------|----------------|
| `configSUPPORT_STATIC_ALLOCATION` | `1` | 允许 `xTaskCreateStatic()` 等静态创建 API；同时要求提供 Idle 任务内存回调。 |
| `configSUPPORT_DYNAMIC_ALLOCATION` | `1` | 允许 `xTaskCreate()` 等动态创建 API；需要选择 `heap_1` 至 `heap_5` 之一。 |
| `configTOTAL_HEAP_SIZE` | `1024 bytes` | 小容量 STM32 的起始值，不是推荐上限。任务栈、TCB、动态队列和信号量都可能从这里分配。 |
| `configUSE_TRACE_FACILITY` | `0` | 增加任务状态和 trace 支持，也会增加 TCB、代码和部分内核数据；需要运行时分析工具时再开启。 |
| `configQUEUE_REGISTRY_SIZE` | `0` | 调试器可见的队列/信号量注册表容量。生产构建通常为 `0`，调试时按实际注册对象数设置。 |
| `configMESSAGE_BUFFER_LENGTH_TYPE` | `size_t` | Message/Stream Buffer 长度字段类型。确认单个缓冲区不会超过 65535 字节时，可评估改为 `uint16_t`。 |
| `configASSERT()` | 死循环 | 配置错误时关闭中断并停住，便于调试器定位。量产工程可增加错误记录或复位，但不应简单删除断言。 |

### 同步、Timer 和可选 API

| 宏定义 | 默认值 | 意义及调整原则 |
|--------|--------|----------------|
| `configUSE_MUTEXES` | `1` | 启用互斥量和优先级继承；使用共享资源时通常保留。 |
| `configUSE_RECURSIVE_MUTEXES` | `1` | 启用递归互斥量。确认没有递归锁需求时可关闭以减少代码。 |
| `configUSE_COUNTING_SEMAPHORES` | `1` | 启用计数信号量。只使用二值信号量时可关闭。 |
| `configUSE_CO_ROUTINES` | `0` | 旧式 co-routine 功能，新工程通常保持关闭。 |
| `configMAX_CO_ROUTINE_PRIORITIES` | `2` | co-routine 优先级数量，仅在启用 co-routine 时生效。 |
| `configUSE_TIMERS` | `0` | 软件定时器默认关闭。启用后会额外创建 Timer daemon 任务、命令队列和相关内核对象。 |
| `configTIMER_TASK_PRIORITY` | `2` | Timer daemon 任务优先级，必须小于 `configMAX_PRIORITIES`，并根据回调时效性设置。 |
| `configTIMER_QUEUE_LENGTH` | `5` | 等待处理的 Timer 命令数量。频繁从任务或 ISR 操作 Timer 时需要增大。 |
| `configTIMER_TASK_STACK_DEPTH` | `128 words` | Timer daemon 栈深度。复杂回调、格式化输出或较深调用链通常需要 `256 words` 以上。 |
| `INCLUDE_xTimerPendFunctionCall` | `0` | 编译 `xTimerPendFunctionCall()` API。设为 `1` 时必须同时设置 `configUSE_TIMERS=1`。 |

其余 `INCLUDE_*` 宏控制对应 API 是否编译进内核。关闭未使用的 API 主要节省 Flash，不应为了省少量空间而关闭应用实际依赖的接口：

| 宏定义 | 默认值 | 对应能力 |
|--------|--------|----------|
| `INCLUDE_vTaskPrioritySet` | `1` | 运行时修改任务优先级。 |
| `INCLUDE_uxTaskPriorityGet` | `1` | 查询任务优先级。 |
| `INCLUDE_vTaskDelete` | `1` | 删除任务；关闭后任务不能自删除或删除其他任务。 |
| `INCLUDE_vTaskCleanUpResources` | `0` | 兼容旧 port 的任务资源清理接口，现代 Cortex-M port 通常不需要。 |
| `INCLUDE_vTaskSuspend` | `1` | 挂起/恢复任务；`portMAX_DELAY` 的无限等待语义也可能依赖它。 |
| `INCLUDE_vTaskDelayUntil` | `1` | 周期任务使用的绝对延时 API。 |
| `INCLUDE_vTaskDelay` | `1` | 相对延时 API。 |
| `INCLUDE_xTaskGetSchedulerState` | `1` | 查询调度器尚未启动、运行或挂起状态。 |
| `INCLUDE_xQueueGetMutexHolder` | `1` | 查询互斥量当前持有者。 |
| `INCLUDE_uxTaskGetStackHighWaterMark` | `1` | 查询任务历史最小剩余栈空间，是调整任务栈的重要依据。 |
| `INCLUDE_xTaskGetCurrentTaskHandle` | `1` | 获取当前任务句柄。 |
| `INCLUDE_eTaskGetState` | `1` | 查询指定任务状态。 |

### 中断和处理器特性

| 宏定义 | 默认值 | 意义及调整原则 |
|--------|--------|----------------|
| `configENABLE_FPU` | 自动 | 根据 CMSIS 的 `__FPU_USED` 判断。它不能替代正确的编译器 FPU/ABI 参数；使用浮点的任务还会增加上下文和栈开销。 |
| `configENABLE_MVE` | 自动 | 根据编译器的 `__ARM_FEATURE_MVE` 判断，主要用于支持 MVE 的 Cortex-M55/M85。 |
| `configENABLE_MPU` | `0` | 是否使用 FreeRTOS MPU port，是应用安全策略，不应只因 MCU 存在 MPU 就自动开启。 |
| `configENABLE_TRUSTZONE` | `0` | ARMv8-M TrustZone 支持，必须与 Secure/Non-secure 工程划分和 port 选择一致。 |
| `configRUN_FREERTOS_SECURE_ONLY` | `0` | 是否仅在 Secure 状态运行 FreeRTOS，只适用于对应 ARMv8-M 架构。 |
| `configPRIO_BITS` | `__NVIC_PRIO_BITS` | CMSIS 提供的 NVIC 有效优先级位数。模板不再为具体 STM32 系列硬编码。 |
| `configLIBRARY_LOWEST_INTERRUPT_PRIORITY` | 自动 | CMSIS 数值形式的最低中断优先级，即 `(1 << configPRIO_BITS) - 1`。 |
| `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` | 自动为 `1` 或 `5` | 允许调用 FreeRTOS `FromISR` API 的最高紧迫度边界；数值越小，中断紧迫度越高。必须非零且在 NVIC 范围内。 |
| `configKERNEL_INTERRUPT_PRIORITY` | 自动 | 写入寄存器格式的 SysTick/PendSV 最低优先级，由上面的 CMSIS 数值左移计算。 |
| `configMAX_SYSCALL_INTERRUPT_PRIORITY` | 自动 | 写入寄存器格式的 syscall 中断阈值，由 `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` 左移计算。 |

调用 FreeRTOS `FromISR` API 的中断，其 CMSIS 优先级数值必须大于或等于 `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY`；数值更小、紧迫度更高的中断不能调用 FreeRTOS API。模板会检查阈值是否为零或超出 NVIC 范围，但无法替应用决定每个外设中断的优先级。

`vPortSVCHandler`、`xPortPendSVHandler` 和 `xPortSysTickHandler` 分别映射到 CMSIS 启动文件使用的 `SVC_Handler`、`PendSV_Handler` 和 `SysTick_Handler`。工程中不能再定义另一套同名处理函数，否则会重复定义或绕过 FreeRTOS port。

### 按 SRAM 容量选择起始配置

下表是用于首次配置和容量评估的起始区间，不是保证值。同一系列的不同完整料号可能有不同 SRAM 容量；应优先查看具体芯片数据手册，以及 CubeMX 生成的链接脚本 `MEMORY` 段。表中的 heap 范围假设使用 `heap_4`、少量任务且没有大型协议栈或图形缓冲区。

| 可用 SRAM | 典型型号举例 | FreeRTOS heap 起始值 | `configMAX_PRIORITIES` | 建议功能基线 |
|-----------|--------------|----------------------|-----------------------|--------------|
| 2–4 KB | 部分 STM32L0；STM32F030F4 为 4 KB | `512–1024 B` | `4` | Timer/trace/registry 全关，优先静态创建；HAL、RTT 与 FreeRTOS 同时使用可能无法容纳 |
| 6–10 KB | STM32F042x6、STM32F103C4 为 6 KB；STM32F103C6 为 10 KB | `1 KB` | `4–8` | 保持模板默认功能，只创建少量简单任务 |
| 16–20 KB | 常见 STM32F072xB 为 16 KB；STM32F103C8/CB 为 20 KB | `2–4 KB` | `8` | Timer 按需开启，逐个测量任务栈 |
| 32–64 KB | STM32F091/部分 G0 为 32 KB；STM32F103RC 为 48 KB；STM32F103RE 为 64 KB | `4–16 KB` | `8–16` | 可启用 Timer/trace 调试，但仍需保留外设缓冲区空间 |
| 96–192 KB | STM32F103RG 为 96 KB；部分 F4/L4 为 128 KB；STM32F407 合计约 192 KB | `16–48 KB` | `8–16` | 根据任务和中间件增加 heap；确认 CCM/主 SRAM 的实际放置位置 |
| 256–512 KB | 部分 STM32F7、G4、L4+ | `32–128 KB` | `16–32` | 为网络、文件系统和 DMA 缓冲区单独预算，不要全部划给 FreeRTOS heap |
| 640 KB–1 MB | 部分 STM32H7 | `64–256 KB` | `16–32` | 明确 DTCM、AXI SRAM 和各 D-domain 的用途及 cache/DMA 约束 |
| 1 MB 以上 | 高端 STM32H7、STM32N6 等 | 按内存域和对象类型规划 | 按任务模型设置 | 考虑 `heap_5`、多内存池或专用分配器，不建议只扩大单一 `ucHeap[]` |

对于 2–4 KB SRAM 的器件，表中的值仍可能过大：Idle 栈、应用任务栈、TCB、HAL 状态、`.data/.bss`、中断主栈和调试缓冲区都需要空间。这类器件应先判断 FreeRTOS 是否确有必要，再考虑将 `configMINIMAL_STACK_SIZE` 降到 `64–96 words`；任何降低都必须通过栈高水位和最坏中断嵌套验证，不能仅以“能够链接”为依据。

STM32F4/F7/H7/N6 的“总 SRAM”经常由多个不连续内存域组成。例如 CCM/DTCM 可能不能被某些 DMA 访问，AXI SRAM 又可能涉及 cache 一致性。使用 `heap_4` 时，`ucHeap[]` 只会位于链接脚本选择的一段内存；总容量较大并不意味着这些 RAM 能被一个 heap 自动合并。需要跨多个不连续区域时应评估 `heap_5`，并检查每个区域的 CPU、DMA 和 cache 属性。

### 调整和验证步骤

1. 从芯片数据手册和链接脚本 `MEMORY` 段确认当前构建真正可用的 RAM，而不是只看产品系列宣传的总容量。
2. 从 `.map` 文件统计 `.data`、`.bss`、FreeRTOS heap、静态任务栈、RTT/协议栈缓冲区以及链接脚本保留的 C heap/主栈。
3. 动态任务的预算至少包含 `stack depth × sizeof(StackType_t)`、TCB 和 heap 管理开销；队列还要包含控制块及 `队列长度 × 单项大小`。在估算结果上保留余量，不要让链接结果刚好贴近 RAM 上限。
4. 运行压力最大的业务路径，使用 `uxTaskGetStackHighWaterMark()` 检查每个任务的历史最小剩余栈，使用 `xPortGetFreeHeapSize()` 和 `xPortGetMinimumEverFreeHeapSize()` 检查当前及历史最小剩余 heap。
5. 为 `xTaskCreate()`、队列/信号量创建等动态分配结果增加失败处理。链接成功只证明静态布局能够放入 RAM，不代表运行期间一定不会耗尽 heap 或任务栈。

---

# 常见问题

1. Q: 编译报错 `Unsupported FREERTOS_PORT 'xxx'`
A: 检查 `FREERTOS_PORT` 的值是否拼写正确，Make 和 CMake 都必须使用上方表格中的完整官方名称，例如 `GCC_ARM_CM4F`。

2. Q: 编译报错 `FreeRTOSConfig.h: No such file or directory`
A: 执行 `make rtos_init` 从模板创建配置文件，或手动将 `FreeRTOSConfig.h` 放到项目根目录。

3. Q: 运行后进入 HardFault
A: 先定位发生故障的任务并检查 `uxTaskGetStackHighWaterMark()`。普通任务应增大其 `xTaskCreate()`/`xTaskCreateStatic()` stack depth；只有 Idle 任务不足时才调整 `configMINIMAL_STACK_SIZE`。同时检查中断优先级、数组越界和无效指针。

4. Q: CMake 构建时提示找不到 FreeRTOS-Kernel
A: 确保已执行 `make rtos_clone`，或在 `FreeRTOS_port` 目录执行 `git submodule update --init FreeRTOS-Kernel`。本项目不需要递归初始化 FreeRTOS-Kernel 中的 ThirdParty 子模块。

5. Q: 链接时报错 `region 'RAM' overflowed`
A: 从 `.map` 文件确认 `.data/.bss` 的主要占用者，重点检查 `configTOTAL_HEAP_SIZE`、静态任务栈、`configMAX_PRIORITIES`、Timer 任务、RTT/协议栈缓冲区，以及链接脚本中的 `_Min_Heap_Size` 和 `_Min_Stack_Size`。不要只缩小某一个值后停止验证，应按本章的容量表重新做完整 RAM 预算。

---

# 测试状态

| FreeRTOS 版本 | MCU | 构建系统 | 状态 |
|--------------|-----|---------|------|
| V11.3.0 | STM32F411CEU6 | Make | ✅ |
| V11.3.0 | STM32F411CEU6 | CMake | ✅ |

以上两项为任务创建、调度、延时和 RTT 日志输出的实际运行验证。

模板还完成了以下编译检查，这些检查不等同于对应开发板的实机运行验证：

| MCU 工程参数 | FreeRTOS port | 检查范围 | 状态 |
|-------------|---------------|----------|------|
| STM32F042x6 | `GCC_ARM_CM0` | 6 KB RAM、HAL、RTT、单任务和完整 GNU Make 链接 | 通过 |
| STM32F103xB | `GCC_ARM_CM3` | 公共内核、heap、回调和 `port.c` | 通过 |
| STM32F411xE | `GCC_ARM_CM4F` | 公共内核、heap、回调、`port.c` 和最小 Cube-CMake 集成 | 通过 |
| STM32H7B0xx | `GCC_ARM_CM7` | 公共内核、heap、回调和 `ARM_CM7/r0p1/port.c` | 通过 |

**实机验证环境**：
macOS 12.2.1 (M1)
GNU Make: ARM GNU Toolchain 12.2.rel1
CMake: STM32 VSCode 插件 4.2.3+st.1

**模板编译检查工具**：
GNU Arm Embedded Toolchain 9.3.1
CMake 4.1.2（最小 Cube-CMake 集成检查）

# 修订记录
| 文档版本 | 修订时间 | 修改内容 | 备注 |
|--|--|--|--|
|2.0.0|2026/07/28|同步通用配置模板、构建接口、端口映射和验证文档|对应 11.3.0-2.0.0|
|1.0.0|2026/04/04|创建文档,并对工程进行了描述||

---

# 更新记录
版本格式为 `<FreeRTOS-Kernel 版本>-<移植层版本>`。前半部分跟随 FreeRTOS-Kernel tag，后半部分遵循语义化版本。由于 2.0.0 统一了 Make/CMake 参数名且不兼容旧的 `CFG_*` 配置，因此提升移植层主版本号。

## [11.3.0-2.0.0] - 2026-07-28

### Breaking Changes

- Make 和 CMake 统一使用 `FREERTOS_PORT`、`FREERTOS_HEAP`。
- `FREERTOS_PORT` 统一使用官方完整名称，例如 `GCC_ARM_CM4F`。
- 不再兼容旧的 `CFG_CORE`、`CFG_HEAP`。

### Added

- 新增独立的 `templates/FreeRTOSConfig.h` 通用配置模板。
- 自动获取 CMSIS NVIC 位数，根据有效范围选择默认中断优先级，并检测 FPU 和 MVE 配置。
- 增加 Make 参数及辅助目标校验。
- 增加 Cortex-M0/M3/M4/M7/M33/M55 port 映射。

### Fixed

- 修复 Cortex-M7、MPU 和 TrustZone port 源文件映射。
- 适配 FreeRTOS V11.3.0 静态内存回调接口，并按配置启用相关回调。
- 修复 `CMakeLists.txt` 文件名大小写。
- 修正回调源码的版权和许可证说明。

### Changed

- CMake 配置继承 `stm32cubemx` 的 include 路径和 MCU 宏。
- `FreeRTOSConfig.h` 改为从独立模板复制，且不覆盖已有配置文件。
- 配置模板改用适合小容量 STM32 的保守内存基线，并默认关闭 Timer、trace 和 queue registry。
- `rtos_clone` 只初始化项目依赖的一级 `FreeRTOS-Kernel` 子模块，避免拉取无关的 ThirdParty port 仓库。
- README 细化全部模板参数的意义，并增加按 SRAM 容量选择 heap、任务栈和可选功能的起始配置及验证方法。
- README 区分源码映射检查、编译检查和实机验证。

## [11.3.0-1.0.0] - 2026-04-04

### Added

- 创建工程，完成对 FreeRTOS-Kernel V11.3.0 的适配。

---
