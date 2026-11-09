# `jetleaf_mcp`: Architectural Specification & Implementation Roadmap

> **Model Context Protocol (MCP) Integration for the Jetleaf Framework**  
> Status: Canonical Production Specification  
> Package: `packages/jetleaf_mcp`  
> Author: Evaristus Adimonyemma & Jetleaf Architecture Team  
> Target Ecosystem: Claude Desktop, Cursor, Windsurf, Antigravity, Copilot, Custom Agent Runtimes

---

## 1. Executive Summary & Mission Statement

### 1.1 The Objective
The mission of `jetleaf_mcp` is to turn Jetleaf into the **#1 AI-native backend framework for Dart**. 

By implementing the open **Model Context Protocol (MCP)** specification (JSON-RPC 2.0 over `stdio` and `SSE`), `jetleaf_mcp` exposes Jetleaf's internal AST scanners, dependency injection container, route registry, resident compiler daemon (`JetleafVM`), and test harnesses directly to frontier LLMs. 

This enables **"vibecoders"** (developers building full production systems using natural language prompts) and enterprise engineering teams to:
1. **Scaffold complete backend architectures** (Controllers, Pods, Repositories, Entities) with zero manual syntax errors.
2. **Inspect live server topology** (route tables, loaded beans, memory consumption, actuator health metrics).
3. **Run autonomous self-healing loops**: When an AI agent modifies code, `jetleaf_mcp` triggers the resident `jl dev` VM, captures compilation errors or failed `@JetleafTest` assertions, feeds structured diagnostics back to the LLM, and lets the agent auto-correct the code until 100% of tests pass.

### 1.2 Separation of Concerns & Pluggability
To prevent coupling to any specific LLM provider or IDE client, `jetleaf_mcp` is built on three strict design principles:
- **Protocol Independence**: The MCP transport layer is decoupled from the tool logic. Developers can serve over standard I/O (`stdio` for Cursor/Claude Desktop) or Server-Sent Events (`SSE` for remote web-based agents).
- **Extensible Tool Registry**: Every tool is an isolated `McpToolHandler`. Developers can register custom project-specific tools or override existing scaffolding handlers.
- **AST & VM Isolation**: Tool execution communicates with the Jetleaf compiler and runtime via well-defined sockets and state files (`.jetleaf/vm/state.json`), ensuring tool calls never crash the user's running application.

---

## 2. System Architecture & Component Decomposition

```
┌────────────────────────────────────────────────────────────────────────┐
│                          AI AGENT CLIENTS                              │
│         (Cursor, Windsurf, Claude Desktop, Antigravity CLI)            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ JSON-RPC 2.0 (stdio / SSE)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       JETLEAF MCP SERVER LAYER                         │
├───────────────────────────────────┬────────────────────────────────────┤
│           Transport Layer         │         Protocol Engine            │
│  - StdioTransport (Local)         │  - McpJsonRpcHandler               │
│  - SseTransport (Remote/Cloud)    │  - Request Router & Serializer     │
├───────────────────────────────────┴────────────────────────────────────┤
│                       MCP CAPABILITY PROVIDERS                         │
├───────────────────────┬────────────────────────┬───────────────────────┤
│    Tools Provider     │   Resources Provider   │    Prompts Provider   │
│ - Scaffolding Tools   │ - Live Route Registry  │ - Backend Generator   │
│ - Diagnostics Tools   │ - Pod Dependency Graph │ - Migration Assistant │
│ - Testing / VM Tools  │ - Actuator Metrics     │ - Test Suite Builder  │
└───────────────────────┴────────────────────────┴───────────────────────┘
                                    │ Local Socket / AST Scanner / State I/O
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   JETLEAF CORE & RESIDENT TOOLING                      │
│     (jetleaf_core, jetleaf_tools, jl dev resident VM daemon)           │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Package File Structure (`packages/jetleaf_mcp`)

```text
packages/jetleaf_mcp/
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── bin/
│   └── jetleaf_mcp.dart                  # Executable entry point for stdio/SSE
├── lib/
│   ├── jetleaf_mcp.dart                  # Public library exports
│   └── src/
│       ├── protocol/                     # MCP JSON-RPC protocol primitives
│       │   ├── mcp_message.dart
│       │   ├── mcp_request.dart
│       │   ├── mcp_response.dart
│       │   ├── mcp_error.dart
│       │   └── json_rpc_parser.dart
│       ├── transport/                    # Transport layer abstraction
│       │   ├── mcp_transport.dart
│       │   ├── stdio_transport.dart
│       │   └── sse_transport.dart
│       ├── server/                       # Core MCP server orchestrator
│       │   ├── mcp_server.dart
│       │   ├── mcp_server_config.dart
│       │   └── client_session.dart
│       ├── tools/                        # Tool definitions & handlers
│       │   ├── mcp_tool.dart             # Abstract tool interface
│       │   ├── tool_registry.dart        # Pluggable tool registry
│       │   ├── scaffold/                 # Generation tools
│       │   │   ├── project_scaffold_tool.dart
│       │   │   ├── controller_scaffold_tool.dart
│       │   │   ├── pod_scaffold_tool.dart
│       │   │   └── repository_scaffold_tool.dart
│       │   ├── introspection/            # Live state inspection
│       │   │   ├── inspect_routes_tool.dart
│       │   │   ├── inspect_pods_tool.dart
│       │   │   └── inspect_actuator_tool.dart
│       │   └── diagnostics/              # VM compilation & testing tools
│       │       ├── run_tests_tool.dart
│       │       ├── diagnose_errors_tool.dart
│       │       └── trigger_hot_reload_tool.dart
│       ├── resources/                    # MCP Live Resources
│       │   ├── mcp_resource.dart
│       │   ├── resource_registry.dart
│       │   ├── route_table_resource.dart
│       │   ├── pod_graph_resource.dart
│       │   └── system_health_resource.dart
│       ├── prompts/                      # Pre-engineered prompts for vibecoders
│       │   ├── mcp_prompt.dart
│       │   ├── prompt_registry.dart
│       │   └── templates/
│       │       ├── scaffold_microservice_prompt.dart
│       │       └── fix_test_failure_prompt.dart
│       └── vm_bridge/                    # Bridge to jl dev daemon & AST
│           ├── vm_state_reader.dart
│           ├── vm_socket_client.dart
│           └── ast_project_scanner.dart
└── test/
    ├── protocol/
    │   └── json_rpc_parser_test.dart
    ├── tools/
    │   ├── controller_scaffold_tool_test.dart
    │   └── run_tests_tool_test.dart
    └── server/
        └── mcp_server_test.dart
```

---

## 4. Core Abstractions & Interfaces

### 4.1 The Transport Abstraction
To ensure Jetleaf MCP can run locally over `stdin`/`stdout` or inside cloud environments (Docker/Kubernetes) over `HTTP`/`SSE`:

```dart
abstract interface class McpTransport {
  /// Starts listening for incoming JSON-RPC messages.
  Stream<McpRequest> get incomingRequests;

  /// Sends a JSON-RPC response or notification to the client.
  Future<void> send(McpMessage message);

  /// Closes the transport channel.
  Future<void> close();
}
```

#### `StdioTransport` Implementation:
Reads line-delimited JSON or `Content-Length` framed JSON-RPC 2.0 payloads from `stdin` and writes formatted responses to `stdout` (with all internal debugging redirected to `stderr` to prevent protocol corruption).

### 4.2 The Extensible Tool Registry
Tools are self-describing, defining their JSON Schema input parameters and execution handler:

```dart
abstract interface class McpTool {
  /// Unique tool identifier (e.g. `jetleaf_scaffold_controller`).
  String get name;

  /// Human and LLM-readable description of what the tool accomplishes.
  String get description;

  /// JSON Schema definition for input arguments.
  Map<String, Object?> get inputSchema;

  /// Executes the tool logic and returns content blocks (text, JSON, or images).
  Future<McpToolResult> execute(
    Map<String, Object?> arguments, 
    ToolExecutionContext context,
  );
}

abstract interface class McpToolRegistry {
  void register(McpTool tool);
  void unregister(String toolName);
  McpTool? get(String toolName);
  List<McpTool> getAll();
}
```

---

## 5. Built-in MCP Tools Specification

### 5.1 `jetleaf_scaffold_controller`
Allows AI agents to generate production-ready REST controllers with validated parameters, typed responses, and constructor-injected dependencies.

* **Input Schema**:
  ```json
  {
    "type": "object",
    "required": ["name", "basePath", "endpoints"],
    "properties": {
      "name": { "type": "string", "description": "Class name, e.g. UserController" },
      "basePath": { "type": "string", "description": "Base route path, e.g. /api/v1/users" },
      "dependencies": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "type": { "type": "string" },
            "name": { "type": "string" }
          }
        }
      },
      "endpoints": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["method", "path", "handlerName"],
          "properties": {
            "method": { "enum": ["GET", "POST", "PUT", "DELETE", "PATCH"] },
            "path": { "type": "string" },
            "handlerName": { "type": "string" },
            "returnType": { "type": "string" },
            "parameters": { "type": "array" }
          }
        }
      }
    }
  }
  ```
* **Output**:
  Generates idiomatic Dart code formatted according to `dart format`, saves it to `lib/src/controllers/`, registers imports, and verifies compilation.

### 5.2 `jetleaf_inspect_routes`
Enables the LLM to inspect all currently registered HTTP endpoints across the entire application context.

* **Execution Flow**:
  1. Reads `.jetleaf/vm/state.json` or queries the resident VM socket.
  2. Inspects `RouteRegistry` from the warm isolate.
  3. Returns a structured JSON array containing HTTP method, URI template, producing/consuming MIME types, controller class, and interceptors.

### 5.3 `jetleaf_run_tests`
Enables the AI agent to drive test suites and receive actionable error logs.

* **Input Schema**:
  ```json
  {
    "type": "object",
    "properties": {
      "targetFile": { "type": "string", "description": "Optional specific test file path" },
      "all": { "type": "boolean", "default": false }
    }
  }
  ```
* **Execution Flow**:
  1. Sends a `runTest` command to the resident `JetleafVM` socket.
  2. The VM runs the `@JetleafTest` entry inside the warm isolate using `test_core` `Engine`.
  3. Returns JSON formatted result:
     ```json
     {
       "success": false,
       "passed": 14,
       "failed": 1,
       "errors": [
         {
           "testName": "User registration emits welcome email",
           "message": "Expected 'EMAIL_SENT', received 'FAILED'",
           "file": "test/services/user_service_test.dart",
           "line": 42,
           "stackTrace": "..."
         }
       ]
     }
     ```

### 5.4 `jetleaf_diagnose_errors`
Parses Dart analysis diagnostics and compiler errors in real time, pinpointing exact code offsets and offering actionable remediation hints.

---

## 6. Live MCP Resources Specification

MCP Resources allow agents to read dynamic project state as if reading virtual files:

1. `jetleaf://routes`: Exposes the live HTTP route mapping table in Markdown or JSON format.
2. `jetleaf://pods`: Exposes the live Dependency Injection graph (beans, scopes, circular dependency checks).
3. `jetleaf://actuator`: Exposes live health status, JVM/isolate memory allocation, CPU load, and thread counters from `jetleaf_actuator`.
4. `jetleaf://schema`: Exposes database entity models and SQL/NoSQL schema mappings.

---

## 7. The Vibecoder Autonomous Self-Healing Loop

The hallmark of `jetleaf_mcp` is enabling non-technical or rapid builders ("vibecoders") to build robust servers without dealing with raw stack traces:

```
[Vibecoder] "Create an endpoint that takes a payment and sends a webhook"
     │
     ▼
[AI Agent via jetleaf_mcp]
  1. Calls `jetleaf_scaffold_controller` -> writes `payment_controller.dart`
  2. Calls `jetleaf_scaffold_pod`        -> writes `payment_service.dart`
  3. Calls `jetleaf_run_tests`           -> test fails (missing API key configuration)
     │
     ▼
[Self-Healing Feedback]
  4. Agent reads structured test error from `jetleaf_run_tests`
  5. Agent automatically creates `.env` template and injects `@Value('${STRIPE_KEY}')`
  6. Agent re-invokes `jetleaf_run_tests` -> 100% Tests Pass!
     │
     ▼
[Vibecoder] "Your payment endpoint is live and fully tested."
```

---

## 8. Extensibility: Creating Custom MCP Tools

Developers can add custom tools to their Jetleaf projects. A custom tool simply implements `McpTool` and is registered in `main()` or auto-discovered via annotations:

```dart
@Pod()
final class DeployToAwsTool implements McpTool {
  @override
  String get name => 'deploy_to_aws';

  @override
  String get description => 'Deploys the current Jetleaf backend to AWS ECS Fargate';

  @override
  Map<String, Object?> get inputSchema => {
    'type': 'object',
    'required': ['environment'],
    'properties': {
      'environment': { 'type': 'string', 'enum': ['staging', 'production'] }
    }
  };

  @override
  Future<McpToolResult> execute(Map<String, Object?> arguments, ToolExecutionContext context) async {
    final env = arguments['environment'] as String;
    // Custom enterprise deployment logic...
    return McpToolResult.text('Successfully deployed to AWS ($env)');
  }
}
```

---

## 9. Verification & Testing Strategy

1. **Protocol Unit Tests**: Validate JSON-RPC 2.0 framing, serialization, malformed input error codes (`-32700`, `-32600`), and response correlation IDs.
2. **Transport Mock Tests**: Test simulated `stdin`/`stdout` streams ensuring no stdout leakage of internal logger logs.
3. **End-to-End Client Test**: Connect Claude Desktop and Cursor via local `stdio` configuration and verify that all tools (`scaffold`, `inspect`, `run_tests`) execute cleanly in a sandbox sample project.
