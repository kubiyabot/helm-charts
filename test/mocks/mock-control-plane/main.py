"""
Mock Control-Plane Service for Testing.

A FastAPI service that mimics control-plane.kubiya.ai API responses
for local testing without requiring the real control-plane service.
"""

from typing import Annotated, Any

from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import JSONResponse

app = FastAPI(title="Mock Control-Plane Service")


# ============================================================================
# MOCK DATA
# ============================================================================

MOCK_ORGANIZATION = {
    "id": "00000000-0000-0000-0000-000000000123",
    "slug": "test-org",
    "user_id": "00000000-0000-0000-0000-000000000456",
    "user_email": "test@kubiya.ai",
    "user_name": "Test User",
}

MOCK_MODELS = [
    {
        "id": "kubiya/gpt-4o",
        "provider": "openai",
        "runtime": "gpt",
        "name": "GPT-4o",
        "enabled": True,
        "description": "OpenAI GPT-4o model",
    },
    {
        "id": "kubiya/gpt-4o-mini",
        "provider": "openai",
        "runtime": "gpt",
        "name": "GPT-4o Mini",
        "enabled": True,
        "description": "OpenAI GPT-4o Mini model",
    },
    {
        "id": "kubiya/claude-sonnet-4",
        "provider": "anthropic",
        "runtime": "claude",
        "name": "Claude Sonnet 4",
        "enabled": True,
        "description": "Anthropic Claude Sonnet 4 model",
    },
    {
        "id": "kubiya/claude-haiku-3.5",
        "provider": "anthropic",
        "runtime": "claude",
        "name": "Claude Haiku 3.5",
        "enabled": True,
        "description": "Anthropic Claude Haiku 3.5 model",
    },
]

MOCK_LLM_CREDENTIALS = {
    "api_key": "mock-api-key",
    "api_base": "http://mock-litellm:8000",
    "provider": "openai",
    "timeout": 30,
}


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================


def extract_token(authorization: str | None) -> tuple[str | None, bool]:
    """Extract token from Authorization header.

    Returns:
        Tuple of (token, is_malformed) where is_malformed is True if
        the token had extra whitespace or other formatting issues.
    """
    if not authorization:
        return None, False
    # Handle "Bearer <token>" or "UserKey <token>" or raw token
    if authorization.startswith("Bearer "):
        raw_token = authorization[7:]
        stripped = raw_token.strip()
        # Check if there was extra whitespace
        is_malformed = raw_token != stripped or raw_token.startswith(" ")
        return stripped if stripped else None, is_malformed
    if authorization.startswith("UserKey "):
        raw_token = authorization[8:]
        stripped = raw_token.strip()
        # Check if there was extra whitespace
        is_malformed = raw_token != stripped or raw_token.startswith(" ")
        return stripped if stripped else None, is_malformed
    # Handle bare "Bearer" or "UserKey" without space (malformed)
    if authorization in ("Bearer", "UserKey"):
        return None, True
    return authorization, False


# ============================================================================
# ENDPOINTS
# ============================================================================


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy", "service": "mock-control-plane"}


@app.get("/")
async def root() -> dict[str, Any]:
    """Root endpoint with service info."""
    return {
        "service": "Mock Control-Plane Service",
        "version": "1.0.0",
        "endpoints": [
            "/health",
            "/api/v1/auth/validate",
            "/models",
            "/models/{model_id}",
            "/api/v1/creds/llm",
            "/api/v1/creds/temporal",
        ],
    }


def is_invalid_token(token: str) -> bool:
    """Check if token is obviously invalid (for auth tests).

    Returns True for tokens that should be rejected:
    - Contains 'invalid' (e.g., 'invalid_key_12345', 'invalid_token_12345')
    - Contains script/XSS patterns
    - Is too short (less than 5 chars)
    - Has extra spaces
    - Is an auth scheme keyword (Bearer, UserKey)
    """
    token_lower = token.lower()

    # Reject auth scheme keywords that accidentally became tokens
    if token_lower in ("bearer", "userkey"):
        return True

    # Reject tokens containing "invalid"
    if "invalid" in token_lower:
        return True

    # Reject XSS/script injection attempts
    if "<script>" in token_lower or "<" in token or ">" in token:
        return True

    # Reject tokens with extra spaces (malformed)
    if "  " in token:
        return True

    # Reject very short tokens (less than 5 chars)
    if len(token) < 5:
        return True

    return False


@app.get("/api/v1/auth/validate")
async def validate_auth(
    authorization: Annotated[str | None, Header()] = None,
) -> dict[str, Any]:
    """
    Validate authentication token.

    Accepts:
    - Known test tokens: test-token-12345, test-key
    - JWTs (tokens starting with 'eyJ')
    - Any other non-invalid tokens

    Returns 401 for:
    - Missing/empty tokens
    - Tokens containing 'invalid' (for auth tests)
    - Tokens with XSS/script patterns
    - Malformed tokens (extra spaces, too short)
    """
    token, is_malformed = extract_token(authorization)

    if not token:
        raise HTTPException(
            status_code=401,
            detail={"error": "Unauthorized", "message": "No authentication token provided"},
        )

    # Reject malformed tokens (extra whitespace, etc.)
    if is_malformed:
        raise HTTPException(
            status_code=401,
            detail={
                "error": "Unauthorized",
                "message": "Malformed authorization header",
            },
        )

    # Check if token is obviously invalid (for auth tests)
    if is_invalid_token(token):
        raise HTTPException(
            status_code=401,
            detail={
                "error": "Unauthorized",
                "message": "Invalid or expired authentication token",
            },
        )

    # Accept all other tokens (JWTs, test tokens, etc.)
    return MOCK_ORGANIZATION


@app.get("/models")
async def list_models(
    provider: str | None = None,
    runtime: str | None = None,
    authorization: Annotated[str | None, Header()] = None,
) -> list[dict[str, Any]]:
    """
    List available LLM models.

    Optionally filter by provider and/or runtime.
    """
    models = MOCK_MODELS

    if provider:
        models = [m for m in models if m["provider"] == provider]

    if runtime:
        models = [m for m in models if m["runtime"] == runtime]

    return models


@app.get("/models/{model_id:path}")
async def get_model(
    model_id: str,
    authorization: Annotated[str | None, Header()] = None,
) -> dict[str, Any]:
    """
    Get specific model by ID.

    Returns 404 if model not found.
    """
    for model in MOCK_MODELS:
        if model["id"] == model_id:
            return model

    raise HTTPException(
        status_code=404,
        detail={"error": "Not Found", "message": f"Model '{model_id}' not found"},
    )


@app.get("/api/v1/creds/llm")
async def get_llm_credentials(
    authorization: Annotated[str | None, Header()] = None,
) -> dict[str, Any]:
    """
    Get LLM credentials.

    Returns mock credentials pointing to mock-litellm service.
    """
    token, _ = extract_token(authorization)

    if not token:
        raise HTTPException(
            status_code=401,
            detail={"error": "Unauthorized", "message": "No authentication token provided"},
        )

    return MOCK_LLM_CREDENTIALS


@app.get("/api/v1/creds/temporal")
async def get_temporal_credentials(
    authorization: Annotated[str | None, Header()] = None,
) -> JSONResponse:
    """
    Get Temporal credentials.

    Returns 404 to simulate "not configured" state.
    This triggers graceful degradation in the API service.
    """
    token, _ = extract_token(authorization)

    if not token:
        raise HTTPException(
            status_code=401,
            detail={"error": "Unauthorized", "message": "No authentication token provided"},
        )

    # Return 404 to indicate Temporal is not configured
    return JSONResponse(
        status_code=404,
        content={"error": "Not Found", "message": "Temporal credentials not configured"},
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
