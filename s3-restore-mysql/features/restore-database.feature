Feature: backup a mysql database to an S3 bucket
In order to be able to restore a database after a disaster, as a CTO,
Andy would like to have a copy of the contents in an S3 bucket from
where he can easily copy it elsewhere.

  Scenario: find the latest valid backup even if one is corrupt
  given that I have a database backup in my s3 bucket
    and that there is a newer corrupt backup
   when my restore task is run
   then it should complain about the wrong password
    and it should not upload a backup file

