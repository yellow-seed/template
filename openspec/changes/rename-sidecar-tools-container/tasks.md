## 1. Compose service

- [x] 1.1 Rename the Docker Compose service from `shell-dev` to a sidecar-oriented name
- [x] 1.2 Keep the sidecar container running under `docker compose up -d`

## 2. Documentation

- [x] 2.1 Update AGENTS.md to describe the sidecar container purpose clearly
- [x] 2.2 Replace one-off `docker compose run` examples with `up` / `exec` / `down` workflow
- [x] 2.3 Move Prettier usage from npm dependency assumptions to mise-managed tooling
- [x] 2.4 Add OpenSpec CLI to the mise-managed toolchain

## 3. Verification

- [x] 3.1 Search for stale `shell-dev` and one-off run examples
- [x] 3.2 Run available formatting or validation checks
