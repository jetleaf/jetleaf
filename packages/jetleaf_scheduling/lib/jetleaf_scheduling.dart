// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & Jetleaf Contributors. All rights reserved.
//
// This source file is part of the Jetleaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the Jetleaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

/// ⏰ **Jetleaf Scheduling Library**
///
/// This library provides a comprehensive scheduling framework for Jetleaf
/// applications, enabling declarative and programmatic task execution
/// based on various triggers, including cron, fixed rate, fixed delay, and
/// periodic schedules.
///
/// It includes task management, execution context handling, scheduling
/// annotations, and infrastructure for building reliable scheduled operations.
///
///
/// ## 🔑 Key Concepts
///
/// ### ⚙ Core Scheduling Infrastructure
/// - `SchedulingConfiguration` — central configuration for scheduling system  
/// - `SchedulingConfigurer` — programmatic configuration of tasks and triggers  
/// - `RunnableScheduledMethod` — represents a scheduled method execution  
/// - `SchedulingAnnotationPodProcessor` — processes annotation-based scheduling
///
///
/// ### 🏗 Task Execution & Management
/// - `TaskScheduler` — primary interface for scheduling tasks  
/// - `ConcurrentTaskScheduler` — supports concurrent task execution  
/// - `ScheduledTask` / `SimpleScheduledTask` — encapsulates scheduled work  
/// - `ScheduledTaskHolder` — stores and manages scheduled tasks  
/// - `TaskExecutionContext` / `DefaultTaskExecutionContext` — runtime context for task execution  
/// - `SchedulingTaskNameGenerator` / `DefaultSchedulingTaskNameGenerator` — generates unique task names
///
///
/// ### ⏱ Triggers
/// - `Trigger` — base interface for scheduling triggers  
/// - `CronTrigger` — schedule tasks using cron expressions  
/// - `FixedRateTrigger` — run tasks at a fixed rate  
/// - `FixedDelayTrigger` — run tasks with a fixed delay after completion  
/// - `PeriodicTrigger` — run tasks at a periodic interval  
/// - `TriggerBuilder` — fluent builder for custom triggers
///
///
/// ### 📝 Annotations & Exceptions
/// - `annotations.dart` — declarative scheduling annotations for methods  
/// - `exceptions.dart` — framework exceptions related to scheduling
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to enable task scheduling in Jetleaf applications:
/// ```dart
/// import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';
///
/// @Scheduled(cron: '0 0 * * *')
/// void dailyCleanup() {
///   // task code
/// }
/// ```
///
/// Supports both annotation-driven scheduling and programmatic task registration,
/// with extensible triggers and execution contexts.
///
///
/// © 2025 Hapnium & Jetleaf Contributors
library;

// Core scheduling infrastructure and configuration
export 'src/scheduling_configuration.dart';
export 'src/scheduling_configurer.dart';
export 'src/runnable_scheduled_method.dart';
export 'src/scheduling_annotation_pod_procesor.dart';

// Task execution and management components
export 'src/task/concurrent_task_scheduler.dart';
export 'src/task/default_scheduling_task_name_generator.dart';
export 'src/task/default_task_execution_context.dart';
export 'src/task/scheduled_task.dart';
export 'src/task/scheduled_task_holder.dart';
export 'src/task/scheduling_task_name_generator.dart';
export 'src/task/simple_scheduled_task.dart';
export 'src/task/task_execution_context.dart';
export 'src/task/task_scheduler.dart';

// Trigger implementations for various scheduling patterns
export 'src/trigger/cron_trigger.dart';
export 'src/trigger/fixed_delay_trigger.dart';
export 'src/trigger/fixed_rate_trigger.dart';
export 'src/trigger/periodic_trigger.dart';
export 'src/trigger/trigger.dart';
export 'src/trigger/trigger_builder.dart';

// Annotations and exception types
export 'src/annotations.dart';
export 'src/exceptions.dart';