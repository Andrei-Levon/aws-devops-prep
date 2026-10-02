# AWS DevOps Interview Preparation

A modular, production-aligned infrastructure project built with Terraform on AWS, designed for hands-on interview preparation.

---

## Architecture Overview

```
                      [ INTERNET ]
                           │
                 [ Internet Gateway (IGW) ]
                           │
       ┌───────────────────┴───────────────────────┐
       │ VPC: 10.0.0.0/16 (eu-central-1)           │
       │                                           │
       │   Public Subnet: 10.0.1.0/24 (eu-central-1a)
       │   ┌───────────────────────────────────┐   │
       │   │ Security Group (Port 80 Ingress)  │   │
       │   │                                   │   │
       │   │   [ EC2: t3.micro (Amazon Linux) ]│   │
       │   │   - Python 3 http.server (:80)    │   │
       │   │   - State: running / stopped      │   │
       │   └───────────────────────────────────┘   │
       └───────────────────────────────────────────┘
```

- **Remote Backend**: Amazon S3 (`tfstate-406526694439-eu-central-1`) with native state locking (`use_lockfile = true`), eliminating the need for a DynamoDB lock table.
- **Networking**: Custom VPC with an Internet Gateway, Public Subnet, and explicit Route Table association.
- **Compute**: EC2 `t3.micro` provisioned via `user_data` running a lightweight Python 3 web server.

---

## Operational Commands

Navigate to the terraform directory:
```bash
cd terraform
```

### 1. Stop the EC2 Server (Save Costs Without Deleting)
When you are done testing, turn off the server. The EBS disk and network configurations stay intact, but compute and public IPv4 charges stop:
```bash
terraform apply -var="server_state=stopped"
```

### 2. Turn the Server Back On
To power it back on for a practice session:
```bash
terraform apply -var="server_state=running"
```

### 3. Full Teardown
To destroy all AWS infrastructure when no longer needed:
```bash
terraform destroy
```

---

## Key Interview Talking Points

1. **Native S3 State Locking (Terraform >= 1.10)**:
   - *Traditional*: S3 (storage) + DynamoDB (distributed lock with partition key `LockID`).
   - *Modern*: `use_lockfile = true` uses Amazon S3 conditional writes (`PutObject` with `If-None-Match`), removing DynamoDB overhead and cost.

2. **Internet Gateway (IGW) vs. NAT Gateway (NGW)**:
   - **IGW**: VPC-level, bidirectional (1:1 static NAT for public subnets), **$0.00/hour**.
   - **NAT Gateway**: Resides in a public subnet to provide outbound-only internet access (SNAT) for private subnets, **~$32+/month**.

3. **Subnet Sizing & AWS Reserved IPs**:
   - A `/24` subnet has $2^{(32-24)} = 256$ IPs.
   - **AWS reserves 5 IPs** in every subnet (`.0` network, `.1` VPC router, `.2` Amazon DNS, `.3` future use, `.255` broadcast). Usable: **251 IPs**.
