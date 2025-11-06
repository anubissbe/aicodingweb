# Euraika-Code

A general-purpose AI Agent system that supports running various tools and operations in a sandbox environment.

Enjoy your own agent with Euraika-Code!

## Demos

### Basic Features

Euraika-Code provides a comprehensive AI agent system with support for Terminal, Browser, File, and Web Search operations.

### Browser Use

Execute complex web browsing tasks with AI assistance, including research, data extraction, and web automation.

### Code Use

Write and execute complex code examples with AI-powered assistance and debugging.

## Key Features

* **Deployment**: Minimal deployment requires only an LLM service, with no dependency on other external services.
* **Tools**: Supports Terminal, Browser, File, Web Search, and messaging tools with real-time viewing and takeover capabilities, supports external MCP tool integration.
* **Sandbox**: Each task is allocated a separate sandbox that runs in a local Docker environment.
* **Task Sessions**: Session history is managed through MongoDB/Redis, supporting background tasks.
* **Conversations**: Supports stopping and interrupting, file upload and download.
* **Authentication**: User login and authentication system.

## Development Roadmap

* Tools: Support for Deploy & Expose.
* Sandbox: Support for mobile and Windows computer access.
* Deployment: Support for K8s and Docker Swarm multi-cluster deployment.

### Overall Design

**When a user initiates a conversation:**

1. Web sends a request to create an Agent to the Server, which creates a Sandbox through `/var/run/docker.sock` and returns a session ID.
2. The Sandbox is an Ubuntu Docker environment that starts Chrome browser and API services for tools like File/Shell.
3. Web sends user messages to the session ID, and when the Server receives user messages, it forwards them to the PlanAct Agent for processing.
4. During processing, the PlanAct Agent calls relevant tools to complete tasks.
5. All events generated during Agent processing are sent back to Web via SSE.

**When users browse tools:**

- Browser:
    1. The Sandbox's headless browser starts a VNC service through xvfb and x11vnc, and converts VNC to websocket through websockify.
    2. Web's NoVNC component connects to the Sandbox through the Server's Websocket Forward, enabling browser viewing.
- Other tools: Other tools work on similar principles.

## Environment Requirements

This project primarily relies on Docker for development and deployment, requiring a relatively new version of Docker:
- Docker 20.10+
- Docker Compose

Model capability requirements:
- Compatible with OpenAI interface
- Support for FunctionCall
- Support for Json Format output

GPT-4 and Deepseek models are recommended.

## Deployment Guide

Docker Compose is recommended for deployment:

```yaml
services:
  frontend:
    image: euraika-frontend
    ports:
      - "5173:80"
    depends_on:
      - backend
    restart: unless-stopped
    networks:
      - euraika-network
    environment:
      - BACKEND_URL=http://backend:8000

  backend:
    image: euraika-backend
    depends_on:
      - sandbox
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - euraika-network
    environment:
      # OpenAI API base URL
      - API_BASE=https://api.openai.com/v1
      # OpenAI API key, replace with your own
      - API_KEY=sk-xxxx
      # LLM model name
      - MODEL_NAME=gpt-4o
      # LLM temperature parameter, controls randomness
      - TEMPERATURE=0.7
      # Maximum tokens for LLM response
      - MAX_TOKENS=2000

      # MongoDB configuration (optional)
      #- MONGODB_URI=mongodb://mongodb:27017
      #- MONGODB_DATABASE=euraika
      #- MONGODB_USERNAME=
      #- MONGODB_PASSWORD=

      # Redis configuration (optional)
      #- REDIS_HOST=redis
      #- REDIS_PORT=6379
      #- REDIS_DB=0
      #- REDIS_PASSWORD=

      # Sandbox configuration
      - SANDBOX_IMAGE=euraika-sandbox
      - SANDBOX_NAME_PREFIX=sandbox
      - SANDBOX_TTL_MINUTES=30
      - SANDBOX_NETWORK=euraika-network

      # Search engine configuration
      # Options: google, bing
      - SEARCH_PROVIDER=bing

      # Google search configuration, only used when SEARCH_PROVIDER=google
      #- GOOGLE_SEARCH_API_KEY=
      #- GOOGLE_SEARCH_ENGINE_ID=

      # Auth configuration
      # Options: password, none, local
      - AUTH_PROVIDER=password

      # Password auth configuration
      - PASSWORD_SALT=
      - PASSWORD_HASH_ROUNDS=10

      # JWT configuration
      - JWT_SECRET_KEY=your-secret-key-here
      - JWT_ALGORITHM=HS256
      - JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
      - JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

      # Application log level
      - LOG_LEVEL=INFO

  sandbox:
    image: euraika-sandbox
    command: /bin/sh -c "exit 0"  # prevent sandbox from starting, ensure image is pulled
    restart: "no"
    networks:
      - euraika-network

  mongodb:
    image: mongo:7.0
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped
    networks:
      - euraika-network

  redis:
    image: redis:7.0
    restart: unless-stopped
    networks:
      - euraika-network

volumes:
  mongodb_data:
    name: euraika-mongodb-data

networks:
  euraika-network:
    name: euraika-network
    driver: bridge
```

Save as `docker-compose.yml` file, and run:

```shell
docker compose up -d
```

> Note: If you see `sandbox-1 exited with code 0`, this is normal, as it ensures the sandbox image is successfully pulled locally.

Open your browser and visit <http://localhost:5173> to access Euraika-Code.

## Development Guide

### Project Structure

This project consists of three independent sub-projects:

* `frontend`: Euraika-Code frontend (Vue 3 + TypeScript + Vite)
* `backend`: Euraika-Code backend (FastAPI + Python)
* `sandbox`: Euraika-Code sandbox (Ubuntu + Docker)

### Environment Setup

1. Clone the project:
```bash
git clone <your-repository-url>
cd euraika-code
```

2. Copy the configuration file:
```bash
cp .env.example .env
```

3. Modify the configuration file (.env):
Update the `.env` file with your API keys and configuration.

### Development and Debugging

1. Run in debug mode:
```bash
# Start all services in development mode
./dev.sh up
```

All services will run in reload mode, and code changes will be automatically reloaded. The exposed ports are as follows:
- 5173: Web frontend port
- 8000: Server API service port
- 8080: Sandbox API service port
- 5900: Sandbox VNC port
- 9222: Sandbox Chrome browser CDP port

> *Note: In Debug mode, only one sandbox will be started globally*

2. When dependencies change (requirements.txt or package.json), clean up and rebuild:
```bash
# Clean up all related resources
./dev.sh down -v

# Rebuild images
./dev.sh build

# Run in debug mode
./dev.sh up
```

### Image Publishing

```bash
export IMAGE_REGISTRY=your-registry-url
export IMAGE_TAG=latest

# Build images
./run.sh build

# Push to the corresponding image repository
./run.sh push
```

## Architecture

The project follows clean architecture principles with clear separation of concerns:

### Backend Structure
```
backend/
├── app/
│   ├── application/     # Application layer (use cases)
│   ├── core/            # Core business logic
│   ├── domain/          # Domain entities and interfaces
│   ├── infrastructure/  # External services and implementations
│   └── interfaces/      # API routes and schemas
└── tests/               # Test suite
```

### Frontend Structure
```
frontend/
├── src/
│   ├── api/            # API client
│   ├── assets/         # Static assets
│   ├── components/     # Vue components
│   ├── composables/    # Vue composables
│   ├── constants/      # Constants
│   ├── lib/            # Libraries
│   ├── locales/        # Internationalization (English)
│   ├── pages/          # Page components
│   ├── types/          # TypeScript types
│   └── utils/          # Utility functions
└── public/             # Public assets
```

### Sandbox Structure
```
sandbox/
├── app/
│   ├── api/            # API endpoints
│   ├── core/           # Core functionality
│   ├── models/         # Data models
│   ├── schemas/        # Pydantic schemas
│   └── services/       # Services
└── resource/           # Sandbox resources
```

## Technologies Used

### Frontend
- Vue 3 (Composition API)
- TypeScript
- Vite
- Tailwind CSS
- Vue Router
- Vue i18n (English only)
- Axios
- NoVNC

### Backend
- FastAPI
- Python 3.11+
- Pydantic
- Docker SDK
- OpenAI API
- MongoDB (optional)
- Redis (optional)
- Playwright

### Sandbox
- Ubuntu 22.04
- Chrome
- VNC server
- Python

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
