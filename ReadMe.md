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
- [常见问题](#常见问题)
- [测试状态](#测试状态)
- [修订记录](#修订记录)
- [更新记录](#更新记录)
  - [\[11.3.0-1.0.0\] - 2026-04-04](#1130-100---2026-04-04)
    - [Added](#added)

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

`make rtos_init` 从 `FreeRTOS_port/templates/FreeRTOSConfig.h` 创建工程根目录下的 `FreeRTOSConfig.h`。模板通过 `main.h` 获取 CubeMX 的 HAL/CMSIS 设备定义；编辑工程根目录下的副本可调整以下应用参数：

| 宏定义 | 默认值 | 说明 |
|--------|--------|------|
| `configUSE_PREEMPTION` | `1` | 抢占式调度 (1=启用) |
| `configTICK_RATE_HZ` | `1000` | 系统节拍频率 (Hz) |
| `configMAX_PRIORITIES` | `56` | 最大任务优先级数 |
| `configMINIMAL_STACK_SIZE` | `128` | 空闲任务最小栈大小 (字) |
| `configTOTAL_HEAP_SIZE` | `15360` | FreeRTOS 堆大小 (字节) |
| `configTICK_TYPE_WIDTH_IN_BITS` | `TICK_TYPE_WIDTH_32_BITS` | 使用 FreeRTOS V11 的 32 位 tick 类型配置 |
| `configUSE_TIMERS` | `1` | 软件定时器 (1=启用) |
| `configUSE_MUTEXES` | `1` | 互斥量支持 |
| `configUSE_RECURSIVE_MUTEXES` | `1` | 递归互斥量 |
| `configUSE_COUNTING_SEMAPHORES` | `1` | 计数信号量 |
| `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` | `5` | 可调用 FreeRTOS ISR API 的最高中断优先级，必须在 MCU 的 NVIC 范围内 |
| `configENABLE_MPU` | `0` | ARMv8-M 的 MPU 应用策略，不根据硬件是否存在 MPU 自动开启 |
| `configENABLE_TRUSTZONE` | `0` | TrustZone 默认关闭，ARMv8-M 工程按安全架构配置 |
| `configRUN_FREERTOS_SECURE_ONLY` | `0` | 是否只在安全侧运行 FreeRTOS |
| `configENABLE_FPU` | 自动 | 根据 CMSIS 的 `__FPU_USED` 判断 |
| `configENABLE_MVE` | 自动 | 根据编译器的 `__ARM_FEATURE_MVE` 判断 |

`configPRIO_BITS` 由 CMSIS 的 `__NVIC_PRIO_BITS` 自动确定。模板会检查 `configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY` 是否为零或超出 NVIC 优先级范围；检查失败时必须根据 MCU 和应用的中断设计调整，不能删除校验。

---

# 常见问题

1. Q: 编译报错 `Unsupported FREERTOS_PORT 'xxx'`
A: 检查 `FREERTOS_PORT` 的值是否拼写正确，Make 和 CMake 都必须使用上方表格中的完整官方名称，例如 `GCC_ARM_CM4F`。

2. Q: 编译报错 `FreeRTOSConfig.h: No such file or directory`
A: 执行 `make rtos_init` 从模板创建配置文件，或手动将 `FreeRTOSConfig.h` 放到项目根目录。

3. Q: 运行后进入 HardFault
A: 通常是栈大小不足。尝试增大 `configMINIMAL_STACK_SIZE` 或检查中断优先级配置。

4. Q: CMake 构建时提示找不到 FreeRTOS-Kernel
A: 确保已执行 `git submodule update --init --recursive` 初始化子模块。

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
|1.0.0|2026/04/04|创建文档,并对工程进行了描述||

---

# 更新记录
版本直接依据所引用的FreeRTOS-Kernel的Tag,并追加先行版本号作为补充
## [11.3.0-1.0.0] - 2026-04-04
### Added
 - 创建工程,完成了对FreeRTOS-Kernel V11.3.0的适配

---
