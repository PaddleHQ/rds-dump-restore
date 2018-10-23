#!/bin/sh

echo "Backup script started"

set -e

if [ "${S3_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "Warning: You did not set the S3_ACCESS_KEY_ID environment variable."
fi

if [ "${S3_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "Warning: You did not set the S3_SECRET_ACCESS_KEY environment variable."
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" = "**None**" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" = "**None**" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" = "**None**" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [ "${S3_IAMROLE}" != "true" ]; then
  # env vars needed for aws tools - only if an IAM role is not used
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION
fi

my_mysql() {
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$@"
}

my_mysqldump() {
    # ash shell does not support arrays and we need to get the mysql dump
    # options in from the docker file so the least nasty way to do this is, to
    # have an unquoted variable as far as I can see.  Make sure it doesn't come
    # in from an untrusted source, which, in the original application I assume
    # it can't.
    # 
    # shellcheck disable=SC2086
    mysqldump "$MYSQL_HOST" -P "$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" $MYSQLDUMP_OPTIONS "$@"
}

dump_to_file() {
    ( set -o pipefail
    THE_DB=$1
    THE_DUMP_FILE=$2
    if [ "${ENCRYPT}" = "false" ]
    then
	my_mysqldump --databases "$THE_DB" | gzip > "$THE_DUMP_FILE"
    else
	my_mysqldump --databases "$THE_DB" | gzip -9 |
	      gpg --homedir /tmp/gnupg --recipient "${KEYID}" --encrypto > "$THE_DUMP_FILE"
    fi )
}

if [ "${S3_FILENAME}" = "**None**" ]
then
    S3_FILENAME=$(date +"%Y-%m-%dT%H%M%SZ")
fi

SUFFIX=".sql.gz"
if [ "${PUBLIC_KEY}" = "**None**" ];
then
    ENCRYPT="false"
else
    SUFFIX="$SUFFIX.gpg"
    ENCRYPT="true"

    # we do want to convert newlines since public keys need them but we
    # don't really want other sequences such as %s since they might
    # appear accidentally;  for now use echo -e but maybe it should be
    # echo | sed ? something based on printf?
    # shellcheck disable=SC2039
    echo -e "${PUBLIC_KEY}" >  my.pub
    # based on
    # https://security.stackexchange.com/questions/86721
    umask 077
    mkdir -p /tmp/gnupg
    gpg --homedir /tmp/gnupg --import my.pub
    KEYID=$(gpg --batch --with-colons /tmp/a4ff2279.pgp | head -n1 | cut -d: -f5)
fi


copy_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" = "**None**" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  echo "Uploading ${DEST_FILE} to S3..."

  

  if ! aws "${AWS_ARGS}" s3 cp "${SRC_FILE}" "s3://${S3_BUCKET}/${S3_PREFIX}/${DEST_FILE}" 
  then
    >&2 echo "Error uploading ${DEST_FILE} to S3"
  fi

  rm "${SRC_FILE}"
}

if echo "${MULTI_FILES}" | grep -q -i -E "(yes|true|1)"
then
  # Multi file: yes
  if [ "${MYSQLDUMP_DATABASE}" = "--all-databases" ]; then
    DATABASES=$(my_mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys|innodb)")
  else
    DATABASES="$MYSQLDUMP_DATABASE"
  fi

  for DB in $DATABASES; do
    echo "Creating individual dump of ${DB} from ${MYSQL_HOST}..."

    S3_FILE="${S3_FILENAME}.${DB}.${SUFFIX}"
    DUMP_FILE="/tmp/${DB}.${SUFFIX}"


    if dump_to_file "${DB}" "${DUMP_FILE}"
    then
      copy_s3 "$DUMP_FILE" "$S3_FILE"
    else
      >&2 echo "Error creating dump of ${DB}"
    fi
  done
else
  # Multi file: no
  echo "Creating dump for ${MYSQLDUMP_DATABASE} from ${MYSQL_HOST}..."

  S3_FILE="${S3_FILENAME}.${SUFFIX}"
  DUMP_FILE="/tmp/dump.${SUFFIX}"

  if dump_to_file "${MYSQLDUMP_DATABASE}" "${DUMP_FILE}"
  then
    copy_s3 "$DUMP_FILE" "$S3_FILE"
  else
    >&2 echo "Error creating dump of all databases"
  fi
fi

echo "SQL backup finished"
