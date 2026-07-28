/*
 * FreeRTOS Kernel V11.3.0
 * Copyright (C) 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * https://www.FreeRTOS.org
 * https://github.com/FreeRTOS
 */

#ifndef FREERTOS_CONFIG_H
#define FREERTOS_CONFIG_H

/*
 * Default FreeRTOS configuration for STM32CubeMX projects.
 *
 * This template is copied to the project root as FreeRTOSConfig.h. Review the
 * memory, timing, interrupt, MPU, and TrustZone settings for each application.
 */

#include "main.h"

#include <stddef.h>
#include <stdint.h>

extern uint32_t SystemCoreClock;

/* Hardware properties supplied by the compiler and the CMSIS device header. */
#ifndef __NVIC_PRIO_BITS
    #error "main.h must include a CMSIS device header that defines __NVIC_PRIO_BITS"
#endif

#ifndef configENABLE_FPU
    #if defined( __FPU_USED ) && ( __FPU_USED == 1U )
        #define configENABLE_FPU    1
    #else
        #define configENABLE_FPU    0
    #endif
#endif

#ifndef configENABLE_MVE
    #if defined( __ARM_FEATURE_MVE ) && ( __ARM_FEATURE_MVE != 0 )
        #define configENABLE_MVE    1
    #else
        #define configENABLE_MVE    0
    #endif
#endif

/* MPU and TrustZone are application policies, not hardware-presence checks. */
#ifndef configENABLE_MPU
    #define configENABLE_MPU    0
#endif

#ifndef configENABLE_TRUSTZONE
    #define configENABLE_TRUSTZONE    0
#endif

#ifndef configRUN_FREERTOS_SECURE_ONLY
    #define configRUN_FREERTOS_SECURE_ONLY    0
#endif

#define configUSE_PREEMPTION                     1
#define configSUPPORT_STATIC_ALLOCATION          1
#define configSUPPORT_DYNAMIC_ALLOCATION         1
#define configUSE_IDLE_HOOK                      0
#define configUSE_TICK_HOOK                      0
#define configCPU_CLOCK_HZ                       ( SystemCoreClock )
#define configTICK_RATE_HZ                       1000U
#define configMAX_PRIORITIES                     56U
#define configMINIMAL_STACK_SIZE                 ( ( uint16_t ) 128U )
#define configTOTAL_HEAP_SIZE                    ( ( size_t ) 15360U )
#define configMAX_TASK_NAME_LEN                  16U
#define configUSE_TRACE_FACILITY                 1
#define configTICK_TYPE_WIDTH_IN_BITS            TICK_TYPE_WIDTH_32_BITS
#define configUSE_MUTEXES                        1
#define configQUEUE_REGISTRY_SIZE                8U
#define configUSE_RECURSIVE_MUTEXES              1
#define configUSE_COUNTING_SEMAPHORES            1
#define configUSE_PORT_OPTIMISED_TASK_SELECTION  0
#define configMESSAGE_BUFFER_LENGTH_TYPE         size_t

/* Co-routine definitions. */
#define configUSE_CO_ROUTINES                    0
#define configMAX_CO_ROUTINE_PRIORITIES          2U

/* Software timer definitions. */
#define configUSE_TIMERS                         1
#define configTIMER_TASK_PRIORITY                2U
#define configTIMER_QUEUE_LENGTH                 10U
#define configTIMER_TASK_STACK_DEPTH             256U

/* Optional API functions. */
#define INCLUDE_vTaskPrioritySet                 1
#define INCLUDE_uxTaskPriorityGet                1
#define INCLUDE_vTaskDelete                      1
#define INCLUDE_vTaskCleanUpResources            0
#define INCLUDE_vTaskSuspend                     1
#define INCLUDE_vTaskDelayUntil                  1
#define INCLUDE_vTaskDelay                       1
#define INCLUDE_xTaskGetSchedulerState           1
#define INCLUDE_xTimerPendFunctionCall           1
#define INCLUDE_xQueueGetMutexHolder             1
#define INCLUDE_uxTaskGetStackHighWaterMark      1
#define INCLUDE_xTaskGetCurrentTaskHandle        1
#define INCLUDE_eTaskGetState                    1

/* Cortex-M interrupt priority configuration. */
#define configPRIO_BITS                          __NVIC_PRIO_BITS
#define configLIBRARY_LOWEST_INTERRUPT_PRIORITY  ( ( 1U << configPRIO_BITS ) - 1U )

#ifndef configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY
    #define configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY    5U
#endif

#if ( configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY == 0U )
    #error "configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY must not be zero"
#endif

#if ( configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY > configLIBRARY_LOWEST_INTERRUPT_PRIORITY )
    #error "configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY exceeds the CMSIS priority range"
#endif

#define configKERNEL_INTERRUPT_PRIORITY      \
    ( configLIBRARY_LOWEST_INTERRUPT_PRIORITY << ( 8U - configPRIO_BITS ) )
#define configMAX_SYSCALL_INTERRUPT_PRIORITY \
    ( configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY << ( 8U - configPRIO_BITS ) )

/*
 * MPU wrappers v2 additionally require application-specific values for
 * configSYSTEM_CALL_STACK_SIZE and configPROTECTED_KERNEL_OBJECT_POOL_SIZE.
 */

#define configASSERT( x )                       \
    do                                          \
    {                                           \
        if( ( x ) == 0 )                        \
        {                                       \
            taskDISABLE_INTERRUPTS();           \
            for( ; ; )                          \
            {                                   \
            }                                   \
        }                                       \
    } while( 0 )

/* Map the FreeRTOS handlers to the CMSIS vector names. */
#define vPortSVCHandler        SVC_Handler
#define xPortPendSVHandler     PendSV_Handler
#define xPortSysTickHandler    SysTick_Handler

#endif /* FREERTOS_CONFIG_H */
