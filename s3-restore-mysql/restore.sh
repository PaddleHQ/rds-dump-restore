#! /bin/sh

echo "Restore script started"

# "BUG": this exposes the private key if used in decrypt mode - this
# is fine for testing whether backups have worked, however in a real
# recovery situation, only the session key used for encrypting this
# particular data should be sent in, not a private key that could be
# used for other past and future data.

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

# we use this without arguments but might add them in future so ignore shellcheck warnings.
# shellcheck disable=SC2120
my_mysql() {
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$@"
}


restore_from_file() {
    ( set -o pipefail
    THE_DUMP_FILE=$2
    if [ "${ENCRYPT}" = "false" ]
    then
	# shellcheck disable=SC2016,SC2119
	gzip -dc "$THE_DUMP_FILE" | sed -e '/-- Current Database: `mysql`/,/-- Current Database:/d' | my_mysql
    else
	# shellcheck disable=SC2016,SC2119
	gpg --homedir /tmp/gnupg --recipient "${KEYID}" --decrypt < "$THE_DUMP_FILE" | gzip -dc | sed -e '/-- Current Database: `mysql`/,/-- Current Database:/d' | my_mysql
    fi )
}

if [ "${PRIVATE_KEY}" = "**None**" ];
then
    ENCRYPT="false"
else
    ENCRYPT="true"
    # we do want to convert newlines since public keys need them but we
    # don't really want other sequences such as %s since they might
    # appear accidentally;  for now use echo -e but maybe it should be
    # echo | sed ? something based on printf?
    # shellcheck disable=SC2039
    echo -e "${PRIVATE_KEY}" >  my.pri
    # based on
    # https://security.stackexchange.com/questions/86721
    gpg --homedir /tmp/gnupg --import my.pri
    KEYID=$(gpg --batch --with-colons /tmp/a4ff2279.pgp | head -n1 | cut -d: -f5)
fi

echo "Finding latest backup"

LATEST_BACKUP=$(aws s3 ls s3://"$S3_BUCKET"/"$S3_PREFIX"/ | sort | tail -n 1 | awk '{ print $4 }')

echo "Fetching ${LATEST_BACKUP} from S3"

aws s3 cp "s3://$S3_BUCKET/$S3_PREFIX/${LATEST_BACKUP}" dump.sql.gz

# TODO:
# echo "Restoring dump for ${MYSQLDUMP_DATABASE} to ${MYSQL_HOST}..."

echo "Restoring dump to ${MYSQL_HOST}..."

set -o pipefail

if restore_from_file dump.sql.gz
then
    echo "SQL restore finished"
else
    echo "SQL restore failed!!!"
fi
