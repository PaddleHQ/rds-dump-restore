Feature: backup the mysql database
In order to be able to restore the mysql database

   Background: we have a database to restore and can check it has worked
   given I have a mysql type database in my AWS account
     and I have an s3 bucket set up for backup use
     and I have data I can check is correct in my database

   @wip
   Scenario: backup the database then restore the data to a new database
   given I run a backup on the database
    when I restore that backup to a new database
    then the data from the original database should be in the new database

   Scenario: backup the database with encryption then restore with decryption
   given I have a private public key pair
     and that my s3 bucket is empty
    when I run a backup on the database using the public key
     and I restore that backup to a new database using the private key
    then the s3 bucket should not contain unencrypted data
     and the data from the original database should be in the new database

   @future
   Scenario: warn when given an encrypted database to restore
   given I have a public
    when I run a backup on the database using the public key
    when I attempt to restore that backup to a new database
    then I should get a warning that the backup is unreadable and a suggestion to try a key

   @future
   Scenario: database modification by the automated backup operator should fail
   given I am using the database operator credentials
    when I try to modify the production database
    then I should gat a failure
    and the production database should not be modified

   @future
   Scenario: stream huge backups
   given that my database has more data than fits in my tasks disks
    when I run backup and restore
    then the data should be restored successfully

   @future
   Scenario: ensure backups are encrypted
   given that I have a public key for database encryption
    when I run backup 
    then the data in s3 should be encrypted with the matching private key
     and there should be no plaintext data in s3

   @future
   Scenario: ignore aborted backups
   given that a previous backup aborted just before completing upload
     and and that there is an older backup
    when my restore task is run
    then that older backup should be restored
