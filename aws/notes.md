# AWS Notes

## Overview

### AWS Types of Services

- On demand
- Shared responsibility
- Upfront cost

### AWS Advantages

- Pay as you go
- Scalability
- No infrastructure cost
- 24/7 availability
- Data Security

---

## Authentication & Authorization

### MFA (Multi-Factor Authentication)

- Passkey or security key
- Authenticator app
- Hardware TOTP Token

### Sign In Options

- **Root user**: Full access
- **IAM user**: Least privilege

**Process**: Authentication → Authorization

---

## Compute Services

### EC2 (Elastic Compute Cloud)

**Pricing Models**:

- On demand
- Shared
- Pricing
- Spot

---

## Storage & Data

### Types of Data

- Structured
- Unstructured
- Semi-structured

### Data Lake (S3)

- Primary storage service for data lakes

### AWS Pricing Formula

```
Total Cost = Compute + Storage + Data OUT
```

### S3 Storage Classes

| Storage Class           | Cost     | Purpose                                       | Access Speed     |
| ----------------------- | -------- | --------------------------------------------- | ---------------- |
| S3 Standard             | High     | Frequently accessed data                      | Milliseconds     |
| S3 Intelligent-Tiering  | Medium   | Data with unknown or changing access patterns | Milliseconds     |
| S3 Standard-IA          | Lower    | Infrequently accessed but important           | Milliseconds     |
| S3 One Zone-IA          | Cheaper  | Infrequent, non-critical data                 | Milliseconds     |
| S3 Glacier              | Very Low | Archive — access in minutes/hours             | Minutes to hours |
| S3 Glacier Deep Archive | Lowest   | Cold storage — long-term archive              | 12–48 hours      |

**Note**: S3 is durable with 11 nines (99.999999999%)

**Hierarchy**: Decreasing price increases speed

---

## Compute Services (Detailed)

### EC2 (Elastic Compute Cloud)

**What is EC2?**

- Provides resizable compute capacity (CPU, memory, storage, networking) on demand
- You pay for compute power according to usage
- **Your laptop → Local server**
- **EC2 → Virtual laptop in AWS data center**

**EC2 Instance**

- The actual virtual server running in the cloud
- Like a virtual machine (VM)
- You can start, stop, reboot, and terminate it
- Has: CPU, RAM, storage (EBS), and network

**EC2 Instance Components**:

- **CPU (Compute)**: How fast calculations are done; important for processing, calculations, batch jobs
- **Memory (RAM)**: How much data can be held while programs run; important for databases, caching, analytics
- **Storage**: Disk space (EBS or instance store); used for OS, files, logs, data
- **Network**: How fast data moves in/out; important for APIs, streaming, distributed systems

**Instance Types** (Choose based on workload):

- **General Purpose**: Balanced compute, memory, networking (default choice)
- **Compute Optimized**: CPU-heavy workloads; batch processing, high-performance web apps
- **Memory Optimized**: RAM-heavy workloads; databases, caching, analytics
- **Storage Optimized**: Disk-heavy workloads; data warehousing, Elasticsearch
- **Accelerated Computing**: GPU; machine learning, graphics rendering

**Instance Size Hierarchy**:

```
nano → micro → small → medium → large → xlarge → 2xlarge → 4xlarge → ...
(smaller/cheaper) ←→ (larger/more expensive)
```

**AMI (Amazon Machine Image)**

- Blueprint/template for creating EC2 instances
- Includes: Operating System (Linux, Windows), software, configurations
- You can create custom AMIs or use AWS pre-built ones

**Storage Options**:

1. **EBS (Elastic Block Store)**
   - Persistent disk storage
   - Data survives instance stop/start
   - Can be attached/detached from instances
   - Types: SSD (fast, expensive), HDD (slower, cheap)

2. **Instance Store**
   - Temporary storage physically attached to the instance
   - Data is lost when instance stops
   - Very fast
   - Good for temporary files, caches

**Key Pairs**

- Required for logging into EC2 instances (especially Linux)
- SSH key-pair for secure access
- Private key: Keep it safe (like a password)
- Public key: Stored in the instance
- Download and save when creating instance (can't be recovered if lost)

**Security Groups**

- Virtual firewall for EC2 instances
- Controls inbound and outbound traffic
- Rules: Source, Protocol, Port range
- Default: All inbound denied, all outbound allowed

---

## Networking

### VPC (Virtual Private Cloud)

- Isolated network environment in AWS
- You control: IP address ranges, subnets, route tables, gateways
- Public Subnets: Instances can be accessed from internet
- Private Subnets: Instances are isolated from internet

### Elastic IP

- Static public IP address
- Doesn't change when you stop/start instance
- You pay if not associated with an instance

---

## Database Services

### RDS (Relational Database Service)

- Managed relational database service
- Supported databases: MySQL, PostgreSQL, MariaDB, Oracle, SQL Server
- Benefits:
  - Automated backups
  - Automatic patching
  - Multi-AZ (Availability Zone) deployment for high availability
  - Read replicas for scaling read operations

### DynamoDB

- Fully managed NoSQL database
- Key-value and document data model
- Fast and scalable
- Pay-per-request or provisioned capacity

---

## Serverless Computing

### Lambda

- Run code without managing servers
- Pay only for execution time
- Scales automatically
- Supported languages: Python, Node.js, Java, Go, C#, Ruby
- Use cases: APIs, data processing, scheduled tasks, real-time processing

---

## Load Balancing & Auto Scaling

### Load Balancer

- Distributes incoming traffic across multiple EC2 instances
- Types: Application Load Balancer (ALB), Network Load Balancer (NLB), Classic Load Balancer
- Health checks ensure traffic goes only to healthy instances

### Auto Scaling

- Automatically adjust number of EC2 instances based on demand
- Scale up during high load
- Scale down during low load
- Cost optimization: pay only for what you need

---

## Identity & Access Management (IAM)

**Core Concepts**:

- **Users**: Individual accounts with specific permissions
- **Groups**: Collections of users with the same permissions
- **Roles**: Set of permissions that can be assumed by services
- **Policies**: Documents that define permissions (JSON-based)

**Least Privilege Principle**:

- Give users only the permissions they need
- Regularly audit and remove unnecessary permissions

**Best Practices**:

- Never use root user for daily tasks
- Enable MFA on all accounts
- Create IAM users for each person
- Use roles for EC2 instances (not hardcoded credentials)
- Rotate access keys regularly

---

## Monitoring & Logging

### AWS CloudWatch

- Monitoring service for AWS resources
- Tracks metrics: CPU usage, network traffic, disk I/O
- Logs: Application logs, system logs
- Alarms: Notify when metrics exceed thresholds
- Dashboards: Visualize metrics and logs

### CloudTrail

- Records API calls and actions in AWS account
- Audit trail of who did what, when, and where
- Important for compliance and security

---

## Security Best Practices

1. **Authentication**:
   - Use IAM users instead of root
   - Enable MFA for all accounts
   - Use strong passwords

2. **Authorization**:
   - Apply least privilege principle
   - Regular permission audits
   - Use IAM roles for services

3. **Data Protection**:
   - Enable encryption at rest (EBS, RDS, S3)
   - Enable encryption in transit (HTTPS, SSL/TLS)
   - Use VPC security groups

4. **Monitoring**:
   - Enable CloudTrail for audit logs
   - Use CloudWatch for monitoring
   - Set up alarms for suspicious activity

5. **Backup & Disaster Recovery**:
   - Regular backups of critical data
   - Multi-AZ deployment for availability
   - Disaster recovery plan

---

## Cost Optimization

1. **Right-sizing**: Use appropriate instance types and sizes
2. **Reserved Instances**: Commit to 1-3 years for discounts
3. **Spot Instances**: Bid for unused capacity (up to 90% discount)
4. **Auto Scaling**: Pay only for resources you use
5. **Storage Lifecycle**: Move old data to cheaper storage classes (S3 Glacier)

---

## Common AWS Services Summary

| Service        | Purpose                                    |
| -------------- | ------------------------------------------ |
| **EC2**        | Virtual compute instances                  |
| **S3**         | Object storage (files, databases, backups) |
| **RDS**        | Managed relational databases               |
| **Lambda**     | Serverless code execution                  |
| **CloudWatch** | Monitoring and logging                     |
| **IAM**        | Identity and access management             |
| **VPC**        | Virtual network environment                |
| **CloudFront** | Content delivery network (CDN)             |
| **DynamoDB**   | NoSQL database                             |
| **SNS/SQS**    | Messaging services                         |

---

## Monitoring
