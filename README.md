===============================================================================
MULTI-TIER HYBRID IAAS & PAAS CLOUD INFRASTRUCTURE BLUEPRINT
===============================================================================

A production-ready, highly available AWS cloud environment provisioned completely 
through Infrastructure as Code (IaC) using Terraform. This project demonstrates 
the architectural integration of Infrastructure as a Service (IaaS) compute 
instances and Platform as a Service (PaaS) managed databases, adhering strictly 
to enterprise security standards, multi-AZ high availability, and the principle 
of least privilege.

-------------------------------------------------------------------------------
1. ARCHITECTURAL OVERVIEW
-------------------------------------------------------------------------------

The infrastructure isolates resources across THREE distinct logical tiers and 
TWO Availability Zones (AZs) to ensure high availability, fault tolerance, 
and absolute network security.

                           [ Internet ]
                                │
                        ┌───────▼───────┐
                        │  Internet GW  │
                        └───────┬───────┘
                                │
┌───────────────────────────────┼───────────────────────────────┐
│ VPC (10.0.0.0/16)             │                               │
│                               ▼                               │
│ ┌───────────────────────────────────────────────────────────┐ │
│ │ PUBLIC SUBNETS (10.0.1.0/24 & 10.0.2.0/24)                │ │
│ │   ┌─────────────────┐             ┌─────────────────┐     │ │
│ │   │   Application   │             │   NAT Gateway   │     │ │
│ │   │  Load Balancer  │             │   (Egress Only) │     │ │
│ │   └────────┬────────┘             └────────┬────────┘     │ │
│ └────────────┼───────────────────────────────┼──────────────┘ │
│              │                               │                │
│              ▼                               │                │
│ ┌────────────────────────────────────────────┼──────────────┐ │
│ │ PRIVATE APP SUBNETS (10.0.11.0/24 & 10.0.12.0/24)          │ │
│ │   ┌─────────────────┐             ┌────────▼────────┐     │ │
│ │   │ EC2 AutoScaling │◄────────────┤  OS Patches /   │     │ │
│ │   │     Group       │             │ Updates Outbound│     │ │
│ │   └────────┬────────┘             └─────────────────┘     │ │
│ └────────────┼──────────────────────────────────────────────┘ │
│              │                                                │
│              ▼                                                │
│ ┌───────────────────────────────────────────────────────────┐ │
│ │ PRIVATE DATA SUBNETS (10.0.21.0/24 & 10.0.22.0/24)         │ │
│ │   ┌─────────────────┐                                     │ │
│ │   │   Amazon RDS    │                                     │ │
│ │   │ (PostgreSQL PaaS)                                     │ │
│ │   └─────────────────┘                                     │ │
│ └───────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┘

Core Components:
* Network Topology (IaaS Core): A custom VPC with 6 subnets split evenly across 
  2 Availability Zones. It utilizes an Internet Gateway for incoming public 
  requests and a NAT Gateway tied to an Elastic IP allowing private instances 
  to fetch OS updates safely without exposure.
* Compute Tier (IaaS): Auto-scaling Ubuntu 24.04 nodes managed by an AWS Launch 
  Template. Traffic is distributed evenly across AZs via an Application Load 
  Balancer (ALB).
* Database Tier (PaaS): A fully managed Amazon RDS PostgreSQL database. 
  Automated storage auto-scaling is enabled, shifting administrative maintenance, 
  patching, and data durability over to the AWS platform fabric.

-------------------------------------------------------------------------------
2. SECURITY & TRAFFIC FLOW MATRIX
-------------------------------------------------------------------------------

Network isolation is enforced programmatically via AWS Security Groups using 
strict ingress/egress micro-segmentation:

* Public Tier (ALB Security Group)
  - Ingress: 0.0.0.0/0 on Port 80 (HTTP)
  - Egress: Anywhere (0.0.0.0/0)

* Private App Tier (App Security Group)
  - Ingress: ONLY from ALB Security Group on Port 80
  - Egress: Anywhere (0.0.0.0/0) via NAT Gateway

* Private Data Tier (DB Security Group)
  - Ingress: ONLY from App Security Group on Port 5432
  - Egress: None

-------------------------------------------------------------------------------
3. REPOSITORY FILE STRUCTURE
-------------------------------------------------------------------------------

.
├── provider.tf      # Defines AWS cloud provider constraints & default tags
├── variables.tf     # Configurable network blocks, region, and sensitive inputs
├── vpc.tf           # Provisioning of VPC, Subnets, Gateways, and Route Tables
├── security.tf      # Chained least-privilege Security Groups (Firewalls)
├── compute.tf       # Application Load Balancer, Launch Templates, and Auto Scaling
├── database.tf      # PaaS Database Subnet groups and Amazon RDS instance
├── outputs.tf       # Exposes the ALB public endpoint URL post-deployment
└── README.txt       # Comprehensive project documentation

-------------------------------------------------------------------------------
4. DEPLOYMENT GUIDE
-------------------------------------------------------------------------------

Prerequisites:
* Terraform v1.5.0+ installed locally.
* An active AWS Account with CLI credentials configured ("aws configure").
* Correct IAM permissions to spin up VPC, EC2, and RDS instances.

Step 1: Clone the Repository
$ git clone https://github.com/YOUR_GITHUB_USERNAME/terraform-hybrid-iaas-paas-arch.git
$ cd terraform-hybrid-iaas-paas-arch

Step 2: Initialize Terraform Working Directory
$ terraform init

Step 3: Inspect the Execution Plan
$ terraform plan -var="db_password=SecurePasswordInstance123!"

Step 4: Apply and Provision the Fabric
$ terraform apply -var="db_password=SecurePasswordInstance123!" --auto-approve
Note: The provisioning cycle might take between 5 to 8 minutes as AWS allocates 
and structures the managed database instance.

Step 5: Verify the Deployment
Once complete, copy the "alb_dns_name" printed out in the terminal.
Example Output:
alb_dns_name = "app-alb-123456789.us-east-1.elb.amazonaws.com"

Paste that URL into your web browser to verify traffic distribution.

-------------------------------------------------------------------------------
5. TEARING DOWN RESOURCES
-------------------------------------------------------------------------------

To prevent ongoing charges to your AWS bill, run the clean-up command:
$ terraform destroy -var="db_password=SecurePasswordInstance123!" --auto-approve

-------------------------------------------------------------------------------
6. PRODUCTION ENGINEERING PRINCIPLES DEMONSTRATED
-------------------------------------------------------------------------------

* Immutable Infrastructure: No servers were configured manually. Scaling nodes 
  use an automated user_data shell bootstrap script to set up software packages 
  on fresh boot cycles.
* Cost Efficiency: Utilizes resource instance sizes under the free-tier 
  (t3.micro for compute, db.t4g.micro with Graviton processors for databases) 
  along with configurable scaling limits.
* Dynamic Configuration: Implemented data source queries (data "aws_ami") to 
  find and capture the absolute latest Canonical Ubuntu LTS machine image 
  dynamically without hardcoding static IDs.
* Sensitive State Integrity: The database master password is set up as a 
  sensitive variable so it remains hidden from command line logs and GitHub 
  tracking files.


===============================================================================
