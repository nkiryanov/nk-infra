YML_FILES = $(shell find . -type f \( -name "*.yml" -o -name "*.yaml" \) -not -path "./venv/*" -not -path "./.venv/*" -not -path "./mitogen/*" -not -path "./.ansible/*")

.PHONY: .uv  ## Check that uv is installed
.uv:
	@uv -V || echo 'Please install uv: https://docs.astral.sh/uv/getting-started/installation/'

.PHONY:  ## Just to check what .yml files are being linted
.yaml-to-lint:
	@$(foreach val, $(YML_FILES), echo $(val);)

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
lint: .uv
	uv run yamllint --strict $(YML_FILES) && echo "Yaml linting ok"
	uv run ansible-lint --format pep8

SECRET=""
NAME="your-secret-name"
.PHONY: encrypt-secret
encrypt-secret:
	ansible-vault encrypt_string --name "$(NAME)" "$(SECRET)"

SECRET = ""
VAULT=@beget/vars/secrets.yml
.PHONY: view-secret
view-secret: .uv
	uv run ansible localhost \
		--inventory="localhost," \
		--module-name="debug" \
		--args="var=$(SECRET)" \
		--extra-vars="$(VAULT)"
