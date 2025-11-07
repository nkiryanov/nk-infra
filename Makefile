.PHONY: .uv  ## Check that uv is installed
.uv:
	@uv --version || echo 'Please install uv: https://docs.astral.sh/uv/getting-started/installation/'

.PHONY: help
help:
	@echo "Commands:"

	@echo "  1. make install"
	@echo "    Install dependencies with uv (.venv will be created)"

	@echo "  2. make lint"
	@echo "    Run linters (yaml linter + ansible-lint) across project"

	@echo "  3. make encrypt-secret SECRET_NAME={secret-name} SECRET={secret-value}"
	@echo "    Encrypt and print to stdout the encrypted value, that could be copy-pasted to configuration."
	@echo "    Examples:"
	@echo "      make encrypt-secret SECRET="my-very-strong-secret""
	@echo "      make encrypt-secret NAME="some-token" SECRET="my-very-strong-secret""

	@echo "  3. make view-secret SECRET={secret-name}"
	@echo "    View the encrypted SECRET secret value."
	@echo "    Usage example: make view-secret SECRET=secrets.github.token"

.PHONY: .install  ## Create (if not exists) virtual environment with development dependencies
install: .uv
	@uv sync --locked --no-dev
	@uv run ansible-galaxy install -r requirements.yml

.PHONY: lint  ## Lint
lint:
	uv run yamllint --strict . && echo "Yaml linting ok"
	uv run ansible-lint --format=pep8

encrypt-secret:
ifndef NAME
	@echo "Error: NAME variable not set"
	@echo
	@echo "Usage:"
	@echo "    make encrypt-secret NAME=secret-name SECRET=your-secret-value"
else ifndef SECRET
	@echo "Error: SECRET variable not set"
	@echo
	@echo "Usage:"
	@echo "    make encrypt-secret NAME=secret-name SECRET=your-secret-value"
else
	uv run ansible-vault encrypt_string --name="$(NAME)" "$(SECRET)"
endif

VAULT=@beget/vars/secrets.yml
.PHONY: view-secret
view-secret:
ifndef SECRET
	@echo "Error: SECRET variable not set"
	@echo
	@echo "Usage:"
	@echo "    make view-secret SECRET=secrets.ghcr.token"
else
	uv run ansible localhost \
		--inventory="localhost," \
		--module-name="debug" \
		--args="var=$(SECRET)" \
		--extra-vars="$(VAULT)"
endif
