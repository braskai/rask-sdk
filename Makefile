.DEFAULT: help
.PHONY: help bootstrap lint isort outdated deptree clean

VENV=.venv
PYTHON=$(VENV)/bin/python
PYPI_INDEX_URL="https://pypi.org/simple"

help:
	@echo "Use \`$(MAKE) <target>' where <target> is one of the following:"
	@echo "  help       - show help information"
	@echo "  bootstrap  - setup packaging dependencies and initialize venv"
	@echo "  lint       - inspect project source code for errors"
	@echo "  isort      - sort imports according to project conventions"
	@echo "  clean      - clean up project environment and all the build artifacts"

bootstrap: $(VENV)/bin/activate
$(VENV)/bin/activate:
	python3 -m venv $(VENV)
	$(PYTHON) -m pip install poetry
	$(PYTHON) -m poetry install

lint: bootstrap
	$(PYTHON) -m mypy rask_sdk
	$(PYTHON) -m black --check rask_sdk

format: bootstrap
	$(PYTHON) -m black rask_sdk

sort: bootstrap
	$(PYTHON) -m isort rask_sdk
	$(PYTHON) -m asort rask_sdk

clean:
	rm -rf build dist htmlcov *.egg-info .coverage .eggs .pytest_cache .venv .mypy_cache
