# MCP Web UI Design Pattern: Dynamic Meta Tool Architecture

## Executive Summary

This document proposes a design pattern for implementing a dynamic meta MCP (Model Context Protocol) tool architecture in the existing OpenAI-compatible chat web UI. The pattern enables the frontend to dynamically discover and interact with MCP tools while allowing for seamless handoff of chat control to backend agents for complex workflows.

## Current Architecture Analysis

The existing web UI is a React-based OpenAI-compatible chat client with:

- **Frontend**: React + TypeScript with Vite
- **Backend**: OpenAI-compatible API (`/v1/chat/completions`, `/v1/models`, etc.)
- **Message System**: Tree-structured con5. **Rollback Capability**: Checkpoint system enables safe experimentation

### Enhanced Configuration

Add to existing `CONFIG_DEFAULT`:tions with branching support

- **Storage**: Local storage for conversations and configuration
- **Real-time**: SSE (Server-Sent Events) for streaming responses

## Problem Statement

The current architecture has limitations:

1. **Static Tool Integration**: Tools must be hardcoded into the frontend
2. **Limited Backend Intelligence**: Frontend cannot leverage backend's tool discovery capabilities
3. **No Agent Handoff**: No mechanism for backend agents to control chat flow
4. **Missed Opportunities**: Cannot dynamically expose new tools or capabilities

## Proposed Solution: Dynamic Meta MCP Tool Pattern

### Core Concept

Implement a **bidirectional control pattern** where:

1. **Frontend** maintains primary control of chat completions
2. **Backend** can be queried for available MCP tools dynamically
3. **Agent handoff** mechanism allows backend to take control when needed
4. **JavaScript interface** enables rich debugging and follow-up interactions

### Architecture Components

#### 1. MCP Tool Discovery Service

```typescript
interface MCPTool {
  id: string;
  name: string;
  description: string;
  parameters: {
    type: string;
    properties: Record<string, any>;
    required?: string[];
  };
  category?: string;
  metadata?: Record<string, any>;
}

interface MCPToolResponse {
  tools: MCPTool[];
  lastUpdated: string;
  capabilities: string[];
}
```

**Implementation**:

- New endpoint: `GET /v1/mcp/tools`
- Cached in frontend with TTL refresh
- Backend scans available MCP servers and returns normalized tool definitions

#### 2. Agent Control Handoff System

```typescript
interface AgentHandoffRequest {
  type: 'agent_handoff';
  context: {
    conversationId: string;
    messageHistory: APIMessage[];
    currentMessage: string;
    availableTools: string[];
  };
  requirements: {
    maxTurns?: number;
    allowedTools?: string[];
    returnConditions: string[];
  };
}

interface AgentHandoffResponse {
  sessionId: string;
  status: 'accepted' | 'rejected';
  estimatedDuration?: number;
  nextAction: 'wait' | 'stream' | 'prompt_user';
}
```

**Flow**:

1. Frontend detects complex query requiring backend intelligence
2. Sends handoff request to `POST /v1/mcp/handoff`
3. Backend agent takes control, streams responses
4. Frontend displays "Agent is working..." with progress
5. Agent returns control with final response

#### 3. Dynamic Tool Registration

```typescript
class DynamicToolManager {
  private tools: Map<string, MCPTool> = new Map();
  private toolInvocations: Map<string, Function> = new Map();

  async refreshTools(): Promise<void> {
    const response = await fetch('/v1/mcp/tools');
    const { tools } = await response.json();
    
    tools.forEach(tool => {
      this.tools.set(tool.id, tool);
      this.registerToolInvocation(tool);
    });
  }

  private registerToolInvocation(tool: MCPTool): void {
    this.toolInvocations.set(tool.id, async (params: any) => {
      // Check if this requires agent handoff
      if (this.requiresAgentHandoff(tool, params)) {
        return this.initiateAgentHandoff(tool, params);
      }
      
      // Direct tool invocation
      return this.invokeTool(tool.id, params);
    });
  }

  private requiresAgentHandoff(tool: MCPTool, params: any): boolean {
    // Heuristics: complex tools, follow-up required, etc.
    return tool.metadata?.requiresHandoff || 
           tool.category === 'complex' ||
           params.requiresFollowup;
  }
}
```

#### 4. Enhanced Message Types

Extend the existing message system:

```typescript
// Add to existing Message interface
interface Message {
  // ...existing fields...
  agentSession?: {
    sessionId: string;
    agentId: string;
    status: 'active' | 'completed' | 'failed';
    toolsUsed: string[];
  };
  toolInvocations?: {
    toolId: string;
    parameters: any;
    result: any;
    timestamp: number;
  }[];
  debugInfo?: {
    traceId: string;
    steps: Array<{
      action: string;
      timestamp: number;
      data: any;
    }>;
  };
}
```

#### 5. JavaScript Debug Interface

```typescript
declare global {
  interface Window {
    mcpDebug: {
      getActiveSession: () => string | null;
      getToolHistory: (limit?: number) => any[];
      sendDebugMessage: (message: string) => Promise<void>;
      inspectTool: (toolId: string) => MCPTool | null;
      triggerAgentHandoff: (context: any) => Promise<string>;
      listAvailableTools: () => MCPTool[];
    };
  }
}
```

### Implementation Plan

#### Phase 1: Core Infrastructure (Week 1-2)

1. **Backend Changes**:
   - Add MCP tool discovery endpoint
   - Implement basic agent handoff mechanism
   - Create tool invocation proxy

2. **Frontend Changes**:
   - Add DynamicToolManager to app context
   - Implement tool discovery on app load
   - Basic UI for tool selection

#### Phase 2: Agent Handoff (Week 3-4)

1. **Backend**:
   - Implement session management for agent handoffs
   - Add progress reporting for long-running operations
   - Tool execution environment isolation

2. **Frontend**:
   - Agent handoff UI components
   - Progress indicators and status updates
   - Cancellation mechanisms

#### Phase 3: Enhanced UX (Week 5-6)

1. **Advanced Features**:
   - Tool suggestion system
   - Smart handoff detection
   - Debug interface implementation

2. **Polish**:
   - Error handling and recovery
   - Performance optimization
   - Documentation and examples

### API Endpoints

#### New Endpoints

```text
GET  /v1/mcp/tools
POST /v1/mcp/tools/{toolId}/invoke
POST /v1/mcp/handoff
GET  /v1/mcp/handoff/{sessionId}/status
POST /v1/mcp/handoff/{sessionId}/cancel
GET  /v1/mcp/capabilities
```

#### Enhanced Existing Endpoints

```text
POST /v1/chat/completions
- Add support for tool_choice with dynamic tools
- Agent handoff detection in system messages

GET /v1/models
- Include MCP capability flags
- Tool availability indicators
```

### UX Patterns

#### 1. Tool Discovery Flow

```text
[User opens app] 
    ↓
[Frontend queries /v1/mcp/tools]
    ↓
[Tools cached and registered]
    ↓
[Tools appear in UI suggestions]
```

#### 2. Agent Handoff Flow

```text
[User asks complex question]
    ↓
[Frontend detects complexity]
    ↓
[Shows "Let me get help from an agent" prompt]
    ↓
[User confirms handoff]
    ↓
[Agent takes control, streams progress]
    ↓
[Agent returns control with result]
```

#### 3. Debug Interface Flow

```text
[Developer opens console]
    ↓
[Types: window.mcpDebug.listAvailableTools()]
    ↓
[Sees all tools with metadata]
    ↓
[Can invoke tools directly for testing]
```

### Configuration Extensions

Add to existing `CONFIG_DEFAULT`:

```typescript
export const CONFIG_DEFAULT = {
  // ...existing config...
  
  // MCP Configuration
  mcpToolsEnabled: true,
  mcpAgentHandoffEnabled: true,
  mcpToolCacheTTL: 300000, // 5 minutes
  mcpDebugMode: isDev,
  mcpMaxHandoffDuration: 120000, // 2 minutes
  mcpPreferredAgents: [] as string[],
};
```

### Benefits

1. **Dynamic Capabilities**: Tools can be added without frontend deployments
2. **Intelligent Workflows**: Backend agents can handle complex multi-step operations
3. **Better Developer Experience**: Debug interface enables rapid testing and development
4. **Scalable Architecture**: Pattern supports addition of new MCP servers
5. **Maintained UX**: Seamless integration with existing chat interface

### Security Considerations

1. **Tool Validation**: All dynamic tools must pass security validation
2. **Agent Isolation**: Handoff sessions run in isolated environments
3. **User Consent**: Explicit user consent for agent handoffs
4. **Rate Limiting**: Prevent abuse of tool discovery and invocation
5. **Audit Trail**: Complete logging of all tool invocations and handoffs

### Future Extensions

1. **Tool Marketplace**: Community-contributed MCP tools
2. **Workflow Builder**: Visual tool composition interface
3. **Multi-Agent Orchestration**: Multiple specialized agents working together
4. **Real-time Collaboration**: Multiple users sharing agent sessions

## Conclusion

This design pattern transforms the static web UI into a dynamic, extensible platform that can grow with the MCP ecosystem. By implementing bidirectional control between frontend and backend, we enable both immediate tool access and sophisticated agent-driven workflows while maintaining excellent user experience.

The phased implementation approach ensures we can validate concepts early and iterate based on user feedback, while the comprehensive API design provides a solid foundation for future enhancements.

### Cline-Inspired Design Patterns

Based on analysis of the successful Cline VSCode extension, we can adopt several proven patterns:

#### 1. gRPC-Based Communication Pattern

**Cline's Approach**: Uses gRPC streaming for real-time bidirectional communication between extension host and webview.

**Adaptation for Web UI**:

```typescript
// WebSocket-based streaming service (instead of gRPC)
class MCPStreamingService {
  private ws: WebSocket;
  private subscriptions: Map<string, Set<(data: any) => void>> = new Map();

  constructor() {
    this.ws = new WebSocket(`ws://${window.location.host}/v1/mcp/stream`);
    this.setupEventHandlers();
  }

  // Subscribe to MCP tool updates
  subscribeToToolUpdates(callback: (tools: MCPTool[]) => void): () => void {
    return this.subscribe('mcp.tools.updated', callback);
  }

  // Subscribe to agent handoff events
  subscribeToAgentHandoff(callback: (session: AgentSession) => void): () => void {
    return this.subscribe('agent.handoff', callback);
  }

  // Subscribe to tool invocation results
  subscribeToToolResults(callback: (result: ToolResult) => void): () => void {
    return this.subscribe('tool.result', callback);
  }

  private subscribe(event: string, callback: (data: any) => void): () => void {
    if (!this.subscriptions.has(event)) {
      this.subscriptions.set(event, new Set());
    }
    this.subscriptions.get(event)!.add(callback);
    
    return () => {
      this.subscriptions.get(event)?.delete(callback);
    };
  }
}
```

#### 2. Context-Driven State Management

**Cline's Approach**: Uses React Context with extensive state management and subscription cleanup.

**Adaptation**:

```typescript
interface MCPContextType {
  // Tool Management
  tools: MCPTool[];
  activeTools: Set<string>;
  toolHistory: ToolInvocation[];
  
  // Agent Sessions
  agentSessions: Map<string, AgentSession>;
  activeSession: string | null;
  
  // Debug Interface
  debugMode: boolean;
  debugMessages: DebugMessage[];
  
  // Actions
  invokeTool: (toolId: string, params: any) => Promise<any>;
  requestAgentHandoff: (context: HandoffContext) => Promise<string>;
  cancelAgentSession: (sessionId: string) => void;
  
  // Subscriptions (Cline pattern)
  onToolUpdate: (callback: (tools: MCPTool[]) => void) => () => void;
  onAgentProgress: (callback: (progress: AgentProgress) => void) => () => void;
  onDebugMessage: (callback: (msg: DebugMessage) => void) => () => void;
}

export const MCPContextProvider: React.FC<{ children: React.ReactNode }> = ({ 
  children 
}) => {
  const [tools, setTools] = useState<MCPTool[]>([]);
  const [agentSessions, setAgentSessions] = useState<Map<string, AgentSession>>(new Map());
  const streamingService = useRef<MCPStreamingService>();
  
  // Subscription refs for cleanup (Cline pattern)
  const toolUpdateUnsubscribeRef = useRef<(() => void) | null>(null);
  const agentHandoffUnsubscribeRef = useRef<(() => void) | null>(null);
  const debugMessageUnsubscribeRef = useRef<(() => void) | null>(null);

  useEffect(() => {
    streamingService.current = new MCPStreamingService();
    
    // Set up subscriptions
    toolUpdateUnsubscribeRef.current = streamingService.current.subscribeToToolUpdates(
      (updatedTools) => {
        console.log('[DEBUG] Received tool updates:', updatedTools);
        setTools(updatedTools);
      }
    );

    agentHandoffUnsubscribeRef.current = streamingService.current.subscribeToAgentHandoff(
      (session) => {
        console.log('[DEBUG] Agent handoff initiated:', session);
        setAgentSessions(prev => new Map(prev).set(session.id, session));
      }
    );

    // Cleanup subscriptions on unmount (Cline pattern)
    return () => {
      if (toolUpdateUnsubscribeRef.current) {
        toolUpdateUnsubscribeRef.current();
        toolUpdateUnsubscribeRef.current = null;
      }
      if (agentHandoffUnsubscribeRef.current) {
        agentHandoffUnsubscribeRef.current();
        agentHandoffUnsubscribeRef.current = null;
      }
      if (debugMessageUnsubscribeRef.current) {
        debugMessageUnsubscribeRef.current();
        debugMessageUnsubscribeRef.current = null;
      }
    };
  }, []);

  // ...rest of implementation
};
```

#### 3. Tool Capability Detection & Dynamic Registration

**Cline's Approach**: Dynamic MCP server detection and tool registration based on capabilities.

**Adaptation**:

```typescript
class DynamicMCPManager {
  private toolCapabilities: Map<string, ToolCapability> = new Map();
  private serverConnections: Map<string, MCPServerConnection> = new Map();

  async discoverAndRegisterTools(): Promise<void> {
    // Discover available MCP servers
    const servers = await this.discoverMCPServers();
    
    for (const server of servers) {
      try {
        const connection = await this.connectToServer(server);
        const tools = await connection.listTools();
        
        tools.forEach(tool => {
          // Determine capability requirements
          const capability = this.analyzeToolCapability(tool);
          this.toolCapabilities.set(tool.id, capability);
          
          // Register tool with appropriate handler
          this.registerToolHandler(tool, capability);
        });
        
        this.serverConnections.set(server.id, connection);
      } catch (error) {
        console.warn(`Failed to connect to MCP server ${server.id}:`, error);
      }
    }
  }

  private analyzeToolCapability(tool: MCPTool): ToolCapability {
    // Cline-style capability detection
    const isComplex = tool.parameters?.properties && 
                     Object.keys(tool.parameters.properties).length > 3;
    const requiresHandoff = tool.metadata?.requiresHandoff ||
                           tool.description.includes('complex') ||
                           tool.description.includes('multi-step');
    
    return {
      type: requiresHandoff ? 'agent_required' : 'direct_invoke',
      complexity: isComplex ? 'high' : 'low',
      permissions: this.extractPermissions(tool),
      estimatedDuration: this.estimateExecutionTime(tool)
    };
  }
}
```

#### 4. Agent Control Flow (Human-in-the-Loop)

**Cline's Approach**: Every action requires user approval with clear indication of what will happen.

**Adaptation**:

```typescript
interface AgentControlFlow {
  requestUserPermission: (action: ProposedAction) => Promise<boolean>;
  showProgress: (progress: AgentProgress) => void;
  allowInterruption: (sessionId: string) => void;
  transferControl: (from: 'user' | 'agent', to: 'user' | 'agent') => void;
}

class AgentSessionManager implements AgentControlFlow {
  async requestUserPermission(action: ProposedAction): Promise<boolean> {
    return new Promise((resolve) => {
      // Show modal with action details (Cline pattern)
      const modal = this.createPermissionModal({
        title: `Agent wants to ${action.type}`,
        description: action.description,
        toolsInvolved: action.tools,
        estimatedTime: action.estimatedDuration,
        onApprove: () => resolve(true),
        onDeny: () => resolve(false),
        onPause: () => this.pauseSession(action.sessionId)
      });
      
      document.body.appendChild(modal);
    });
  }

  showProgress(progress: AgentProgress): void {
    // Real-time progress display (like Cline's task progress)
    this.updateProgressUI({
      sessionId: progress.sessionId,
      currentStep: progress.currentStep,
      totalSteps: progress.totalSteps,
      message: progress.message,
      toolsUsed: progress.toolsUsed,
      canCancel: true
    });
  }
}
```

#### 5. Checkpoint & Restore System

**Cline's Approach**: Automatic workspace snapshots at each step with compare/restore functionality.

**Adaptation**:

```typescript
interface CheckpointSystem {
  createCheckpoint: (label: string, context: any) => Promise<string>;
  restoreCheckpoint: (checkpointId: string) => Promise<void>;
  compareCheckpoints: (id1: string, id2: string) => Promise<Diff[]>;
  listCheckpoints: () => Promise<Checkpoint[]>;
}

class MCPCheckpointManager implements CheckpointSystem {
  async createCheckpoint(label: string, context: any): Promise<string> {
    const checkpoint: Checkpoint = {
      id: generateId(),
      timestamp: Date.now(),
      label,
      context: {
        conversation: context.conversation,
        toolStates: await this.captureToolStates(),
        agentSessions: context.agentSessions,
        userPreferences: context.userPreferences
      }
    };
    
    await this.saveCheckpoint(checkpoint);
    return checkpoint.id;
  }

  async restoreCheckpoint(checkpointId: string): Promise<void> {
    const checkpoint = await this.loadCheckpoint(checkpointId);
    if (!checkpoint) throw new Error('Checkpoint not found');
    
    // Restore conversation state
    await this.restoreConversation(checkpoint.context.conversation);
    
    // Restore tool states
    await this.restoreToolStates(checkpoint.context.toolStates);
    
    // Cancel any active agent sessions
    await this.cancelActiveSessions();
    
    // Restore agent sessions if any
    await this.restoreAgentSessions(checkpoint.context.agentSessions);
  }
}
```

#### 6. Debug Interface Integration

**Cline's Approach**: Rich debugging capabilities with console access and real-time inspection.

**Enhanced Implementation**:

```typescript
// Global debug interface (enhanced from original design)
declare global {
  interface Window {
    mcpDebug: {
      // Tool Management
      listAvailableTools: () => MCPTool[];
      inspectTool: (toolId: string) => ToolInspection;
      invokeTool: (toolId: string, params: any) => Promise<any>;
      
      // Agent Management  
      getActiveSessions: () => AgentSession[];
      inspectSession: (sessionId: string) => SessionInspection;
      triggerHandoff: (context: any) => Promise<string>;
      cancelSession: (sessionId: string) => void;
      
      // Checkpoint Management
      createCheckpoint: (label: string) => Promise<string>;
      listCheckpoints: () => Checkpoint[];
      restoreCheckpoint: (id: string) => Promise<void>;
      
      // Real-time Monitoring
      monitorToolInvocations: (callback: (inv: ToolInvocation) => void) => () => void;
      monitorAgentProgress: (callback: (progress: AgentProgress) => void) => () => void;
      
      // Advanced Debug Features
      traceExecution: (enable: boolean) => void;
      dumpState: () => any;
      injectDebugMessage: (message: string) => void;
    };
  }
}
```

#### 7. Enhanced API Design

**Building on Cline's patterns**:

```typescript
// WebSocket-based real-time API (instead of HTTP polling)
interface MCPWebSocketAPI {
  // Tool Discovery & Management
  'mcp.tools.list': () => MCPTool[];
  'mcp.tools.updated': (tools: MCPTool[]) => void;
  'mcp.tool.invoke': (toolId: string, params: any) => Promise<any>;
  
  // Agent Handoff & Control
  'agent.handoff.request': (context: HandoffContext) => Promise<AgentSession>;
  'agent.progress': (sessionId: string, progress: AgentProgress) => void;
  'agent.handoff.complete': (sessionId: string, result: any) => void;
  
  // Real-time Updates
  'conversation.updated': (conversation: Conversation) => void;
  'debug.message': (message: DebugMessage) => void;
  
  // Checkpoint Events
  'checkpoint.created': (checkpoint: Checkpoint) => void;
  'checkpoint.restored': (checkpointId: string) => void;
}
```

### Integration Plan

1. **Phase 1**: Implement WebSocket-based streaming service
2. **Phase 2**: Add context-driven state management with subscription cleanup
3. **Phase 3**: Implement agent control flow with user permission system
4. **Phase 4**: Add checkpoint/restore capabilities
5. **Phase 5**: Enhance debug interface with real-time monitoring

### Benefits of Cline Patterns

1. **Proven Reliability**: Battle-tested in production VSCode environment
2. **Real-time Communication**: WebSocket streaming enables immediate updates
3. **User Trust**: Human-in-the-loop approval process builds confidence
4. **Developer Experience**: Rich debugging capabilities
5. **State Management**: Robust subscription cleanup prevents memory leaks
6. **Rollback Capability**: Checkpoint system enables safe experimentation

## Official MCP TypeScript SDK Integration

**Excellent Discovery**: Instead of building custom communication patterns from scratch, we should leverage the official `@modelcontextprotocol/sdk` which provides robust, standardized MCP client and server implementations.

### Key Advantages

1. **Standardized Protocol**: Full MCP specification compliance
2. **Multiple Transports**: stdio, HTTP, Streamable HTTP support out of the box  
3. **Type Safety**: Complete TypeScript definitions
4. **Built-in Error Handling**: Connection management and recovery
5. **Resource Management**: Native support for MCP resources and templates
6. **Tool Discovery**: Automatic capability detection

### Implementation Strategy

Replace our custom streaming service with the official SDK:

```bash
npm install @modelcontextprotocol/sdk zod
```

```typescript
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport, StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";

class MCPClientManager {
  private clients = new Map<string, Client>();

  async connectToServer(config: MCPServerConfig): Promise<Client> {
    const client = new Client({ name: "webui-mcp-client", version: "1.0.0" });
    
    const transport = config.type === 'stdio' 
      ? new StdioClientTransport({ command: config.command, args: config.args })
      : new StreamableHTTPClientTransport(new URL(config.url));

    await client.connect(transport);
    this.clients.set(config.id, client);
    return client;
  }

  async discoverTools(): Promise<MCPTool[]> {
    const allTools: MCPTool[] = [];
    for (const [serverId, client] of this.clients) {
      const tools = await client.listTools();
      allTools.push(...tools.tools.map(tool => ({ ...tool, serverId })));
    }
    return allTools;
  }

  async invokeTool(serverId: string, name: string, arguments: any) {
    const client = this.clients.get(serverId);
    if (!client) throw new Error(`Server ${serverId} not connected`);
    return await client.callTool({ name, arguments });
  }
}
```

### Enhanced Configuration

Add to existing `CONFIG_DEFAULT`:

```typescript
export const CONFIG_DEFAULT = {
  // ...existing config...
  
  // MCP SDK Configuration  
  mcpEnabled: true,
  mcpAutoConnect: true,
  mcpConnectionTimeout: 10000,
  mcpRetryAttempts: 3,
  mcpRetryDelay: 2000,
  
  // Server configurations
  mcpServers: [
    {
      id: 'local-files',
      name: 'File System Server',
      type: 'stdio',
      command: 'node',
      args: ['mcp-servers/filesystem.js'],
      autoConnect: true
    },
    {
      id: 'remote-api',
      name: 'Remote API Server', 
      type: 'http',
      url: 'http://localhost:3001/mcp',
      autoConnect: false
    }
  ] as MCPServerConfig[],
  
  // Tool preferences
  mcpToolTimeout: 30000,
  mcpToolRetries: 2,
  mcpPreferredToolCategories: ['file-system', 'api', 'database'],
  
  // Agent handoff settings (enhanced)
  mcpAgentHandoffEnabled: true,
  mcpMaxHandoffDuration: 300000, // 5 minutes
  mcpHandoffComplexityThreshold: 'moderate',
  mcpAgentProgressUpdates: true,
};
```

## Implementation Strategy: BFF vs Frontend MCP Client

### Analysis Summary

**Current Architecture Constraints:**

- 1.5MB bundle size limit (single-file build)
- Existing `/v1` proxy pattern to backend
- OpenAI-compatible backend design
- No existing WebSocket infrastructure

### **Recommended: Hybrid BFF-Primary Architecture**

#### Primary MCP Client in BFF (Backend-for-Frontend)

**Implementation:**

```typescript
// Backend: MCP Service Layer
class MCPService {
  private clients = new Map<string, Client>();
  
  async initializeServers(configs: MCPServerConfig[]) {
    for (const config of configs) {
      const client = new Client({ name: "webui-mcp", version: "1.0.0" });
      const transport = this.createTransport(config);
      await client.connect(transport);
      this.clients.set(config.id, client);
    }
  }
  
  async getAvailableTools(): Promise<MCPTool[]> {
    const allTools = [];
    for (const [serverId, client] of this.clients) {
      const { tools } = await client.listTools();
      allTools.push(...tools.map(t => ({ ...t, serverId })));
    }
    return allTools;
  }
  
  async invokeTool(serverId: string, name: string, args: any) {
    const client = this.clients.get(serverId);
    return await client.callTool({ name, arguments: args });
  }
}
```

**New API Endpoints:**

```text
GET  /v1/mcp/tools                    # Tool discovery
POST /v1/mcp/tools/invoke             # Tool invocation
GET  /v1/mcp/servers                  # Server status
POST /v1/mcp/servers/{id}/connect     # Connect to server
POST /v1/mcp/handoff                  # Agent handoff
```

#### Lightweight Frontend MCP Interface

**Implementation:**

```typescript
// Frontend: Lightweight MCP API wrapper
class MCPApiClient {
  async getTools(): Promise<MCPTool[]> {
    const response = await fetch('/v1/mcp/tools');
    return response.json();
  }
  
  async invokeTool(serverId: string, toolName: string, params: any) {
    return fetch('/v1/mcp/tools/invoke', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ serverId, toolName, params })
    }).then(r => r.json());
  }
  
  // SSE for real-time updates
  subscribeToUpdates(callback: (event: MCPEvent) => void) {
    const eventSource = new EventSource('/v1/mcp/events');
    eventSource.onmessage = (e) => callback(JSON.parse(e.data));
    return () => eventSource.close();
  }
}
```

### Benefits of BFF-Primary Approach

1. **Bundle Size**: Keeps `@modelcontextprotocol/sdk` out of frontend bundle
2. **Security**: MCP servers run in secure backend environment
3. **Performance**: Connection pooling, caching, and resource sharing
4. **Compatibility**: Leverages existing proxy architecture
5. **Scalability**: Multiple frontend clients share backend connections
6. **Error Handling**: Centralized retry logic and connection management

### Hybrid Elements

**For Development/Debug**: Optional lightweight MCP client in frontend

```typescript
// Only in development builds
if (import.meta.env.DEV) {
  const { Client } = await import('@modelcontextprotocol/sdk/client');
  window.mcpDebugClient = new Client({ name: "debug", version: "1.0.0" });
}
```

## Final Implementation Recommendation

### Revised Architecture

1. **BFF-Primary MCP Integration**: Use `@modelcontextprotocol/sdk` in backend
2. **Lightweight Frontend API**: HTTP + SSE for real-time updates  
3. **Adopt Cline's proven patterns** for state management and UI
4. **Implement progressive enhancement** starting with simple tool discovery
5. **Add agent handoff capabilities** for complex workflows
6. **Include comprehensive debugging tools** for development

### Next Steps

1. **Backend Dependencies**: Install `@modelcontextprotocol/sdk`, `zod` in BFF
2. **Create MCPService**: Manage connections to MCP servers in backend
3. **Add API Endpoints**: `/v1/mcp/*` routes for tool discovery and invocation
4. **Frontend MCPApiClient**: Lightweight wrapper for MCP operations
5. **Enhance AppContext**: Add MCP state management with SSE subscriptions
6. **Build UI Components**: Tool discovery, agent handoff, debug interface
7. **Add Configuration**: MCP server settings in user preferences

### Trade-off Summary

| Aspect | BFF Primary | Frontend Primary |
|--------|-------------|------------------|
| Bundle Size | ✅ Minimal impact | ❌ +500KB+ |
| Security | ✅ Server-side | ❌ Browser limitations |
| Latency | ⚠️ Extra hop | ✅ Direct |
| Scalability | ✅ Shared connections | ❌ Per-tab connections |
| Development | ✅ Simpler debugging | ⚠️ Complex state |
| Architecture Fit | ✅ Matches existing | ❌ Requires restructure |

This design provides a robust, scalable foundation for dynamic MCP tool integration while respecting current architecture constraints and bundle size requirements.
