MESH Sandbox
===========

MESH sandbox for local testing of [NHS Digital's MESH API](https://digital.nhs.uk/developer/api-catalogue/message-exchange-for-social-care-and-health-api).

Installation
------------

Example use
-----------

pip
---

```bash
pip install mesh-sandbox
STORE_MODE=file MAILBOXES_DATA_DIR=/tmp/mesh uvicorn mesh_sandbox.api:app --reload --port 8700 --workers=1
curl http://localhost:8700/health
```

docker compose
--------------

```yaml
version: '3.9'


services:

  mesh_sandbox:
    build: 
      context: https://github.com/NHSDigital/mesh-sandbox.git#refs/tags/v1.0.4
    ports:
      - "8700:80"
    deploy:
      restart_policy:
        condition: on-failure
        max_attempts: 3
    healthcheck:
      test: curl -sf http://localhost:80/health || exit 1
      interval: 3s
      timeout: 10s
    environment:
      - SHARED_KEY=TestKey
    volumes:
      # mount a different mailboxes.jsonl to pre created mailboxes
      - ./src/mesh_sandbox/store/data/mailboxes.jsonl:/app/mesh_sandbox/store/data/mailboxes.jsonl:ro
      # the mesh sandbox supports injecting a plugin to support test hooks 
      # - ./my_test_plugin.py:/app/mesh_sandbox/plugin/my_test_plygin.py:ro

```

Guidance for contributors
-------------------------
[contributing](CONTRIBUTING.md)
