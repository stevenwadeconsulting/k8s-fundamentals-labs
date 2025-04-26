initialise:
	pre-commit --version || brew install pre-commit
	pre-commit install --install-hooks
	pre-commit run -a

serve:
	docker run --rm -it -p 8000:8000 -v ${PWD}:/docs squidfunk/mkdocs-material
