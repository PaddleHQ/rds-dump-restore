Feature: backup the mysql databsae
In order to be able to restore the mysql database

   Background: we have a database to restore and can check it has worked
   given that I have a mysql type database
     and that I have data I can check is correct in my database	 

   Scenario: backup the database restore the data to a new database from that backup
   given that I run a backup on the database
    when I restore that backup to a new database
    then the data from the original database should be in the new database