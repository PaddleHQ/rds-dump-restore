#! /bin/sh
# file: examples/party_test.sh

mockaws(){
    cat    > mockstmp/aws <<'EOF'
#/bin/sh
echo mysql "$@" >> aws-invocation.log
case "$2" in
     ls)
     	  echo "2018-10-25 15:23:37     595315 2018-10-25T142329Z.sql.gz.gpg"
	  ;;
     cp)
	cp fixtures/2018-10-25T142329Z.sql.gz.gpg dump.sql.gz.gpg
	  ;;
     *)
	echo "Mock aws command: Ignoring unexpected aws command" >&2
esac
exit 0
EOF
    chmod +x mockstmp/aws
    rm -f aws-invocation.log
}


oneTimeSetUp() {
    PATH=$PWD/mockstmp:"$PATH"
    export PATH
}


setUp() {
    export MYSQLDUMP_OPTIONS=--fake-mysql-option
    export MYSQLDUMP_DATABASE=fake-database
    export MYSQL_HOST=fake-host.example.com
    export MYSQL_PORT=3306
    export MYSQL_USER=fakeuser
    export MYSQL_PASSWORD=fakepassword
    export S3_ACCESS_KEY_ID=fakekeyid
    export S3_SECRET_ACCESS_KEY=fake-aws-secret
    export S3_BUCKET=fake-bucket
    export S3_REGION=fake-region
    export S3_ENDPOINT='**None**'
    export S3_S3V4=no
    export S3_PREFIX='backup'
    export S3_FILENAME='**None**'
    export MULTI_FILES=no
    export SCHEDULE='**None**'
    export PRIVATE_KEY="-----BEGIN PGP PRIVATE KEY BLOCK-----\\n\\n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\\n=YRh3\\n-----END PGP PRIVATE KEY BLOCK-----\\n"
    rm -fr mockstmp
    mkdir -p mockstmp
}


testEquality()
{
    ${_ASSERT_EQUALS_} 1 1
}


testFailsMysqlBroken()
{
    (
	# shellcheck disable=SC2030,SC2031
	cat    > mockstmp/mysql <<EOF
#/bin/sh
exit 5
EOF
	chmod +x mockstmp/mysql
	mockaws
	echo where is mysql?
	command -v mysql
	bash ./restore.sh
    )
    ${_ASSERT_EQUALS_} 5 $? 
}


testFailsGPGBroken()
{
    (
	cat    > mockstmp/gpg <<EOF
#/bin/sh
exit 6
EOF
	chmod +x mockstmp/gpg
	mockaws
	echo where is gpg?
	command -v gpg
	bash ./restore.sh
    )
    ${_ASSERT_EQUALS_} 6 $? 
}

testRunsProperly()
{
    (
	cat    > mockstmp/mysql <<'EOF'
#/bin/sh
echo mysql "$@" >> mysql-invocation.log
cat >> mysql-input.log
exit 0
EOF
	mockaws
	chmod +x mockstmp/mysql
	echo where is mysql?
	command -v mysql
	bash ./restore.sh
    )
    RET=$?
    ${_ASSERT_EQUALS_} '"restore script failed unexpectedly"' 0 "$RET"
    grep -qE -e '-h fake-host.example.com -P 3306 -ufakeuser -pfakepassword' mysql-invocation.log
    ${_ASSERT_EQUALS_} '"mysql database credentials not delivered to mysql as expected"' 0 "$?"
    grep -qE -e 'test_backup_restore' mysql-input.log
    ${_ASSERT_EQUALS_} '"failed to dump selected database"' 0 "$?"
}

# load shunit2
# shellcheck disable=SC1091
. /usr/local/bin/shunit2
