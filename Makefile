YML_FILES = $(shell find . -type f \( -name "*.yml" -o -name "*.yaml" \) -not -path "./venv/*" -not -path "./mitogen/*")

install:
	pip install --upgrade pip
	pip install -r requirements.txt
	ansible-galaxy install -r requirements.yml

lint-yml:
	@yamllint --strict $(YML_FILES) && echo "Yaml linting ok"

lint: lint-yml
	ansible-lint --format pep8 --offline

echo:
	echo $(YML_FILES)

.PHONY: install lint-yml lint
