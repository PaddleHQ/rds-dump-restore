from __future__ import print_function

import subprocess
import sys
import random
import string
from hamcrest import assert_that, equal_to, is_not
from subprocess import run
import boto3


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def call_ansible_step(step_name, playbook="test-system.yml", extra_vars=None):
    """call_ansible_step - run a step by running a matching ansible tag"""

    proc_res = subprocess.run(args=["ansible-playbook", "--list-tags", playbook],
                              capture_output=True)
    if proc_res.returncode > 0:
        eprint("Ansible STDOUT:\n", proc_res.stdout, "Ansible STDERR:\n", proc_res.stderr)
        raise Exception("ansible failed while listing tags")

    lines = [x.lstrip() for x in proc_res.stdout.split(b"\n")]
    steps_lists = [x[10:].rstrip(b"]").lstrip(b"[ ").split(b",")
                   for x in lines if x.startswith(b"TASK TAGS:")]
    steps = [x.lstrip() for y in steps_lists for x in y]
    eprint(b"\n".join([bytes(x) for x in steps]))
    if bytes(step_name, 'latin-1') not in steps:
        raise Exception("Ansible playbook: `" + playbook + "' missing tag: `" + step_name + "'")

    eprint("calling ansible with: ", step_name)
    ansible_args = ["ansible-playbook", "-vvv", "--tags", step_name, playbook]
    if extra_vars is not None:
        ansible_args.extend(["--extra-vars", extra_vars])
    proc_res = subprocess.run(args=ansible_args, capture_output=True)
    eprint("Ansible STDOUT:\n", proc_res.stdout, "Ansible STDERR:\n", proc_res.stderr)
    if proc_res.returncode > 0:
        raise Exception("ansible failed")


@given(u'that I have a mysql type database')
def step_impl(context):
    call_ansible_step(context.this_step.step_type + " " + context.this_step.name,
                      playbook="test-backup.yml")


@given(u'that I have data I can check is correct in my database')
def step_impl(context):
    call_ansible_step("given that I have verification lambdas prepared",
                      playbook="test-backup.yml")
    context.test_key = ''.join(
        [random.choice(string.ascii_letters + string.digits) for n in range(16)])
    payload = b"""{
    "testdata": "%s"
    }""" % context.test_key.encode('utf-8')
    client = boto3.client('lambda')
    response = client.invoke(
        FunctionName="db_set_data",
        Payload=payload
    )
    assert_that(response["StatusCode"], equal_to(200))
    assert_that(response["FunctionError"], is_not(equal_to("Unhandled")))


@then(u'the data from the original database should be in the new database')
def step_impl(context):
    payload = b"""{
    "testdata": "%s"
    }""" % context.test_key.encode('utf-8')
    client = boto3.client('lambda')
    response = client.invoke(
        FunctionName="db_check_data",
        Payload=payload
    )
    assert_that(response["StatusCode"], equal_to(200))
    assert_that(response["FunctionError"], is_not(equal_to("Unhandled")))


@when(u'I restore that backup to a new database')
def step_impl(context):
    call_ansible_step("create restore database", playbook="test-backup.yml")
    run(["fargate", "task", "run", "restore", "--image", "schickling/mysql-backup-s3"])


@given(u'that I run a backup on the database')
def step_impl(context):
    run(["fargate", "task", "run", "backup", "--image", "schickling/mysql-backup-s3"])
