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

本项目为STM32CubeMX生成的工程提供了一套兼容 **GNU Make** 和 **STM32 for VSCode插件的cube-CMake** 双构建系统的 FreeRTOS 移植方案，初衷是为了直接采用FreeRTOS的的源码来进行开发操作,规避STM32CubeMX生成的CMSIS层,适用于基于ARM Cortex-M 系列的 MCU。

---

# 目录结构

```
项目根目录/
├── FreeRTOS_port/
│   ├── FreeRTOS-Kernel/          # FreeRTOS 内核源码 (Git 子模块)
│   ├── freertos_callbacks.c      # 静态内存分配回调函数
│   ├── FreeRTOS.mk               # Make 构建配置
│   └── CmakeLists.txt            # CMake 构建配置
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
在主 Makefile中 `# compile gcc flags`前添加以下内容,并将占位符__TODO_REPLACE_XXXX__替换为实际值,可参考[配置参数](#用户手动配置参数参考)
```makefile
# *** FreeRTOS config ***
# Set heap implementation (heap_1...5 are supported)
CFG_HEAP = __TODO_REPLACE_HEAP__

# Set FreeRTOS port for Core 
CFG_CORE = __TODO_REPLACE_CORE__

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
以上命令会自动完成相关配置

1. 编译验证
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
以上命令会自动完成相关配置
配置工程参数:
在根目录的CMakeLists.txt中找到脚本追加的数据并替换并将占位符__TODO_REPLACE_XXXX__替换为实际值,可参考[配置参数](#用户手动配置参数参考)

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

移植时只需要根据Make / Cmake修改 **两个参数**：

1. `CFG_CORE` / `__TODO_REPLACE_CORE__`

指定你的 MCU 对应的 FreeRTOS port 目录。

| CFG_CORE (Make) | FREERTOS_PORT (CMake) | 适用芯片 | 额外说明 |
|-----------------|----------------------|---------|---------|
| `ARM_CM0` | `GCC_ARM_CM0` | Cortex-M0 / M0+ | 需要额外 `mpu_wrappers_v2_asm.c`, `portasm.c`已适配 |
| `ARM_CM3` | `GCC_ARM_CM3` | Cortex-M3 | |
| `ARM_CM3_MPU` | `GCC_ARM_CM3_MPU` | Cortex-M3 (带 MPU) | 需要额外 `mpu_wrappers_v2_asm.c`已适配 |
| `ARM_CM4F` | `GCC_ARM_CM4F` | Cortex-M4 (带 FPU) | **最常用**，如 STM32F4xx |
| `ARM_CM4_MPU` | `GCC_ARM_CM4_MPU` | Cortex-M4 (带 MPU) | 需要额外 `mpu_wrappers_v2_asm.c`已适配 |
| `ARM_CM7` | `GCC_ARM_CM7` | Cortex-M7 | 复用 `ARM_CM4F` 的 port |
| `ARM_CM33_SECURE` | `GCC_ARM_CM33` (secure) | Cortex-M33 (TrustZone 安全侧) | 需要额外 secure 相关文件,已适配 |
| `ARM_CM33_NONSECURE` | `GCC_ARM_CM33` (non_secure) | Cortex-M33 (TrustZone 非安全侧) | 需要额外 `portasm.c`, `mpu_wrappers_v2_asm.c`已适配 |
| `ARM_CM33_NTZ_NONSECUR` | `GCC_ARM_CM33_NTZ` (non_secure) | Cortex-M33 (无 TrustZone),已适配 | |
| `ARM_CM55_NONSECURE` | `GCC_ARM_CM55` (non_secure) | Cortex-M55 (TrustZone 非安全侧),已适配 | |
| `ARM_CM55_SECURE` | `GCC_ARM_CM55` (secure) | Cortex-M55 (TrustZone 安全侧) | 需要额外 secure 相关文件,已适配 |
| `ARM_CM55_NTZ_NONSECURE` | `GCC_ARM_CM55_NTZ` (non_secure) | Cortex-M55 (无 TrustZone),已适配 | |

> **常见选型参考**：
> - STM32F1xx → `ARM_CM3`
> - STM32F4xx / STM32G4xx → `ARM_CM4F`
> - STM32F7xx (带 FPU) → `ARM_CM7`
> - STM32L0xx → `ARM_CM0`
> - STM32U5xx → `ARM_CM33_NONSECURE` 或 `ARM_CM33_SECURE`

2. `CFG_HEAP` / `__TODO_REPLACE_HEAP__`

指定 FreeRTOS 堆管理策略。

| 值 | 名称 | 特点 | 推荐场景 |
|----|------|------|---------|
| `1` | `heap_1` | 只分配，不释放 | 极简应用，创建后不删除任务 |
| `2` | `heap_2` | 可分配和释放，但不合并碎片 | 固定大小内存块 |
| `3` | `heap_3` | 封装标准库 `malloc`/`free` | 线程安全要求简单 |
| `4` | `heap_4` | 可分配释放，**自动合并碎片** | **最常用，推荐** |
| `5` | `heap_5` | 同 `heap_4`，支持多个不连续内存区 | 分散 RAM 的复杂系统 |

> **默认推荐**：`CFG_HEAP = 4` / `set(FREERTOS_HEAP 4 ...)`

---

## FreeRTOSConfig.h 关键配置项

编辑项目根目录下的 `FreeRTOSConfig.h` 可调整以下参数：

| 宏定义 | 默认值 | 说明 |
|--------|--------|------|
| `configUSE_PREEMPTION` | `1` | 抢占式调度 (1=启用) |
| `configTICK_RATE_HZ` | `1000` | 系统节拍频率 (Hz) |
| `configMAX_PRIORITIES` | `56` | 最大任务优先级数 |
| `configMINIMAL_STACK_SIZE` | `128` | 空闲任务最小栈大小 (字) |
| `configTOTAL_HEAP_SIZE` | `15360` | FreeRTOS 堆大小 (字节) |
| `configUSE_TIMERS` | `1` | 软件定时器 (1=启用) |
| `configUSE_MUTEXES` | `1` | 互斥量支持 |
| `configUSE_RECURSIVE_MUTEXES` | `1` | 递归互斥量 |
| `configUSE_COUNTING_SEMAPHORES` | `1` | 计数信号量 |

---

# 常见问题

1. Q: 编译报错 `Unknown CFG_CORE: xxx`
A: 检查 `CFG_CORE` 的值是否拼写正确，参考上方参数对照表。

2. Q: 编译报错 `FreeRTOSConfig.h: No such file or directory`
A: 执行 `make rtos_init` 生成配置文件，或手动将 `FreeRTOSConfig.h` 放到项目根目录。

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

**测试环境**: 
macOS 12.2.1 (M1)
GNU Make: ARM GNU Toolchain 12.2.rel1
Cmake :STM32 VSCode插件 4.2.3+st.1

所有版本均已通过基本功能验证(任务创建/调度/延时, RTT日志输出)。

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
