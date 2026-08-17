# AWS Architecture — Patrick Diamitani Portfolio

**Well-Architected Framework:** Production-grade, cost-optimized static site hosting  
**Deployment Target:** AWS (US Region recommended: us-east-1)  
**Infrastructure as Code:** Terraform (provided)

---

## System Diagram

```
                          Internet
                             |
                    Route53 (DNS)
                    diamitani.com
                             |
                      CloudFront (CDN)
                   (Edge caching layer)
                             |
                    +--------+--------+
                    |                 |
              S3 Origin         Custom Origin
           (Static files)        (if needed)
         diamitani-portfolio-web
```

---

## Components

### 1. Route53 (DNS)

**Purpose:** Domain name resolution + health checks

**Configuration:**
- Domain: `diamitani.com` (or your chosen domain)
- Type: Hosted Zone (public)
- Record: `A record` → CloudFront distribution alias
- Health Check: CloudFront distribution health (automatic)

**Cost:** ~$0.50/month (Hosted Zone) + ~$0.50/month per health check

---

### 2. CloudFront (CDN)

**Purpose:** Global content delivery, edge caching, HTTPS enforcement

**Configuration:**

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Origin** | S3 bucket (`diamitani-portfolio-web.s3.amazonaws.com`) | Primary source |
| **Alternate Origin** | (Optional) GitHub Pages fallback | Redundancy |
| **Protocol** | HTTPS only (enforce) | Security |
| **TLS Version** | TLSv1.2+ | Security, browser compatibility |
| **Certificate** | AWS Certificate Manager (free) | Automated renewal |
| **Default TTL** | 3600s (1 hour) for HTML | Freshness vs cache hit rate |
| **Max TTL** | 86400s (24 hours) for HTML | Upper bound |
| **Cache Policy** | Custom (see below) | Optimize for static site |
| **Compression** | gzip, brotli | Reduce transfer size |

**Cache Behavior:**

```
Path Pattern: *.html
  Default TTL: 3600
  Max TTL: 86400
  Query string forward: No
  Compress: Yes
  
Path Pattern: *.js, *.css, *.webp, *.png, *.jpg
  Default TTL: 604800 (7 days)
  Max TTL: 31536000 (1 year)
  Query string forward: No
  Compress: Yes
  
Path Pattern: /
  Default TTL: 3600
  Max TTL: 86400
  Query string forward: No
  Compress: Yes
```

**Custom Headers:**
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: SAMEORIGIN
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
```

**Cost:** ~$0.085 per GB (data transfer out) + minimal request charges

---

### 3. S3 (Static Storage)

**Purpose:** Store HTML, CSS, JS, images, videos (embedded via YouTube)

**Bucket Configuration:**

| Setting | Value | Rationale |
|---------|-------|-----------|
| **Bucket Name** | `diamitani-portfolio-web` | Descriptive, globally unique |
| **Region** | us-east-1 | Lowest latency with CloudFront |
| **Versioning** | Enabled | Rollback capability |
| **Public Access** | Block all (via CloudFront only) | Security |
| **Encryption** | AES-256 (default) | Data at rest |
| **Website Hosting** | Disabled (use CloudFront) | Best practice |

**Bucket Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudFrontReadOnly",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::diamitani-portfolio-web/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT_ID:distribution/DISTRIBUTION_ID"
        }
      }
    }
  ]
}
```

**Folder Structure:**
```
s3://diamitani-portfolio-web/
├── index.html
├── pages/
│   ├── leadership/
│   │   ├── learn-be-curious.html
│   │   ├── invent-simplify.html
│   │   └── [other principles]
│   └── developer-advocacy.html
├── styles/
│   ├── main.css (production bundle)
│   └── lp-detail.css
├── scripts/
│   ├── main.js (minimal JS)
│   └── nav.js
├── images/
│   └── [hero.webp, etc. — max 1200px width]
└── assets/
    └── [icons, fonts if self-hosted]
```

**Cost:** ~$0.023 per GB for storage (you'll use <100MB, so <$2.50/month)

---

### 4. CI/CD Pipeline (GitHub Actions + AWS)

**Purpose:** Deploy on push to main

**Workflow (`.github/workflows/deploy.yml`):**

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Sync to S3
        run: |
          aws s3 sync . s3://diamitani-portfolio-web \
            --exclude ".git/*" \
            --exclude ".github/*" \
            --exclude ".gitignore" \
            --exclude "README.md" \
            --exclude "DESIGN.md" \
            --exclude "ARCHITECTURE.md" \
            --cache-control "public, max-age=31536000" \
            --cache-control "public, max-age=3600" \
            --metadata-directive REPLACE
      
      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"
      
      - name: Slack Notification
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK }}
          payload: |
            {
              "text": "✅ Portfolio deployed to AWS",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Deploy Successful*\nSite: https://diamitani.com\nCommit: ${{ github.sha }}"
                  }
                }
              ]
            }
```

**Setup Steps:**
1. Create GitHub secrets (AWS credentials, CloudFront distribution ID, Slack webhook)
2. Commit workflow file to `.github/workflows/deploy.yml`
3. Push to main → automatic deployment

---

## Terraform Configuration

**File:** `infrastructure/main.tf`

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "diamitani-terraform-state"
    key            = "portfolio/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 Bucket
resource "aws_s3_bucket" "portfolio" {
  bucket = "diamitani-portfolio-web"
  
  tags = {
    Name        = "Portfolio Website"
    Environment = "production"
    Owner       = "Patrick Diamitani"
    Project     = "AWS SA Portfolio"
  }
}

resource "aws_s3_bucket_versioning" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  default_root_object = "index.html"
  
  origin {
    domain_name              = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio.id
  }
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    
    cache_policy_id          = data.aws_cloudfront_cache_policy.managed_caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.managed_all_viewer.id
  }
  
  cache_behaviors = [
    {
      path_pattern           = "*.html"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      target_origin_id       = "S3Origin"
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
      cache_policy_id        = aws_cloudfront_cache_policy.html_cache.id
    }
  ]
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
    # OR: use ACM certificate for custom domain
    # acm_certificate_arn = aws_acm_certificate.portfolio.arn
    # ssl_support_method  = "sni-only"
  }
  
  tags = {
    Name = "Portfolio CloudFront"
  }
}

resource "aws_cloudfront_origin_access_control" "portfolio" {
  name                              = "portfolio-oac"
  description                       = "Portfolio OAC"
  origin_access_control_origin_type = "s3"
}

# Cache Policy for HTML (short TTL)
resource "aws_cloudfront_cache_policy" "html_cache" {
  name            = "portfolio-html-cache"
  comment         = "Cache policy for HTML files"
  default_ttl     = 3600
  max_ttl         = 86400
  min_ttl         = 0
  
  parameters_in_cache_key_and_forwarded_to_origin {
    query_strings_config {
      query_string_behavior = "none"
    }
    
    headers_config {
      header_behavior = "none"
    }
  }
}

# Route53 (optional, if using custom domain)
# resource "aws_route53_record" "portfolio" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "diamitani.com"
#   type    = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.portfolio.domain_name
#     zone_id                = aws_cloudfront_distribution.portfolio.hosted_zone_id
#     evaluate_target_health = true
#   }
# }

# Outputs
output "s3_bucket_name" {
  value = aws_s3_bucket.portfolio.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.portfolio.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.portfolio.id
}
```

**Deploy:**
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

---

## Security Best Practices

✅ **HTTPS Only** — CloudFront enforces TLS 1.2+  
✅ **No Database** — Static site, no SQL injection risk  
✅ **No Secrets in Code** — Use GitHub Secrets for AWS credentials  
✅ **Public S3 Blocked** — Only CloudFront can read objects  
✅ **CSP Headers** — Prevent XSS (via CloudFront custom headers)  
✅ **Signed Cookies/URLs** (optional) — If you want to gate access to any content  

---

## Monitoring & Alerts

### CloudWatch Metrics to Monitor

```
- CloudFront: Requests, BytesDownloaded, 4xxErrorRate, 5xxErrorRate
- S3: BucketSize, NumberOfObjects
- Route53: HealthCheckStatus (if using health checks)
```

**Alerts (SNS):**
- 4xx error rate > 5% for 5 minutes
- 5xx error rate > 1% for 5 minutes
- S3 bucket size > 1GB (cost control)

### Logging

**S3 Access Logs:**
```
s3://diamitani-portfolio-logs/access-logs/
```

**CloudFront Logs:**
```
s3://diamitani-portfolio-logs/cloudfront-logs/
```

---

## Cost Estimate (Monthly)

| Service | Usage | Cost |
|---------|-------|------|
| **S3** | <100MB storage | ~$0.02 |
| **S3** | ~1M PUT/GET requests | ~$0.05 |
| **CloudFront** | ~5GB outbound (worldwide traffic) | ~$0.43 |
| **CloudFront** | ~10M requests | ~$0.85 |
| **Route53** | Hosted zone (optional) | ~$0.50 |
| **Route53** | ~1M DNS queries | ~$0.40 |
| ****Total** | — | **~$2.25** |

**Scaling:** Even at 100M requests/month, cost stays under $50. No scaling concerns.

---

## Deployment Checklist

- [ ] Create S3 bucket (`diamitani-portfolio-web`)
- [ ] Enable versioning + encryption on S3
- [ ] Create CloudFront distribution pointing to S3
- [ ] Add custom domain (Route53 or external DNS)
- [ ] Verify HTTPS certificate (ACM)
- [ ] Set up GitHub Actions workflow
- [ ] Create AWS IAM user for CI/CD (limited permissions)
- [ ] Add GitHub Secrets (AWS credentials, CloudFront ID)
- [ ] Deploy and test
- [ ] Monitor CloudWatch metrics
- [ ] Set up alerts (SNS to email/Slack)

---

## Disaster Recovery

**Backup:**
- S3 versioning enabled (retain past 30 versions)
- Terraform state in S3 with versioning

**Restore:**
```bash
# Restore specific version from S3
aws s3api restore-object \
  --bucket diamitani-portfolio-web \
  --key index.html \
  --version-id <VERSION_ID>

# Or: Redeploy from GitHub
git push  # Triggers GitHub Actions → redeploys to S3/CloudFront
```

---

## Next Steps

1. **Set up infrastructure:** Run Terraform scripts
2. **Configure CI/CD:** Add GitHub Actions workflow
3. **Deploy redesigned site:** Push redesigned HTML/CSS/JS to GitHub
4. **Monitor:** Watch CloudWatch dashboard for first 48 hours
5. **Iterate:** Update DESIGN.md as you refine

---

**Last Updated:** August 2026  
**Deployed by:** Patrick Diamitani  
**Architecture Review:** AWS Solutions Architect
