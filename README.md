# nk-infra

vpn managed with [Ansible](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html).
The xray config is very simple and mostly borrowed from [Amnezia VPN](https://amneziavpn.org/).
**stack:** Ansible, xray (VLESS + Reality), [uv](https://docs.astral.sh/uv/) for Python dependency management, GitHub Actions for CI/CD.

## Setup
Requires [uv](https://docs.astral.sh/uv/getting-started/installation/) installed.

```bash
make install
```

## Usage

```bash
# Lint
make lint

# Deploy
ansible-playbook --inventory hosts.yml --become site.yml

# Manage secrets (vault key stored in .vault-key)
make encrypt-secret NAME=token SECRET="value"
make view-secret SECRET=secrets.github.token
```

### First deployment of a new server

The `common` role creates the `infra` user (and other accounts from `vars/ssh_accounts.yml`).
On a fresh server this role must be run manually as root, since the deploy user doesn't exist yet:

```bash
ansible-playbook --inventory="hosts.yml" --user="root" --become --tags="common" --limit="nk-router" site.yml
```

After that, subsequent deploys work without specifying a user.

## Architecture

Two servers managed via `site.yml`:

- **nk-router** — entry point. Routes RU traffic directly, proxies the rest through nk-freedom. Blocks BitTorrent.
- **nk-freedom** — exit node. Forwards proxied traffic to the internet.
