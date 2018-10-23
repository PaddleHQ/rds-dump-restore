test: containers lint
	behave --tags '~@future'
wip:
	behave --wip


lint:
	find . -name '*.py' | xargs flake8 --max-line-length=100 --builtins=given,when,then \
		--ignore=F811
	find . -name '*.yaml' -name '*.yml' | xargs yamllint
	find . -name '*.sh'  | xargs shellcheck --format=gcc

testfix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --diff

fix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --in-place

containers: 
	$(MAKE) -C mysql-backup-s3
	$(MAKE) -C s3-restore-mysql
