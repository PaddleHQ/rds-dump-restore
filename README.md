This system is designed to completely dump the data from an RDS
instance to a file in s3 that can then be backed up elsewhere.

## Setting up for local development

* You will need to install

   - shunit2
   - latest ansible
   - python3 - set as the default pytnon (venv later()
   - mysql clients including mysqldump

* You will need to have a custom version of the fargate command

  https://github.com/jpignata/fargate/pull/65

* You will need to have your AWS credentials;
   cp TEMPLATE_aws_credentials_admin.yml aws_credentials_ACCOUNT_admin.yml
  where ACCOUNT is the name of your account matching the one in test-backup.yml

* you will need to have the gpgme python bindings installed which has
  to come with your operating system or will not be compatible; for example: 

  Homebrew:
	https://github.com/Homebrew/homebrew-core/pull/33129
  Alpine
	https://github.com/alpinelinux/aports/pull/5387

* You will need to install the needed python modules

  pip install -r requirements.txt --system-site-packages

* You will need to be logged into dockerhub

(alternatively you can create without system site packages and make a
symbolic link into )

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
