YML_FILES = $(shell find . -type f \( -name "*.yml" -o -name "*.yaml" \) -not -path "./venv/*" -not -path "./.venv/*" -not -path "./mitogen/*" -not -path "./.ansible/*")

.PHONY: .uv  ## Check that uv is installed
.uv:
	@uv -V || echo 'Please install uv: https://docs.astral.sh/uv/getting-started/installation/'

.PHONY: .install  ## Create (if not exists) virtual environment with development dependencies
install: .uv
	@uv sync --locked --no-dev
	@uv run ansible-galaxy install -r requirements.yml

.PHONY: lint-yml  ## Lint yaml files
lint-yml: .uv
	@uv run yamllint --strict $(YML_FILES) && echo "Yaml linting ok"

.PHONY: lint  ## Lint
lint: lint-yml .uv
	uv run ansible-lint --format pep8

.PHONY:  ## Just to check what .yml files are being linted
echo:
	@$(foreach val, $(YML_FILES), echo $(val);)
