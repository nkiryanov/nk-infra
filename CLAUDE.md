# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible-based infrastructure automation for a distributed Xray VLESS proxy network. Two VPS servers are managed:
- **nk-router** — entry point; routes traffic (blocks torrents, directs RU traffic locally, proxies the rest through nk-freedom)
- **nk-freedom** — exit node; forwards proxied traffic to the internet

## Common Commands

```bash
# Set up the environment (requires uv: https://docs.astral.sh/uv/)
make install

# Lint (yamllint + ansible-lint)
make lint

# Deploy to production (runs the full playbook)
ansible-playbook -i hosts.yml --user infra --become site.yml

# Run a single role/tag (e.g. only xray on the router)
ansible-playbook -i hosts.yml --user infra --become site.yml --tags xray -l nk-router

# Encrypt a new secret for vault
make encrypt-secret NAME=secret_name SECRET="value"

# View a vault-encrypted secret
make view-secret SECRET=secrets.github.token

# Generate .ssh-config from inventory
make ssh-config
```

## Architecture

### Playbook structure (`site.yml`)
Three plays run in order:
1. **Common configuration** — applied to all hosts: `common` role (hostname, packages, SSH accounts, UFW firewall) + `docker` role.
2. **Xray Router** — applied to `nk-router` only. Loads both router and freedom secrets (needs freedom's host IP for the proxy outbound).
3. **Xray Freedom** — applied to `nk-freedom` only. Loads only freedom secrets.

### Roles (`roles/`)
- **common** — base server setup: hostname, packages (acl, net-tools, vim, ufw, fish), passwordless sudo, SSH account management (`vars/ssh_accounts.yml`), UFW rules (SSH, private LAN, deny default). Depends on `geerlingguy.swap` and `geerlingguy.security`.
- **docker** — installs Docker CE + compose plugin via official apt repo with GPG verification.
- **xray** — installs Xray from GitHub releases, deploys Jinja2 config template (`config_template` var), opens port 443, manages the systemd service.

### Xray configuration (`xray/`)
Each server has its own `config.json.j2` template and `secrets.yml` (vault-encrypted UUIDs, reality keys).
- Router config routes based on destination: RU → direct, BitTorrent → blackhole, everything else → proxy outbound to nk-freedom.
- Freedom config is a simple VLESS+Reality listener with a direct outbound.

### Secrets
- `vars/secrets.yml` — global secrets (e.g. GHCR token).
- `xray/{router,freedom}/secrets.yml` — per-service Xray secrets.
- Vault password file: `.vault-key` (gitignored, not in repo).

### CI/CD (`.github/workflows/`)
- **lint.yml** — runs `make lint` on PRs.
- **deploy-prod.yml** — triggers on push to `main` (or manual dispatch); runs lint first, then deploys with `ansible-playbook` using the `infra` user and secrets from GitHub Actions.
- **setup-project action** — composite action that installs uv, Python, caches galaxy roles, runs `make install`.

### Inventory (`hosts.yml`)
Defines `nk-router` and `nk-freedom` under `all.hosts` with `ansible_host` IPs. Both target Python 3.12 interpreters on the remote hosts.

## Key Conventions
- Dependencies managed with `uv` (not pip directly). Lock file is `uv.lock`.
- Python >=3.13 required for local development (see `.python-version` and `pyproject.toml`).
- Ansible uses Mitogen strategy plugin (bundled in `mitogen/` submodule) for faster execution.
- UFW is the firewall; private VLAN `10.16.0.0/16` is allowed between hosts.
- Galaxy role dependencies listed in `requirements.yml` (geerlingguy.swap, geerlingguy.security).
