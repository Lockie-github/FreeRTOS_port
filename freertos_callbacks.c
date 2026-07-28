/*
 * FreeRTOS application callbacks.
 *
 * Derived from CMSIS-FreeRTOS cmsis_os2.c.
 * Copyright (c) 2013-2020 Arm Limited. All rights reserved.
 * Modifications Copyright (c) 2026 Lockie.
 *
 * SPDX-License-Identifier: Apache-2.0
 * See LICENSES/Apache-2.0.txt for the full license text.
 */

/* Includes ------------------------------------------------------------------*/
#include "FreeRTOS.h"
#include "task.h"

/* Private functions ---------------------------------------------------------*/

#if (configSUPPORT_STATIC_ALLOCATION == 1) && \
    (configKERNEL_PROVIDED_STATIC_MEMORY == 0)

/**
  * @brief  Memory allocation callback for Idle Task
  * @note   Required when configSUPPORT_STATIC_ALLOCATION is set to 1
  * @param  ppxIdleTaskTCBBuffer: Pointer to Idle Task TCB buffer
  * @param  ppxIdleTaskStackBuffer: Pointer to Idle Task stack buffer
  * @param  puxIdleTaskStackSize: Pointer to Idle Task stack size
  * @retval None
  */
void vApplicationGetIdleTaskMemory(StaticTask_t **ppxIdleTaskTCBBuffer,
                                    StackType_t **ppxIdleTaskStackBuffer,
                                    configSTACK_DEPTH_TYPE *puxIdleTaskStackSize)
{
  static StaticTask_t xIdleTaskTCB;
  static StackType_t uxIdleTaskStack[configMINIMAL_STACK_SIZE];

  *ppxIdleTaskTCBBuffer = &xIdleTaskTCB;
  *ppxIdleTaskStackBuffer = uxIdleTaskStack;
  *puxIdleTaskStackSize = configMINIMAL_STACK_SIZE;
}

#if (configUSE_TIMERS == 1)

/**
  * @brief  Memory allocation callback for Timer Task
  * @note   Required when configSUPPORT_STATIC_ALLOCATION is set to 1
  * @param  ppxTimerTaskTCBBuffer: Pointer to Timer Task TCB buffer
  * @param  ppxTimerTaskStackBuffer: Pointer to Timer Task stack buffer
  * @param  puxTimerTaskStackSize: Pointer to Timer Task stack size
  * @retval None
  */
void vApplicationGetTimerTaskMemory(StaticTask_t **ppxTimerTaskTCBBuffer,
                                     StackType_t **ppxTimerTaskStackBuffer,
                                     configSTACK_DEPTH_TYPE *puxTimerTaskStackSize)
{
  static StaticTask_t xTimerTaskTCB;
  static StackType_t uxTimerTaskStack[configTIMER_TASK_STACK_DEPTH];

  *ppxTimerTaskTCBBuffer = &xTimerTaskTCB;
  *ppxTimerTaskStackBuffer = uxTimerTaskStack;
  *puxTimerTaskStackSize = configTIMER_TASK_STACK_DEPTH;
}

#endif /* configUSE_TIMERS */

#endif /* configSUPPORT_STATIC_ALLOCATION && !configKERNEL_PROVIDED_STATIC_MEMORY */

/**
 * @brief 
 * 
 * @param xTask 
 * @param pcTaskName 
 */
void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName)
{
    (void)xTask;
    (void)pcTaskName;  
    taskDISABLE_INTERRUPTS();
    for (;;)
    {
    }
}
