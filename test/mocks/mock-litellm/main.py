"""
Mock LiteLLM Service for Testing.

A smart FastAPI service that mimics LiteLLM/OpenAI API responses
including tool/function calling support for Agno workflow testing.
"""

import json
import random
import time
import uuid
from typing import Any

from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

app = FastAPI(title="Mock LiteLLM Service")

# Embedding dimension (matches text-embedding-3-large)
EMBEDDING_DIMENSIONS = 3072


class FunctionCall(BaseModel):
    name: str
    arguments: str


class ToolCall(BaseModel):
    id: str
    type: str = "function"
    function: FunctionCall


class Message(BaseModel):
    role: str
    content: str | None = None
    tool_calls: list[ToolCall] | None = None
    tool_call_id: str | None = None


class Tool(BaseModel):
    type: str = "function"
    function: dict[str, Any]


class ChatCompletionRequest(BaseModel):
    model: str
    messages: list[Message]
    temperature: float = 0.7
    max_tokens: int = 2048
    tools: list[Tool] | None = None
    tool_choice: str | dict[str, Any] | None = None
    stream: bool = False


class EmbeddingRequest(BaseModel):
    model: str
    input: str | list[str]


# ============================================================================
# MOCK RESPONSES FOR EACH WORKFLOW PHASE
# ============================================================================

QUERY_ANALYSIS_RESPONSE = """{
  "intent": "Find information in the knowledge graph",
  "key_terms": ["search", "query", "data"],
  "suggested_labels": ["Entity", "Document", "Concept"],
  "suggested_relationships": ["RELATES_TO", "CONTAINS", "HAS"],
  "search_strategy": "First get available labels, then search for relevant nodes by properties"
}"""

ANSWER_SYNTHESIS_RESPONSE = """\
Based on my search of the knowledge graph, I found relevant information.

**Summary:**
The graph contains entities and documents that match your query. I discovered nodes with \
relevant properties and relationships.

**Key Findings:**
- Found Entity nodes with associated properties
- Found Document nodes with status information
- The graph structure supports relationship exploration

**Suggestions for follow-up:**
- Explore relationships between discovered nodes
- Search for specific property values
- Query related entities by different labels"""

# Tool results that simulate what the graph service would return
MOCK_TOOL_RESULTS = {
    "get_available_labels": {
        "type": "tool_result",
        "tool": "get_available_labels",
        "success": True,
        "data": {"labels": ["Entity", "Document", "Concept", "User", "Project"], "count": 5},
        "human_readable": (
            "Found 5 node labels:\n  - Concept\n  - Document\n  - Entity\n  - Project\n  - User"
        ),
    },
    "get_available_relationship_types": {
        "type": "tool_result",
        "tool": "get_available_relationship_types",
        "success": True,
        "data": {
            "relationship_types": ["RELATES_TO", "CONTAINS", "HAS", "OWNS", "CREATED_BY"],
            "count": 5,
        },
        "human_readable": (
            "Found 5 relationship types:\n  - CONTAINS\n  - CREATED_BY\n  - HAS\n  - OWNS"
            "\n  - RELATES_TO"
        ),
    },
    "get_graph_statistics": {
        "type": "tool_result",
        "tool": "get_graph_statistics",
        "success": True,
        "data": {
            "node_count": 150,
            "relationship_count": 300,
            "labels": ["Entity", "Document", "Concept"],
            "relationship_types": ["RELATES_TO", "CONTAINS"],
        },
        "human_readable": "Graph Statistics:\n  Total Nodes: 150\n  Total Relationships: 300",
    },
    "search_nodes": {
        "type": "tool_result",
        "tool": "search_nodes",
        "success": True,
        "data": {
            "nodes": [
                {
                    "id": "node-001",
                    "labels": ["Entity"],
                    "properties": {"name": "Test Entity", "type": "mock", "status": "active"},
                },
                {
                    "id": "node-002",
                    "labels": ["Document"],
                    "properties": {"title": "Test Document", "status": "published"},
                },
            ],
            "count": 2,
            "query": {"label": "Entity"},
        },
        "human_readable": (
            "Found 2 nodes:\n\nNode 1:\n  ID: node-001\n  Labels: Entity\n  Properties:"
            "\n    name: Test Entity\n    type: mock\n\nNode 2:\n  ID: node-002\n  Labels:"
            " Document\n  Properties:\n    title: Test Document"
        ),
    },
    "get_node_by_id": {
        "type": "tool_result",
        "tool": "get_node_by_id",
        "success": True,
        "data": {
            "node": {
                "id": "node-001",
                "labels": ["Entity"],
                "properties": {"name": "Test Entity", "type": "mock"},
            }
        },
        "human_readable": (
            "Node Details:\n  ID: node-001\n  Labels: Entity\n  Properties:\n    name: Test Entity"
        ),
    },
    "get_node_relationships": {
        "type": "tool_result",
        "tool": "get_node_relationships",
        "success": True,
        "data": {
            "relationships": [
                {"type": "RELATES_TO", "source_id": "node-001", "target_id": "node-002"},
                {"type": "CONTAINS", "source_id": "node-001", "target_id": "node-003"},
            ],
            "count": 2,
            "lightweight_mode": True,
        },
        "human_readable": (
            "Found 2 relationships (lightweight mode):\n\nRelationship 1:\n  Type: RELATES_TO"
            "\n  Source: node-001\n  Target: node-002"
        ),
    },
}


def is_instructor_request(tools: list[Tool] | None) -> bool:
    """Detect if this is an Instructor-style structured output request."""
    if not tools or len(tools) != 1:
        return False

    # Instructor typically sends a single tool with schema-like name
    tool_name = tools[0].function.get("name", "")
    # Common Instructor patterns: Response, Answer, Output, Extract*, etc.
    instructor_patterns = [
        "Response",
        "Answer",
        "Output",
        "Extract",
        "Parse",
        "Schema",
        "Content",
        "Summarized",
    ]
    return any(pattern in tool_name for pattern in instructor_patterns)


def detect_workflow_phase(
    messages: list[Message], has_tools: bool, tools: list[Tool] | None = None
) -> str:
    """Detect which phase of the Agno workflow we're in."""
    # Check for Instructor-style requests first
    if is_instructor_request(tools):
        return "instructor"

    # Check for tool results in messages (means we're past initial tool call)
    has_tool_results = any(m.role == "tool" for m in messages)

    # Check last message content
    last_content = ""
    for msg in reversed(messages):
        if msg.content:
            last_content = msg.content.lower()
            break

    # Phase detection logic
    if "query & schema analyzer" in last_content or "analyze" in last_content:
        return "query_analysis"

    if has_tools and not has_tool_results:
        # Has tools but no results yet - need to call tools
        return "tool_call"

    if has_tools and has_tool_results:
        # Has tool results - time to summarize
        return "tool_summarize"

    if (
        "answer synthesizer" in last_content
        or "aggregated" in last_content
        or "synthesize" in last_content
    ):
        return "answer_synthesis"

    # Default based on tools presence
    if has_tools:
        return "tool_call"

    return "query_analysis"


def _get_called_tools(messages: list[Message]) -> set[str]:
    """Extract names of tools that have already been called from messages."""
    called_tools: set[str] = set()
    # Build a map of tool_call_id -> tool_name from assistant messages
    tool_call_map: dict[str, str] = {}
    for msg in messages:
        if msg.tool_calls:
            for tc in msg.tool_calls:
                tool_call_map[tc.id] = tc.function.name
    # Find which tools have results
    for msg in messages:
        if msg.role == "tool" and msg.tool_call_id:
            if msg.tool_call_id in tool_call_map:
                called_tools.add(tool_call_map[msg.tool_call_id])
    return called_tools


def _should_call_tool(name: str, tool_names: list[str], called_tools: set[str]) -> bool:
    """Check if a tool should be called (exists and hasn't been called)."""
    return name in tool_names and name not in called_tools


def get_tools_to_call(messages: list[Message], tools: list[Tool]) -> list[dict[str, Any]]:
    """Determine which tools to call based on context."""
    tool_names = [t.function.get("name", "") for t in tools]
    called_tools = _get_called_tools(messages)
    tools_to_call: list[dict[str, Any]] = []

    # First priority: get_available_labels and get_graph_statistics
    if _should_call_tool("get_available_labels", tool_names, called_tools):
        tools_to_call.append({"name": "get_available_labels", "arguments": "{}"})

    if _should_call_tool("get_graph_statistics", tool_names, called_tools):
        tools_to_call.append({"name": "get_graph_statistics", "arguments": "{}"})

    # Second priority: search_nodes (only if no first-priority tools to call)
    if not tools_to_call and _should_call_tool("search_nodes", tool_names, called_tools):
        tools_to_call.append(
            {
                "name": "search_nodes",
                "arguments": json.dumps({"label": "Entity", "limit": 10}),
            }
        )

    # If we've called tools, don't call more - return empty to signal summarization
    if not tools_to_call and called_tools:
        return []

    # Fallback: call first available tool
    if not tools_to_call and tool_names:
        tools_to_call.append({"name": tool_names[0], "arguments": "{}"})

    return tools_to_call


def create_tool_call_response(model: str, tools_to_call: list[dict[str, Any]]) -> dict[str, Any]:
    """Create OpenAI-format response with tool calls."""
    tool_calls = []
    for tool in tools_to_call:
        tool_calls.append(
            {
                "id": f"call_{uuid.uuid4().hex[:8]}",
                "type": "function",
                "function": {"name": tool["name"], "arguments": tool["arguments"]},
            }
        )

    return {
        "id": f"chatcmpl-mock-{uuid.uuid4().hex[:8]}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": None, "tool_calls": tool_calls},
                "finish_reason": "tool_calls",
            }
        ],
        "usage": {"prompt_tokens": 100, "completion_tokens": 50, "total_tokens": 150},
    }


def create_text_response(model: str, content: str) -> dict[str, Any]:
    """Create OpenAI-format text response."""
    return {
        "id": f"chatcmpl-mock-{uuid.uuid4().hex[:8]}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {"role": "assistant", "content": content},
                "finish_reason": "stop",
            }
        ],
        "usage": {
            "prompt_tokens": 100,
            "completion_tokens": len(content.split()) * 2,
            "total_tokens": 100 + len(content.split()) * 2,
        },
    }


def create_tool_summary_response(model: str, messages: list[Message]) -> dict[str, Any]:
    """Create response that summarizes tool results."""
    # Extract tool results from messages
    tool_results = []
    for msg in messages:
        if msg.role == "tool" and msg.content:
            tool_results.append(msg.content)

    # Build summary with embedded JSON tool results (for aggregation step to parse)
    summary_parts = ["Based on the query analysis, I searched the graph database.\n"]

    for result in tool_results:
        # Try to parse and re-format the tool result
        try:
            result_data = json.loads(result)
            summary_parts.append(json.dumps(result_data, indent=2))
            summary_parts.append("")
        except json.JSONDecodeError:
            summary_parts.append(result)
            summary_parts.append("")

    summary = "\n".join(summary_parts)

    return create_text_response(model, summary)


def create_instructor_response(model: str, tools: list[Tool]) -> dict[str, Any]:
    """Create response for Instructor-style structured output requests."""
    # Get the schema tool
    tool = tools[0]
    tool_name = tool.function.get("name", "Response")
    schema = tool.function.get("parameters", {})

    # Build mock structured response based on schema properties
    properties = schema.get("properties", {})
    mock_data: dict[str, Any] = {}

    for prop_name, prop_schema in properties.items():
        prop_type = prop_schema.get("type", "string")
        if prop_type == "string":
            mock_data[prop_name] = f"Mock {prop_name} content for testing"
        elif prop_type == "integer" or prop_type == "number":
            mock_data[prop_name] = 42
        elif prop_type == "boolean":
            mock_data[prop_name] = True
        elif prop_type == "array":
            mock_data[prop_name] = ["item1", "item2"]
        elif prop_type == "object":
            mock_data[prop_name] = {"key": "value"}
        else:
            mock_data[prop_name] = f"Mock {prop_name}"

    # Return as a single tool call with proper arguments
    return {
        "id": f"chatcmpl-mock-{uuid.uuid4().hex[:8]}",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model,
        "choices": [
            {
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": None,
                    "tool_calls": [
                        {
                            "id": f"call_{uuid.uuid4().hex[:8]}",
                            "type": "function",
                            "function": {"name": tool_name, "arguments": json.dumps(mock_data)},
                        }
                    ],
                },
                "finish_reason": "tool_calls",
            }
        ],
        "usage": {"prompt_tokens": 100, "completion_tokens": 50, "total_tokens": 150},
    }


@app.post("/v1/chat/completions", response_model=None)
@app.post("/chat/completions", response_model=None)
async def chat_completions(request: ChatCompletionRequest):
    """Mock chat completion endpoint with full tool calling support."""

    has_tools = request.tools is not None and len(request.tools) > 0
    phase = detect_workflow_phase(request.messages, has_tools, request.tools)

    # Handle streaming (basic support)
    if request.stream:
        return await handle_streaming_response(request, phase, has_tools)

    # Instructor-style structured output
    if phase == "instructor" and request.tools:
        return create_instructor_response(request.model, request.tools)

    # Query Analysis Phase - return JSON analysis
    if phase == "query_analysis":
        return create_text_response(request.model, QUERY_ANALYSIS_RESPONSE)

    # Tool Call Phase - return tool calls
    if phase == "tool_call" and has_tools:
        tools_to_call = get_tools_to_call(request.messages, request.tools)
        if tools_to_call:
            return create_tool_call_response(request.model, tools_to_call)
        else:
            # No more tools to call, summarize results
            return create_tool_summary_response(request.model, request.messages)

    # Tool Summarize Phase - summarize tool results
    if phase == "tool_summarize":
        return create_tool_summary_response(request.model, request.messages)

    # Answer Synthesis Phase - return final answer
    if phase == "answer_synthesis":
        return create_text_response(request.model, ANSWER_SYNTHESIS_RESPONSE)

    # Default fallback
    return create_text_response(request.model, ANSWER_SYNTHESIS_RESPONSE)


async def handle_streaming_response(
    request: ChatCompletionRequest, phase: str, has_tools: bool
) -> StreamingResponse:
    """Handle streaming chat completion."""

    async def generate_stream():
        # Determine response content
        if phase == "query_analysis":
            content = QUERY_ANALYSIS_RESPONSE
        elif phase == "tool_call" and has_tools:
            tools_to_call = get_tools_to_call(request.messages, request.tools)
            if tools_to_call:
                # For tool calls in streaming, we need to emit the tool call
                response = create_tool_call_response(request.model, tools_to_call)
                # Convert to streaming format
                chunk = {
                    "id": response["id"],
                    "object": "chat.completion.chunk",
                    "created": response["created"],
                    "model": response["model"],
                    "choices": [
                        {
                            "index": 0,
                            "delta": response["choices"][0]["message"],
                            "finish_reason": "tool_calls",
                        }
                    ],
                }
                yield f"data: {json.dumps(chunk)}\n\n"
                yield "data: [DONE]\n\n"
                return
            else:
                content = create_tool_summary_content(request.messages)
        elif phase == "tool_summarize":
            content = create_tool_summary_content(request.messages)
        else:
            content = ANSWER_SYNTHESIS_RESPONSE

        # Stream content in chunks
        chunk_id = f"chatcmpl-mock-{uuid.uuid4().hex[:8]}"

        # Initial chunk with role
        initial_chunk = {
            "id": chunk_id,
            "object": "chat.completion.chunk",
            "created": int(time.time()),
            "model": request.model,
            "choices": [
                {
                    "index": 0,
                    "delta": {"role": "assistant", "content": ""},
                    "finish_reason": None,
                }
            ],
        }
        yield f"data: {json.dumps(initial_chunk)}\n\n"

        # Content chunks
        words = content.split()
        for i in range(0, len(words), 5):
            chunk_text = " ".join(words[i : i + 5]) + " "
            chunk_data = {
                "id": chunk_id,
                "object": "chat.completion.chunk",
                "created": int(time.time()),
                "model": request.model,
                "choices": [{"index": 0, "delta": {"content": chunk_text}, "finish_reason": None}],
            }
            yield f"data: {json.dumps(chunk_data)}\n\n"

        # Final chunk
        final_chunk = {
            "id": chunk_id,
            "object": "chat.completion.chunk",
            "created": int(time.time()),
            "model": request.model,
            "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
        }
        yield f"data: {json.dumps(final_chunk)}\n\n"
        yield "data: [DONE]\n\n"

    return StreamingResponse(generate_stream(), media_type="text/event-stream")


def create_tool_summary_content(messages: list[Message]) -> str:
    """Create summary content from tool results."""
    tool_results = []
    for msg in messages:
        if msg.role == "tool" and msg.content:
            tool_results.append(msg.content)

    summary_parts = ["Based on the query analysis, I searched the graph database.\n"]
    for result in tool_results:
        try:
            result_data = json.loads(result)
            summary_parts.append(json.dumps(result_data, indent=2))
        except json.JSONDecodeError:
            summary_parts.append(result)
        summary_parts.append("")

    return "\n".join(summary_parts)


@app.post("/v1/embeddings")
@app.post("/embeddings")
async def embeddings(request: EmbeddingRequest) -> dict[str, Any]:
    """Mock embedding endpoint (OpenAI-compatible)."""
    inputs = [request.input] if isinstance(request.input, str) else request.input

    data = []
    for i, text in enumerate(inputs):
        seed = hash(text) % 10000
        random.seed(seed)
        embedding = [random.uniform(-1, 1) for _ in range(EMBEDDING_DIMENSIONS)]
        norm = sum(x * x for x in embedding) ** 0.5
        embedding = [x / norm for x in embedding]
        data.append({"object": "embedding", "embedding": embedding, "index": i})

    return {
        "object": "list",
        "data": data,
        "model": request.model,
        "usage": {
            "prompt_tokens": sum(len(text.split()) for text in inputs),
            "total_tokens": sum(len(text.split()) for text in inputs),
        },
    }


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy", "service": "mock-litellm"}


@app.get("/")
async def root() -> dict[str, Any]:
    """Root endpoint with service info."""
    return {
        "service": "Mock LiteLLM Service",
        "version": "2.0.0",
        "features": [
            "OpenAI-compatible chat completions",
            "Tool/function calling support",
            "Streaming support",
            "Embeddings",
        ],
        "endpoints": ["/v1/chat/completions", "/v1/embeddings", "/health"],
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
