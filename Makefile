test:
	behave --tags '~@future'

wip:
	behave --wip


lint:
	find . -name '*.py' | xargs flake8 --max-line-length=100 --builtins=given,when,then \
		--ignore=F811
	find . -name '*.yaml' -name '*.yml' | xargs yamllint

testfix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --diff

fix:
	find . -name '*.py' | xargs autopep8 --aggressive --max-line-length=100 --in-place


containers:
	docker build mysql-backup-s3 -t paddlehq/mysql-backup-s3
	docker build s3-restore-mysql -t paddlehq/s3-restore-mysql
	docker image push paddlehq/mysql-backup-s3
	docker image push paddlehq/s3-restore-mysql

