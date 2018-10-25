TIMESTAMPFILE := $(shell mktemp)

build: Dockerfile restore.sh install.sh run.sh
	docker build . -t paddlehq/s3-restore-mysql
	docker image push paddlehq/s3-restore-mysql
	cp -p $(TIMESTAMPFILE) build

test:
	bash test.sh
