# MESH Sandbox

MESH sandbox for local testing of [NHS Digital's MESH API](https://digital.nhs.uk/developer/api-catalogue/message-exchange-for-social-care-and-health-api).

## Installation and example use

#### pip
```bash
pip install mesh-sandbox
STORE_MODE=file MAILBOXES_DATA_DIR=/tmp/mesh uvicorn mesh_sandbox.api:app --reload --port 8700 --workers=1
curl http://localhost:8700/health
```

#### docker compose
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


## Ways to use mesh-sandbox

#### Store Mode

Store mode is set using environment variable `STORE_MODE`

Accepted parameters:
 - **canned** - Read only mailboxes
 - **memory** - Mailbox state persists only while instance is active.
 - **file** - Mailbox state persists using files which are stored in location defined by environment variable `FILE_STORE_DIR`

> Note: Initial state of mailboxes is defined in `src/mesh_sandbox/store/data`

#### Authentication Mode

Authentication mode is set using environment variable: `AUTH_MODE`

Accepted parameters:
 - **none** - No authentication against passwords
 - **full** - Requires valid password and certificates


#### Admin endpoints
Admin endpoints that can be used for testing purposes:

- Reset all mailboxes: `/admin/reset`
- Reset single mailbox: `/admin/reset/{mailbox_id}`
- Create new mailbox: `/admin/create/{mailbox_id}`

## Guidance for contributors
[contributing](CONTRIBUTING.md)
