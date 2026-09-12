# CI/CD Pipeline with GitHub Actions, Docker & AWS ECS

A complete CI/CD pipeline that automatically builds, containerizes, and deploys a Node.js application to AWS ECS (Fargate) using GitHub Actions, Docker, and Terraform.

## Table of Contents

- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [AWS Requirements](#aws-requirements)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Running the Application](#running-the-application)
- [CI/CD Workflow](#cicd-workflow)
- [Verification](#verification)
- [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
- [Troubleshooting](#troubleshooting)
- [Cost Estimate](#cost-estimate)
- [Cleanup](#cleanup)
- [Useful Commands](#useful-commands)
- [Security Notes](#security-notes)
- [Project Lifecycle](#project-lifecycle)
- [License](#license)

## Architecture

```
Developer → GitHub → GitHub Actions → ECR → ECS Fargate → ALB → Internet
                                        ↑
                    Terraform (provisions VPC, ECR, ECS, ALB, IAM)
```

## Tech Stack

| Layer | Technology |
|---|---|
| Runtime | Node.js 18 |
| Framework | Express.js 4.18 |
| Container | Docker (`node:18-alpine`) |
| IaC | Terraform 1.5+ |
| Cloud | AWS (ECS, ECR, ALB, VPC, IAM, CloudWatch) |
| CI/CD | GitHub Actions |
| Registry | AWS ECR |
| Compute | AWS ECS Fargate |
| Load Balancer | AWS ALB |

## Prerequisites

Install these before starting:

- **Node.js 18+** — https://nodejs.org
- **Docker** — https://docs.docker.com/get-docker
- **Terraform 1.5+** — https://developer.hashicorp.com/terraform/install
- **AWS CLI v2** — https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- **Git** — https://git-scm.com
- **VS Code** — https://code.visualstudio.com

Verify installations:

```bash
node --version      # v18.x or higher
docker --version    # Docker version 20.x or higher
terraform --version # Terraform v1.5 or higher
aws --version       # aws-cli/2.x or higher
git --version       # git version 2.30 or higher
```

## AWS Requirements

- AWS account with billing enabled
- AWS CLI configured with an IAM user that has admin permissions (for initial setup)
- Permissions to create: VPC, ECR, ECS, ALB, IAM roles, CloudWatch Logs

Configure AWS CLI:

```bash
aws configure
```

## Project Structure

```
cicd-pipeline-project/
├── app/                          # Node.js application
│   ├── package.json
│   └── server.js
├── infra/                        # Terraform infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── ecr.tf
│   ├── ecs.tf
│   ├── alb.tf
│   ├── iam.tf
│   └── terraform.tfvars.example
├── .github/
│   └── workflows/
│       └── deploy.yml            # CI/CD pipeline
├── Dockerfile
├── .dockerignore
├── .gitignore
└── README.md
```

## Setup Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/cicd-pipeline-project.git
cd cicd-pipeline-project
```

### Step 2: Test the Application Locally

```bash
cd app
npm install
npm start
```

Open browser: `http://localhost:3000`

Expected output: `Hello from CI/CD Pipeline!`

Test the health endpoint:

```bash
curl http://localhost:3000/health
```

Stop the app: `Ctrl + C`

### Step 3: Test Docker Build Locally

```bash
docker build -t my-app .
docker run -d -p 3000:3000 --name my-app-container my-app
curl http://localhost:3000
docker stop my-app-container
docker rm my-app-container
```

### Step 4: Provision AWS Infrastructure with Terraform

```bash
cd infra
terraform init
terraform plan
terraform apply -auto-approve
```

Save the outputs:

```bash
terraform output
```

Note the values:

- `alb_dns_name` — your application URL
- `ecr_repository_url` — where images will be pushed
- `ecs_cluster_name` — ECS cluster name

### Step 5: Create IAM User for GitHub Actions

In AWS Console → IAM → Users → Create user:

- **User name:** `github-actions-deploy`
- **Permissions:** Attach policies directly:
  - `AmazonECS_FullAccess`
  - `AmazonEC2ContainerRegistry_FullAccess`
  - `ElasticLoadBalancing_FullAccess`
  - `CloudWatchLogsFullAccess`

After creating the user, go to **Security credentials** → **Create access key** → **Command Line Interface (CLI)**.

**Copy both keys immediately** (shown only once):

- Access Key ID
- Secret Access Key

### Step 6: Add GitHub Secrets

1. Go to: `https://github.com/YOUR_USERNAME/cicd-pipeline-project/settings/secrets/actions`
2. Click **New repository secret**
3. Add these three secrets:

| Name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | Your IAM access key |
| `AWS_SECRET_ACCESS_KEY` | Your IAM secret key |
| `AWS_REGION` | `us-east-1` |

### Step 7: Push Code to Trigger Deployment

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

### Step 8: Watch the Pipeline

Go to: `https://github.com/YOUR_USERNAME/cicd-pipeline-project/actions`

You should see the workflow running with these steps:

- ✅ Checkout repository
- ✅ Configure AWS credentials
- ✅ Login to Amazon ECR
- ✅ Build and push Docker image
- ✅ Deploy to ECS
- ✅ Wait for ECS deployment
- ✅ Get application URL
- ✅ Verify deployment

## Running the Application

### Local Development

```bash
cd app
npm install
npm start
```

Access at: `http://localhost:3000`

### Local Docker

```bash
docker build -t my-app .
docker run -p 3000:3000 my-app
```

Access at: `http://localhost:3000`

### Production (AWS)

```bash
cd infra
terraform output -raw app_url
```

Open the URL in a browser, or test with curl:

```bash
curl $(terraform -chdir=infra output -raw app_url)
```

## CI/CD Workflow

The pipeline runs automatically on every push to `main`.

**Trigger:**

```bash
git add .
git commit -m "Update app"
git push origin main
```

**Pipeline steps:**

1. Checks out repository code
2. Authenticates to AWS using GitHub Secrets
3. Logs in to Amazon ECR
4. Builds the Docker image
5. Tags the image with the commit SHA and `latest`
6. Pushes both tags to ECR
7. Triggers an ECS rolling deployment
8. Waits for the service to stabilize
9. Verifies deployment via HTTP request

**Deployment model:** Zero-downtime rolling update. ECS starts new tasks, waits for health checks, then drains old tasks.

## Verification

### 1. Verify Local Setup

```bash
curl http://localhost:3000
```

### 2. Verify Terraform

```bash
cd infra
terraform state list
terraform output
```

### 3. Verify GitHub Actions

Go to the **Actions** tab → latest workflow run → confirm all steps show green checkmarks.

### 4. Verify ECS Service

```bash
aws ecs describe-services \
  --cluster cicd-pipeline-cluster \
  --services cicd-pipeline-service \
  --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount}' \
  --output table
```

Expected:

```
Desired: 1
Running: 1
Status: ACTIVE
```

### 5. Verify ECR

```bash
aws ecr describe-images \
  --repository-name cicd-pipeline-repo \
  --query 'imageDetails[*].imageTags'
```

Expected: `latest` and a commit SHA tag.

### 6. Verify Live Application

```bash
curl $(terraform -chdir=infra output -raw app_url)
curl $(terraform -chdir=infra output -raw app_url)/health
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | Port the server listens on |

## API Endpoints

| Method | Endpoint | Response |
|---|---|---|
| GET | `/` | `Hello from CI/CD Pipeline!` |
| GET | `/health` | `{"status":"healthy","timestamp":"..."}` |

## Troubleshooting

### Docker build fails

- Check the Docker daemon is running: `docker ps`
- Verify `Dockerfile` exists in the project root
- Verify `app/package.json` exists

### Terraform apply fails

- Verify AWS credentials: `aws sts get-caller-identity`
- Check the region is correct in `variables.tf`
- Ensure the IAM user has the required permissions

### GitHub Actions fails at "Configure AWS"

- Verify secrets are added correctly in GitHub Settings
- Check the IAM user has all four required policies attached
- Verify secret names match exactly: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

### GitHub Actions fails at "Login to ECR"

- Verify the `AWS_REGION` secret matches the region where ECR was created
- Check the IAM user has `AmazonEC2ContainerRegistry_FullAccess`

### GitHub Actions fails at "Deploy to ECS"

- Verify the ECS cluster and service exist: `aws ecs list-clusters`
- Check the IAM user has `AmazonECS_FullAccess`
- Ensure Terraform was applied before the first pipeline run

### ECS task stuck in PROVISIONING

- Check ECR has an image: `aws ecr describe-images --repository-name cicd-pipeline-repo`
- Verify the ECS task definition references the correct ECR URL
- Check CloudWatch logs: `/ecs/cicd-pipeline`

### ALB returns 503 Service Unavailable

- Check the ECS task is running: `aws ecs list-tasks --cluster cicd-pipeline-cluster`
- Verify target group health: AWS Console → EC2 → Target Groups
- Check the security group allows port 3000 inbound
- Wait 2–3 minutes after deployment for health checks

### `curl` returns empty response

- The ALB may still be initializing (wait 2–3 minutes)
- Verify the ALB DNS: `terraform -chdir=infra output alb_dns_name`
- Check the ALB is in `active` state in the AWS Console

### View container logs

```bash
aws logs tail /ecs/cicd-pipeline --follow
```

## Cost Estimate

| Service | Monthly Cost |
|---|---|
| ECS Fargate (0.25 vCPU, 0.5 GB, 1 task) | ~$15 |
| Application Load Balancer | ~$16 |
| ECR storage (~500 MB) | ~$0.05 |
| CloudWatch Logs | ~$1 |
| Data transfer | ~$1 |
| **Total** | **~$33/month** |

Free tier may cover some costs. **Destroy resources when not in use.**

## Cleanup

To avoid ongoing AWS charges, destroy all resources:

```bash
cd infra
terraform destroy -auto-approve
```

This deletes:

- ECS cluster and service
- ECR repository and images
- Application Load Balancer
- VPC, subnets, internet gateway
- IAM roles and policies
- CloudWatch log groups

Verify cleanup:

```bash
aws ecs list-clusters
aws ecr describe-repositories
aws elbv2 describe-load-balancers
```

## Useful Commands

```bash
npm start
npm install
docker build -t my-app .
docker run -p 3000:3000 my-app
docker ps
terraform init
terraform plan
terraform apply
terraform destroy
terraform output
terraform state list
aws ecs list-clusters
aws ecs list-services --cluster cicd-pipeline-cluster
aws ecs describe-services --cluster cicd-pipeline-cluster --services cicd-pipeline-service
aws ecr describe-repositories
aws ecr describe-images --repository-name cicd-pipeline-repo
aws logs tail /ecs/cicd-pipeline --follow
```

## Security Notes

- Never commit AWS credentials to Git
- Secrets are stored in GitHub Secrets (encrypted)
- IAM user follows the least-privilege principle (only required policies)
- Container runs as a non-root user (`node:18-alpine` default)
- Security group restricts inbound traffic to port 3000
- ECR images are scanned for vulnerabilities on push

## Project Lifecycle

1. **Develop** — Write code in VS Code
2. **Test locally** — `npm start` + `docker run`
3. **Push** — `git push origin main`
4. **Pipeline runs** — GitHub Actions builds and pushes the image
5. **Deploy** — ECS pulls the new image and rolling-updates
6. **Verify** — Curl the ALB URL
7. **Iterate** — Make changes, push, repeat
8. **Destroy** — `terraform destroy` when done

## Quick Start

For those who want the fastest path through setup:

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/cicd-pipeline-project.git
cd cicd-pipeline-project

# 2. Test locally
cd app && npm install && npm start
# Open http://localhost:3000, then Ctrl+C
cd ..

# 3. Test Docker
docker build -t my-app .
docker run -d -p 3000:3000 my-app
curl http://localhost:3000
docker stop $(docker ps -q --filter ancestor=my-app)

# 4. Provision AWS
cd infra
terraform init
terraform apply -auto-approve
terraform output
cd ..

# 5. Add secrets to GitHub (via browser)

# 6. Push to deploy
git add .
git commit -m "Deploy"
git push origin main

# 7. Verify
curl $(terraform -chdir=infra output -raw app_url)

# 8. Cleanup
terraform -chdir=infra destroy -auto-approve
```

## License

MIT
