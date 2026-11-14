import subprocess
import json
import concurrent.futures


def call(service, action, region=None):
    a = ["aws", service, action, "--output", "json"]
    if region:
        a += ["--region", region]
    if service == "iam" and action == "list-policies":
        a += ["--scope", "Local"]
    p = subprocess.run(a, capture_output=True)
    return (
        json.loads(p.stdout or b"{}")
        if p.returncode == 0
        else {"inventory_error": p.stderr.decode().split(":")[-1].strip()}
    )


regions = call("ec2", "describe-regions", "eu-west-1")
if "Regions" not in regions:
    raise SystemExit("Unable to enumerate regions")
checks = [
    ("lambda", "list-functions"),
    ("ec2", "describe-instances"),
    ("ec2", "describe-volumes"),
    ("ec2", "describe-addresses"),
    ("ec2", "describe-vpcs"),
    ("rds", "describe-db-instances"),
    ("ecs", "list-clusters"),
    ("eks", "list-clusters"),
    ("cloudformation", "describe-stacks"),
    ("logs", "describe-log-groups"),
    ("secretsmanager", "list-secrets"),
    ("apigateway", "get-rest-apis"),
    ("apigatewayv2", "get-apis"),
    ("events", "list-rules"),
    ("sns", "list-topics"),
    ("sqs", "list-queues"),
    ("dynamodb", "list-tables"),
    ("ecr", "describe-repositories"),
    ("elbv2", "describe-load-balancers"),
    ("elb", "describe-load-balancers"),
    ("ec2", "describe-subnets"),
    ("ec2", "describe-route-tables"),
    ("ec2", "describe-internet-gateways"),
    ("ec2", "describe-security-groups"),
    ("ec2", "describe-network-acls"),
    ("ec2", "describe-nat-gateways"),
    ("ec2", "describe-network-interfaces"),
    ("ec2", "describe-vpc-endpoints"),
    ("ec2", "describe-key-pairs"),
]
jobs = [(s, a, r["RegionName"]) for r in regions["Regions"] for s, a in checks]
jobs += [
    (s, a, None)
    for s, a in [
        ("iam", "list-users"),
        ("iam", "list-roles"),
        ("iam", "list-policies"),
        ("s3api", "list-buckets"),
        ("route53", "list-hosted-zones"),
        ("cloudfront", "list-distributions"),
    ]
]
results = {}
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
    futures = {pool.submit(call, *j): j for j in jobs}
    for f in concurrent.futures.as_completed(futures):
        j = futures[f]
        results["/".join(x or "global" for x in j)] = f.result()
enc = subprocess.run(
    [
        "sops",
        "--encrypt",
        "--input-type",
        "json",
        "--output-type",
        "yaml",
        "--pgp",
        "47E4999BED565F9874AA0E7C05DA03D000FC10D1",
        "/dev/stdin",
    ],
    input=json.dumps(results).encode(),
    capture_output=True,
    check=True,
).stdout
open("inventory.sops.yaml", "wb").write(enc)
for k, v in results.items():
    if "inventory_error" in v:
        print(k + ": ERROR")
    else:
        counts = {a: len(b) for a, b in v.items() if isinstance(b, list) and b}
        if counts:
            print(k + ": " + str(counts))
