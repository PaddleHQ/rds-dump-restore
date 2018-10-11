Feature: backup a mysql database to an S3 bucket
In order to be able to restore a database after a disaster, as a CTO,
Andy would like to have a copy of the contents in an S3 bucket from
where he can easily copy it elsewhere.


  Scenario: don't make a mess if given the wrong password
  given that I have an origin database
    and that I the wrong password for that database
   when my backup task is run
   then it should complain about the wrong password
    and it should not upload a backup file


