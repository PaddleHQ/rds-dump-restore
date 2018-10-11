from __future__ import print_function

import subprocess
import sys
import random
import string
from hamcrest import assert_that, equal_to, not_, has_key
from subprocess import run
import boto3
import logging
from dotenv import dotenv_values


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


@given(u'I have an s3 bucket set up for backup use')
@given(u'I have IAM configured for backups')
@given(u'I have a mysql type database')
def step_impl(context):
    call_ansible_step(context.this_step.step_type + " " + context.this_step.name,
                      playbook="test-backup.yml")


@given(u'I have a mysql type database in my AWS account')
def step_impl(context):
    context.execute_steps(u"""
    Given I have IAM configured for backups
     and I have a mysql type database
    """)


@given(u'I have data I can check is correct in my database')
def step_impl(context):
    call_ansible_step("given I have verification lambdas prepared",
                      playbook="test-backup.yml")
    context.test_key = ''.join(
        [random.choice(string.ascii_letters + string.digits) for n in range(16)]).encode('utf-8')
    payload = b"""{
    "testdata": "%s"
    }""" % context.test_key
    client = boto3.client('lambda')
    response = client.invoke(
        FunctionName="db_set_data",
        Payload=payload
    )
    assert_that(response["StatusCode"], equal_to(200))
    assert_that(response, not_(has_key("FunctionError")))


@then(u'the data from the original database should be in the new database')
def step_impl(context):
    payload = b"""{
    "testdata": "%s"
    }""" % context.test_key
    client = boto3.client('lambda')
    response = client.invoke(
        FunctionName="db_check_data",
        Payload=payload
    )
    assert_that(response["StatusCode"], equal_to(200))
    assert_that(response, not_(has_key("FunctionError")))


def run_fargate_with_envfile(envfile, image="paddlehq/mysql-backup-s3"):
    task_name = image.replace("/", "_")
    env_vars = dotenv_values(envfile)
    call_env = []
    for key, value in env_vars.items():
        call_env += ["-e", "%s=%s" % (key, value)]

    security_group = env_vars["DB_SECURITY_GROUP"]
    subnet = env_vars["DB_SUBNET_ID"]
    region = env_vars["AWS_REGION"]

    call_args = ["fargate", "--verbose", "task", "run", task_name, "--image", image,
                 "--region", region, "--security-group-id", security_group,
                 "--subnet-id", subnet]
    call_args += call_env
    logging.info(" ".join(call_args))
    run(call_args)
    run(["fargate", "task", "wait", task_name, "--region", region])


@given(u'I run a backup on the database')
def step_impl(context):
    call_ansible_step("given that I have configured environment definitions",
                      playbook="test-backup.yml")
    run_fargate_with_envfile('backup-task-environment', image="paddlehq/mysql-backup-s3")


@when(u'I restore that backup to a new database')
def step_impl(context):
    call_ansible_step("given that I have configured environment definitions",
                      playbook="test-backup.yml")
    run_fargate_with_envfile('restore-task-environment', image="paddlehq/s3-restore-mysql")


@given(u'I am using the database operator credentials')
def step_impl(context):
    raise NotImplementedError(u'STEP: Given I am using the database operator credentials')


@when(u'I try to modify the production database')
def step_impl(context):
    raise NotImplementedError(u'STEP: When I try to modify the production database')


@then(u'I should gat a failure')
def step_impl(context):
    raise NotImplementedError(u'STEP: Then I should gat a failure')


@then(u'the production database should not be modified')
def step_impl(context):
    raise NotImplementedError(u'STEP: Then the production database should not be modified')
