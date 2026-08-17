# AWS Deployment Guide — Patrick Diamitani Portfolio

## Prerequisites

1. **AWS Account** with permissions to create S3, CloudFront, and IAM resources
2. **Terraform** installed locally (`terraform` CLI)
3. **AWS CLI** installed locally
4. **Git** with access to GitHub repo
5. **AWS Credentials** configured locally

---

## Step 1: Set Up AWS Credentials Locally

```bash
# Configure AWS credentials
aws configure

# When prompted, enter:
# - AWS Access Key ID: [your_access_key]
# - AWS Secret Access Key: [your_secret_key]
# - Default region: us-east-1
# - Default output format: json
```

**Get AWS credentials:**
1. Go to AWS Console → IAM → Users
2. Create a new user (or use existing)
3. Create Access Key (type: Local code/CLI)
4. Download and keep safe
5. Attach policy: `AdministratorAccess` (or scoped S3/CloudFront permissions)

---

## Step 2: Set Up Terraform State Backend (One-time)

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://diamitani-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket diamitani-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket diamitani-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for Terraform locks
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

---

## Step 3: Deploy Infrastructure with Terraform

```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform (downloads providers and configures backend)
terraform init

# Review what will be created
terraform plan

# Deploy to AWS (type 'yes' when prompted)
terraform apply
```

**Output:** Terraform will display:
- S3 bucket name
- CloudFront distribution ID
- CloudFront domain name

**Save these values** — you'll need them for GitHub Actions.

---

## Step 4: Set Up GitHub Actions Secrets

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add these secrets:

| Secret Name | Value | Where to find |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS IAM → Create access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS IAM → Create access key |
| `CLOUDFRONT_DISTRIBUTION_ID` | From Terraform output | `terraform apply` output |

**Add secrets:**
```bash
# Or use GitHub CLI
gh secret set AWS_ACCESS_KEY_ID --body "your_access_key"
gh secret set AWS_SECRET_ACCESS_KEY --body "your_secret_key"
gh secret set CLOUDFRONT_DISTRIBUTION_ID --body "E123ABC45XYZ" # from terraform
```

---

## Step 5: Deploy Site via GitHub Actions

```bash
# Push to main to trigger automatic deployment
git add .
git commit -m "Deploy: site to AWS"
git push origin main
```

**Monitor deployment:**
1. Go to GitHub repo → Actions
2. Watch workflow run
3. When complete, it will show CloudFront URL

---

## Step 6: Verify Deployment

```bash
# Test the site
curl https://diamitani-portfolio-web.s3.us-east-1.amazonaws.com/index.html

# Or open in browser
# https://diamitani-portfolio-web.s3.us-east-1.amazonaws.com
# (or CloudFront domain from Terraform output)
```

---

## Step 7: Set Up Custom Domain (Optional)

If you own `diamitani.com`:

### Option A: Using Route53 (within AWS)

```bash
# Create hosted zone in Route53
aws route53 create-hosted-zone \
  --name diamitani.com \
  --caller-reference $(date +%s)

# Create alias record pointing to CloudFront
# (Do this in AWS Console: Route53 → Create Record)
# - Type: A (Alias)
# - Name: diamitani.com
# - Alias to: [CloudFront domain from Terraform]
```

### Option B: Using External DNS Provider

1. Get CloudFront domain: `terraform output cloudfront_domain_name`
2. Go to your DNS provider (GoDaddy, Namecheap, etc.)
3. Create CNAME record:
   - Name: `www`
   - Value: CloudFront domain
   - TTL: 3600

---

## Step 8: Monitor & Maintain

### Check CloudFront metrics:

```bash
# Get distribution status
aws cloudfront get-distribution --id $(terraform output -raw cloudfront_distribution_id)

# Invalidate cache if needed (after Terraform apply)
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

### View logs:

```bash
# S3 access logs
aws s3api get-bucket-logging --bucket diamitani-portfolio-web

# CloudFront logs (stored in S3)
aws s3 ls s3://diamitani-portfolio-web/cloudfront-logs/
```

---

## Troubleshooting

### Issue: "Access Denied" errors

**Solution:** Check AWS IAM permissions. User needs:
- `s3:*` (S3 full access)
- `cloudfront:*` (CloudFront full access)
- `logs:*` (CloudWatch Logs)

### Issue: Terraform state locked

**Solution:** 
```bash
# Check lock
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue: Site shows old content after deploy

**Solution:** CloudFront cache invalidation sometimes takes 30-60 seconds. Check:
```bash
# Monitor invalidation status
aws cloudfront list-invalidations --distribution-id <ID>

# Check cache settings in ARCHITECTURE.md
```

### Issue: 403 Forbidden on CloudFront

**Solution:** S3 bucket policy might be missing. Re-apply Terraform:
```bash
terraform plan
terraform apply
```

---

## Cost Monitoring

Monitor your AWS costs:

```bash
# S3 storage cost (usually <$1/month)
aws s3api list-objects-v2 --bucket diamitani-portfolio-web --query 'Contents[].Size' | awk '{sum+=$1} END {print "Total size: " sum/1024/1024 " MB"}'

# CloudFront data transfer (usually <$1/month for low traffic)
# View in AWS Console → CloudFront → Monitoring
```

Expected monthly cost: **~$2–5**

---

## Rollback

To rollback to previous version:

```bash
# List S3 versions
aws s3api list-object-versions --bucket diamitani-portfolio-web

# Restore specific version
aws s3api restore-object \
  --bucket diamitani-portfolio-web \
  --key index.html \
  --version-id <VERSION_ID>
```

---

## Next Steps

✅ **Deployment complete!** Your site is now:
- Hosted on S3 (durable, 99.99% uptime)
- Served via CloudFront (global CDN, fast edge caching)
- Auto-deployed on every push to main branch
- Monitored with CloudWatch logs
- Protected by AWS security best practices

**What's next:**
1. Update social links in `index.html`
2. Add Google Analytics (optional)
3. Set up email notifications for deployment failures
4. Monitor CloudFront metrics weekly

---

## Questions?

Refer to:
- **DESIGN.md** — Design system details
- **ARCHITECTURE.md** — Infrastructure design
- AWS Documentation: https://docs.aws.amazon.com/

