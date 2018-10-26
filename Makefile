test: build
	behave --tags '~@future'

wip: build
	behave --wip

build: lint container-test containers

lint:
	find . -name '*.py' | xargs flake8 --max-line-length=100 --builtins=given,when,then \
		--ignore=F811
	find . -name '*.yaml' -name '*.yml' | xargs yamllint
	find . -name '*.sh'  | xargs shellcheck --format=gcc

testfix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --diff

fix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --in-place

container-test: 
	$(MAKE) -C mysql-backup-s3 test
	$(MAKE) -C s3-restore-mysql test

containers: 
	$(MAKE) -C mysql-backup-s3
	$(MAKE) -C s3-restore-mysql

.PHONY: build

