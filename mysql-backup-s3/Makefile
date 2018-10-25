TIMESTAMPFILE := $(shell mktemp)

build: Dockerfile backup.sh install.sh run.sh
	docker build . -t paddlehq/mysql-backup-s3
	docker image push paddlehq/mysql-backup-s3
	cp -p $(TIMESTAMPFILE) build

test:
	bash test.sh
