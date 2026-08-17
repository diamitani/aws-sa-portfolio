# Infrastructure as Code — CloudFront + S3 Deployment

This directory contains Terraform configuration to deploy the Patrick Diamitani portfolio website to AWS CloudFront + S3.

## Architecture

```
Route53 (DNS)
    ↓
CloudFront (Global CDN)
    ↓
S3 Bucket (Static files)
```

**Cost:** ~$2-5/month (S3 storage + CloudFront egress)  
**Latency:** <100ms globally (CloudFront edge caching)  
**Uptime:** 99.99% (AWS SLA)

---

## Prerequisites

1. **AWS Account** with permissions for S3, CloudFront, IAM, Route53
2. **Terraform** installed (`terraform -v` to verify)
3. **AWS CLI** installed (`aws --version` to verify)
4. **AWS Credentials** configured locally

### Set Up AWS Credentials

```bash
# Option 1: Interactive configuration
aws configure

# When prompted:
# AWS Access Key ID: [your_access_key]
# AWS Secret Access Key: [your_secret_key]
# Default region: us-east-1
# Default output format: json

# Option 2: Environment variables (for CI/CD)
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_REGION="us-east-1"
```

**Get AWS credentials:**
1. Go to AWS Console → IAM → Users
2. Select your user → Create Access Key
3. Choose "Local code/CLI"
4. Download credentials file (keep it safe!)
5. Attach policy: `AdministratorAccess` (or custom S3/CloudFront permissions)

---

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd infrastructure
terraform init
```

**What it does:**
- Downloads AWS provider plugin
- Creates `.terraform/` directory
- Initializes working directory

### Step 2: Review Planned Changes

```bash
terraform plan
```

**Output shows:**
- S3 bucket creation
- CloudFront distribution setup
- IAM roles and policies
- Security headers configuration

**Example output:**
```
Plan: 8 to add, 0 to change, 0 to destroy.
```

### Step 3: Deploy to AWS

```bash
terraform apply
```

**When prompted:** Type `yes` to proceed

**What it does:**
1. Creates S3 bucket (with versioning, encryption, access controls)
2. Sets up CloudFront distribution (with caching rules)
3. Configures Origin Access Identity (OAI)
4. Creates SSL certificate (if custom domain)
5. Sets up Route53 DNS (if hosted zone provided)

**Deployment time:** 5-15 minutes for CloudFront to become active

### Step 4: Get Output Values

```bash
terraform output
```

**Important outputs:**
```
cloudfront_distribution_id  = "d1234567890abc.cloudfront.net"
cloudfront_domain_name      = "d1234567890abc.cloudfront.net"
s3_bucket_name              = "diamitani-portfolio-web-123456789"
deployment_url              = "https://d1234567890abc.cloudfront.net"
```

**Save these values!** You'll need them for GitHub Actions secrets.

---

## Initial File Upload to S3

After Terraform deployment, upload your website files:

```bash
# Upload all files from parent directory to S3
aws s3 sync .. s3://diamitani-portfolio-web-123456789 \
  --delete \
  --exclude ".git/*" \
  --exclude "node_modules/*" \
  --exclude "*.tfstate*"

# Set cache headers for HTML (1 hour)
aws s3 cp .. s3://diamitani-portfolio-web-123456789 \
  --recursive \
  --exclude "*" \
  --include "*.html" \
  --cache-control "public, max-age=3600, must-revalidate" \
  --metadata "content-type=text/html"

# Set long cache for assets (7 days)
aws s3 cp .. s3://diamitani-portfolio-web-123456789 \
  --recursive \
  --exclude "*" \
  --include "*.css" --include "*.js" --include "*.png" --include "*.jpg" \
  --cache-control "public, max-age=604800" 
```

---

## Set Up GitHub Actions (Optional - For Continuous Deployment)

GitHub Actions will automatically sync changes to S3 and invalidate CloudFront.

### Step 1: Get Required Values

```bash
# From terraform output above:
echo "S3_BUCKET_NAME = diamitani-portfolio-web-123456789"
echo "CLOUDFRONT_DISTRIBUTION_ID = d1234567890abc"
echo "CLOUDFRONT_DOMAIN = d1234567890abc.cloudfront.net"

# Also get AWS credentials:
# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```

### Step 2: Add GitHub Secrets

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add these secrets:

| Name | Value |
|------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `S3_BUCKET_NAME` | Output from terraform output |
| `CLOUDFRONT_DISTRIBUTION_ID` | Output from terraform output |
| `CLOUDFRONT_DOMAIN` | Output from terraform output |

### Step 3: GitHub Actions Workflow

The workflow file is in `.github/workflows/deploy.yml`

**What it does on every push to main:**
1. Checks out code
2. Configures AWS credentials
3. Syncs files to S3
4. Invalidates CloudFront cache
5. Reports deployment status

**Deployment time:** ~2 minutes

---

## Custom Domain Setup (Optional)

### Using Route53

1. Buy domain (or transfer to Route53)
2. Update `terraform.tfvars`:
   ```hcl
   domain_name      = "diamitani.com"
   hosted_zone_id   = "Z1234567890ABC"  # From Route53 console
   ```
3. Re-run Terraform:
   ```bash
   terraform plan
   terraform apply
   ```
4. Terraform creates A record automatically

### Using External DNS Provider

1. Get CloudFront domain: `terraform output cloudfront_domain_name`
2. In your DNS provider (GoDaddy, Namecheap, etc.), create CNAME:
   ```
   Type: CNAME
   Name: diamitani.com
   Value: d1234567890abc.cloudfront.net
   ```
3. Wait 24-48 hours for propagation

---

## Verification

### Test CloudFront

```bash
curl -I https://d1234567890abc.cloudfront.net
# Should return: 200 OK
# Headers should include: X-Cache, CloudFront-Id
```

### Check Cache Headers

```bash
curl -I https://d1234567890abc.cloudfront.net/index.html
# Cache-Control: public, max-age=3600, must-revalidate
```

### Performance Check

Use Lighthouse to verify performance:
https://pagespeed.web.dev/

Target: 95+ performance score

---

## Maintenance

### Update Website Files

```bash
# Option 1: Manual sync
aws s3 sync .. s3://diamitani-portfolio-web-123456789 --delete

# Option 2: Push to GitHub (automatic via GitHub Actions)
git push origin main
```

### Invalidate Cache Manually

```bash
aws cloudfront create-invalidation \
  --distribution-id d1234567890abc \
  --paths "/*"
```

### Destroy Infrastructure (⚠️ Careful!)

```bash
terraform destroy
```

**Warning:** This deletes S3 bucket and CloudFront distribution (but keeps state file)

---

## Troubleshooting

### CloudFront returning 403 Forbidden

Check S3 bucket policy:
```bash
aws s3api get-bucket-policy --bucket diamitani-portfolio-web-123456789
```

Should have CloudFront Origin Access Identity (OAI) principal.

### Files not updating after push

Check CloudFront cache:
```bash
aws cloudfront create-invalidation \
  --distribution-id d1234567890abc \
  --paths "/*"
```

Wait 2-5 minutes for invalidation to propagate.

### Terraform state issues

If state gets corrupted:
```bash
terraform refresh
terraform plan  # Review changes
terraform apply
```

---

## Security Best Practices

✅ S3 bucket has public access blocked  
✅ CloudFront enforces HTTPS only  
✅ Origin Access Identity restricts S3 access  
✅ Security headers configured (CSP, X-Frame-Options, etc.)  
✅ Versioning enabled (disaster recovery)  
✅ Encryption at rest (AES-256)  
✅ Encryption in transit (TLS 1.2+)  

---

## Cost Optimization

**Estimated monthly cost:**
- S3 storage: ~$0.50 (10 MB site)
- CloudFront: ~$1-2 (10-50 GB egress)
- Route53: ~$0.50 (if custom domain)
- **Total: ~$2-3/month**

**To reduce costs:**
- Use PriceClass_100 (US, Europe, Asia) instead of worldwide
- Enable gzip compression (reduce transfer size)
- Set appropriate cache TTLs (reduce origin requests)

---

## References

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Terraform State Management](https://www.terraform.io/language/state)

---

## Support

- Questions? Check the deployment guide: `../DEPLOYMENT_GUIDE.md`
- Architecture details? See: `../ARCHITECTURE.md`
- Deployed but having issues? See Troubleshooting section above
