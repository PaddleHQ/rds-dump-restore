FROM alpine:latest
LABEL maintainer="Michael De La Rue <estodoimg.xklesae@spamgourmet.com>"

ADD install.sh install.sh
RUN sh install.sh && rm install.sh

ENV MYSQL_OPTIONS ''
ENV MYSQL_HOST **None**
ENV MYSQL_PORT 3306
ENV MYSQL_USER **None**
ENV MYSQL_PASSWORD **None**
ENV S3_ACCESS_KEY_ID **None**
ENV S3_SECRET_ACCESS_KEY **None**
ENV S3_BUCKET **None**
ENV S3_REGION us-west-1
ENV S3_ENDPOINT **None**
ENV S3_S3V4 no
ENV S3_PREFIX 'backup'
ENV S3_FILENAME **None**
ENV PRIVATE_KEY **None**

ADD run.sh run.sh
ADD restore.sh restore.sh

CMD ["sh", "run.sh"]
