import boto3
import urllib.request
import urllib.error

REGION = "us-east-2"

TAG_MAIN = "module-11"
TAG_TEMPLATE = "module-11-template"

ec2 = boto3.client("ec2", region_name=REGION)
rds = boto3.client("rds", region_name=REGION)
asg = boto3.client("autoscaling", region_name=REGION)
secrets = boto3.client("secretsmanager", region_name=REGION)


grandTotal = 0


def print_result(test_name, required, actual, passed, hint=""):
    global grandTotal

    print("=" * 70)
    print(f"Test: {test_name}")
    print(f"Required: {required}")
    print(f"Actual: {actual}")

    if passed:
        print("Result: PASS")
        grandTotal += 1
    else:
        print("Result: FAIL")
        print(f"Hint: {hint}")

    print()


# 1. AMI tagged module-11-template
images = ec2.describe_images(
    Owners=["self"],
    Filters=[
        {"Name": "tag:Name", "Values": [TAG_TEMPLATE]},
        {"Name": "state", "Values": ["available"]},
    ],
)["Images"]

print_result(
    "Check that there is 1 AMI tagged module-11-template",
    1,
    len(images),
    len(images) == 1,
    "Check aws_ami_from_instance and make sure AMI tag Name = module-11-template.",
)


# 2. RDS Snapshot tagged module-11-template
snapshots = rds.describe_db_snapshots(SnapshotType="manual")["DBSnapshots"]

snapshot_count = 0

for snap in snapshots:
    arn = snap["DBSnapshotArn"]
    tags = rds.list_tags_for_resource(ResourceName=arn)["TagList"]
    if any(t["Key"] == "Name" and t["Value"] == TAG_TEMPLATE for t in tags):
        snapshot_count += 1

print_result(
    "Check that there is 1 RDS Snapshot tagged module-11-template",
    1,
    snapshot_count,
    snapshot_count == 1,
    "Check aws_db_snapshot and make sure snapshot tag Name = module-11-template.",
)


# 3. RDS Instance tagged module-11
dbs = rds.describe_db_instances()["DBInstances"]

rds_count = 0

for db in dbs:
    arn = db["DBInstanceArn"]
    tags = rds.list_tags_for_resource(ResourceName=arn)["TagList"]
    if any(t["Key"] == "Name" and t["Value"] == TAG_MAIN for t in tags):
        rds_count += 1

print_result(
    "Check that there is 1 RDS Instance tagged module-11",
    1,
    rds_count,
    rds_count == 1,
    "Check aws_db_instance and make sure RDS tag Name = module-11.",
)


# 4. DB subnet group tagged module-11
subnet_groups = rds.describe_db_subnet_groups()["DBSubnetGroups"]

db_subnet_group_count = 0

for group in subnet_groups:
    arn = group["DBSubnetGroupArn"]
    tags = rds.list_tags_for_resource(ResourceName=arn)["TagList"]
    if any(t["Key"] == "Name" and t["Value"] == TAG_MAIN for t in tags):
        db_subnet_group_count += 1

print_result(
    "Check that there is 1 Database subnet group tagged module-11",
    1,
    db_subnet_group_count,
    db_subnet_group_count == 1,
    "Check aws_db_subnet_group and make sure tag Name = module-11.",
)


# 5. Security Groups tagged module-11
security_groups = ec2.describe_security_groups(
    Filters=[
        {"Name": "tag:Name", "Values": [TAG_MAIN]},
    ]
)["SecurityGroups"]

print_result(
    "Check that there are 2 Security Groups tagged module-11",
    2,
    len(security_groups),
    len(security_groups) == 2,
    "Check that only 2 security groups have tag Name = module-11.",
)


# 6. HTTP check returns 200
instances_response = ec2.describe_instances(
    Filters=[
        {"Name": "tag:Name", "Values": [TAG_MAIN]},
        {"Name": "instance-state-name", "Values": ["running"]},
    ]
)

public_ips = []

for reservation in instances_response["Reservations"]:
    for instance in reservation["Instances"]:
        if "PublicIpAddress" in instance:
            public_ips.append(instance["PublicIpAddress"])

http_pass = False
working_url = "None"

for ip in public_ips:
    url = f"http://{ip}"
    try:
        response = urllib.request.urlopen(url, timeout=5)
        if response.status == 200:
            http_pass = True
            working_url = url
            break
    except Exception:
        pass

print_result(
    "Check that the HTTP check returns HTTP 200",
    "HTTP 200 from at least one EC2 public IP",
    working_url if http_pass else "No HTTP 200 found",
    http_pass,
    "Check port 80 in security group, public subnet, route table, internet gateway, and nginx user_data.",
)


# 7. EC2 instances tagged module-11
ec2_count = len(public_ips)

print_result(
    "Check that there are 3 EC2 instances tagged module-11",
    3,
    ec2_count,
    ec2_count == 3,
    "Check standalone EC2 + ASG desired capacity. Total running EC2 with Name = module-11 must be exactly 3.",
)


# 8. Secrets Manager secrets tagged module-11
all_secrets = secrets.list_secrets()["SecretList"]

secret_count = 0

for secret in all_secrets:
    tags = secret.get("Tags", [])
    if any(t["Key"] == "Name" and t["Value"] == TAG_MAIN for t in tags):
        secret_count += 1

print_result(
    "Check that there are 2 secrets in Secrets Manager tagged module-11",
    2,
    secret_count,
    secret_count == 2,
    "Check aws_secretsmanager_secret and make sure exactly 2 secrets have tag Name = module-11.",
)


# 9. Subnets tagged module-11
subnets = ec2.describe_subnets(
    Filters=[
        {"Name": "tag:Name", "Values": [TAG_MAIN]},
    ]
)["Subnets"]

print_result(
    "Check that there are 3 subnets tagged module-11",
    3,
    len(subnets),
    len(subnets) == 3,
    "Check aws_subnet resources. Exactly 3 subnets should have tag Name = module-11.",
)


# 10. Auto Scaling Group tagged module-11
groups = asg.describe_auto_scaling_groups()["AutoScalingGroups"]

asg_count = 0

for group in groups:
    tags = group.get("Tags", [])
    if any(t["Key"] == "Name" and t["Value"] == TAG_MAIN for t in tags):
        asg_count += 1

print_result(
    "Check that there is one Auto Scaling Group tagged module-11",
    1,
    asg_count,
    asg_count == 1,
    "Check aws_autoscaling_group tag block. ASG should have tag Name = module-11.",
)


print("=" * 70)
print(f"grandTotal score: {grandTotal}/10")
print("=" * 70)
