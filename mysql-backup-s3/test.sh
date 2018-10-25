#! /bin/sh
# file: examples/party_test.sh


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
    export PUBLIC_KEY="-----BEGIN PGP PUBLIC KEY BLOCK-----\\n\\nmQGNBFvRZYoBDAD0rIMMNnPbYu/hGNwJEN8dKGDKcH8He2PlitQ+LuMBAnQDKF2T\\nAKRqAqJIOxIMHKu+AYDENBEP1J0hQ3DI62FkO02T9NlrMpzOtlu+sfFxIdf7I6xd\\ns/qvLs0TKe8uoHDmHcy5cXLZ74uZKPym959wsA37vH9uvymFv7i754ZflaENqiOl\\nOFozSQvKpCFBAbMHXmnbjD9OObw2Gkk0/E2EFnRygB7yGurWCXeSJ/0BU1QRy741\\nI+ygWImvys1hLve5F9WoR+jiPfdB0qBJN7d92qHJbvVRdBt6lVWJ6sbPMN5otyVD\\nf6PXI7ZLAyTEckw0OS7SL4dJqWFuRfELAh+bj07b0EPbe/zA/WOnMx3eXm9kqSg4\\nmiHYofqXibQ/tvzfqR5TbHXaOL6RwI3HKb0e9KZNpPFODDDNIzbZQKEWus2etQYY\\ncv3Wstso46zp6Q7hJUzNSxqjugMQjqpd1F2k+omxiaT3iWPpyRoEl/1q1QThOma+\\nekyrzyPEC5pd8zsAEQEAAbQRYmFja3VwLUExWnVrZnVpMU2JAdQEEwEIAD4WIQQo\\nvrUy1NrndBIyUa+3A2PlN1Jv4QUCW9FligIbDQUJAeEzgAULCQgHAgYVCgkICwIE\\nFgIDAQIeAQIXgAAKCRC3A2PlN1Jv4TgzC/wIDqC9ZaoifsKb56+T+1/SDDY+P18z\\nf/kRRVKlS0BX3SOfUQFYnnJTzYTF0YFBtWc6hA4RQXS00SYrNm0R5N1EaPzZCj8+\\n5f1QTYYkvkKhHMWOKsxyENS+ycR715WbmpK6hzIGvst0tr8RllDnpv2jhgeSrY8a\\n9JJ0A4qZ0TWQjobvzHqJeGV3LHTTTP6SzXUjgswLw8A0Vyy+nemFgz4G4bxX+SnC\\n/r/zTN82VYeGxHV5UI8hLhMitWuQg1ksfzhMMdIb6Fg64iVKxNEVdcWHLlNZuATI\\ncyoVCHECy9UIffcG+NGgfGJuGReUOmQ+cejAkTt/0Tgd3u2thh4nZ8i3W8/Ojyub\\nayz4lM86lQ3g5gWryGdGwyoURU9QnSFv7+i5Qt4GWRaf0jr3MKpDR4vs8OkMzGxC\\nuHI8Ffv8bhwt2USfLGaW3F/GDL1fWQ48dyN63RD1lxle+h1CKCk5GLY+pmN7jnV1\\nwFNdALXHiWwa5aWi4s3lknGrQOFISM9lhCE=\\n=8aLI\\n-----END PGP PUBLIC KEY BLOCK-----\\n"
    rm -r mokstmp
    mkdir -p mockstmp
}



testEquality()
{
    ${_ASSERT_EQUALS_} 1 1
}


testFailsMysqldumpBroken()
{
    (
	# shellcheck disable=SC2030,SC2031
	cat    > mockstmp/mysqldump <<EOF
#/bin/sh
exit 5
EOF
	chmod +x mockstmp/mysqldump
	echo where is mysqldump?
	command -v mysqldump
	setup_env
	bash ./backup.sh
    )
    ${_ASSERT_EQUALS_} 5 $? 
    rm mockstmp/mysqldump
}


testFailsGPGBroken()
{
    (
	cat    > mockstmp/gpg <<EOF
#/bin/sh
exit 6
EOF
	chmod +x mockstmp/gpg
	echo where is gpg?
	command -v gpg
	setup_env
	bash -vx ./backup.sh
    )
    ${_ASSERT_EQUALS_} 6 $? 
    rm mockstmp/gpg
}

testRunsProperlyOneDB()
{
    (
	cat    > mockstmp/mysqldump <<'EOF'
#/bin/sh
echo mysqldump "$@" >> mysqldump-invocation.log
echo "COMMIT;"
exit 0
EOF
	rm  mysqldump-invocation.log
	chmod +x mockstmp/mysqldump
	echo where is mysqldump?
	command -v mysqldump
	setup_env
	bash ./backup.sh
    )
    ${_ASSERT_EQUALS_} '"backup script failed unexpectedly"' 0 $? 
    grep -qE -e '--all-databases' mysqldump-invocation.log
    ${_ASSERT_EQUALS_} '"called with --all-databases when should be (only) --database"' 1 $? 
    grep -qE -e '--password |-p ' mysqldump-invocation.log
    ${_ASSERT_EQUALS_} '"bare password argument passed to mysqldump - will fail"' 1 $? 
    grep -qE -e '--databases.fake-database' mysqldump-invocation.log
    ${_ASSERT_EQUALS_} '"failed to dump selected database"' 0 $? 
    rm mockstmp/mysqldump
}

testRunsProperlyAllDB()
{
    (
	cat    > mockstmp/mysqldump <<'EOF'
#/bin/sh
echo mysqldump "$@" >> mysqldump-invocation.log
echo "COMMIT;"
exit 0
EOF
	rm  mysqldump-invocation.log
	chmod +x mockstmp/mysqldump
	echo where is mysqldump?
	command -v mysqldump
	setup_env
	export MYSQLDUMP_DATABASE=--all-databases
	bash ./backup.sh
    )
    ${_ASSERT_EQUALS_} '"backup script failed unexpectedly"' 0 $? 
    grep -qE -e '--all-databases' mysqldump-invocation.log
    ${_ASSERT_EQUALS_} '"failed to dump all databases"' 0 $? 
    grep -qE -e '--password |-p ' mysqldump-invocation.log
    ${_ASSERT_EQUALS_} '"bare password argument passed to mysqldump - will fail"' 1 $? 
    grep -qE -e '--databases' mysqldump-invocation.log
    ${_ASSERT_EQUALS_} '"called with --databases when should be (only) --all-databases"' 1 $? 
    rm mockstmp/mysqldump
}


# load shunit2
# shellcheck disable=SC1091
. /usr/local/bin/shunit2
