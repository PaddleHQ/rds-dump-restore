lint:
	find . -name '*.py' | xargs flake8 --max-line-length=100 --builtins=given,when,then \
		--ignore=F811
	find . -name '*.yaml' -name '*.yml' | xargs yamllint

testfix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --diff

fix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --in-place
