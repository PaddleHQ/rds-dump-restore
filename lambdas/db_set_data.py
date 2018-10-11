from __future__ import print_function
import json
import os
import mysql.connector

"""db_check_lambda - check that a database is actually correctly restored

this lambda is designed to provide simple verification that a backup
and restore has succeeded.  It is called with one parameter -
`testdata` which contains the data it expects to find when it runs:

    SELECT value FROM test_backup_restore WHERE key = 'testdata'

"""

"""
This program is based on code included in Ansible and is licensed
under the AGPLv3.  It links with the Oracle mysql client licenses
under the The Universal FOSS Exception, Version 1.0

  https://oss.oracle.com/licenses/universal-foss-exception/

"""


user = os.environ["DB_USER"]
password = os.environ["DB_PASSWORD"]
host = os.environ["DB_HOST"]
database = os.environ["DB_DATABASE"]


def handler(event, context):
    """
    The handler function is the function which gets called each time
    the lambda is run.
    """
    # printing goes to the cloudwatch log allowing us to simply debug the lambda if we can find
    # the log entry.
    print("got event:\n" + json.dumps(event))

    # if the testdata parameter isn't present this can throw an exception
    # which will result in an amazon chosen failure from the lambda
    # which can be completely fine.

    testdata = event["testdata"]

    cnx = mysql.connector.connect(user=user, password=password, host=host,
                                  database=database, connection_timeout=5)
    try:
        cursor = cnx.cursor()
        create = ("CREATE TABLE IF NOT EXISTS `test_backup_restore` ("
                  "  `thekey` varchar(20) NOT NULL,"
                  "  `thevalue` varchar(40) NOT NULL,"
                  "  PRIMARY KEY (`thekey`)"
                  ")")
        cursor.execute(create)
        delete = ("DELETE FROM test_backup_restore "
                  " WHERE `thekey` = 'testdata' ;")
        cursor.execute(delete)
        insert = ("INSERT INTO test_backup_restore "
                  " ( `thekey`, `thevalue` )"
                  " VALUES "
                  " ( 'testdata', %s ) ;")
        cursor.execute(insert, (testdata,))
        cnx.commit()

    finally:
        cursor.close()
        cnx.close()

    return {"result": "inserted test data: " + testdata + " into database"}


def main():
    """
    This main function will normally never be called during normal
    lambda use.  It is here for testing the lambda program only.
    """
    event = {"testdata": "abc123"}
    context = None
    print(handler(event, context))


if __name__ == '__main__':
    main()
