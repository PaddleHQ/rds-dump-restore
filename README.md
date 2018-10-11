This system is designed to completely dump the data from an RDS
instance to a file in s3 that can then be backed up elsewhere.


## Setting up

* You need to install the latest ansible
* You will need python 3 - probably set up as your default python
* You will need to have your AWS credentials;
   cp TEMPLATE_aws_credentials_admin.yml aws_credentials_ACCOUNT_admin.yml
  where ACCOUNT is the name of your account matching the one in test-backup.yml
* You will need to install the needed python modules

  pip install -r requirements.txt

after that just running

    make

should run the tests

## License and History

The code is a mixture of code from various sources including code from
Ansible (https://github.com/ansible) and from schickling's docker
files (https://github.com/schickling/dockerfiles).  As such some of it
is required to be under the at least the GPLv3 and you should assum
that files are under the AGPL unless mentioned otherwise.  The files
from the dockerfiles collection are in a separated directory and are
MIT licensed.
