# 🚀 DEPLOY NOW — Choose Your Path

Your premium AWS portfolio is ready to ship. Choose your deployment strategy:

---

## **Option 1: Vercel (Fastest — 5 minutes)**

**Best for:** Getting live immediately, preview deployments, zero infrastructure

### One-Click Deploy

1. Go to https://vercel.com/import
2. Select GitHub repo: `aws-sa-portfolio`
3. Click "Deploy"
4. **Done!** You're live

**Result:**
```
✅ Live URL: https://aws-sa-portfolio.vercel.app
✅ Preview deployments on every PR
✅ Automatic HTTPS
✅ Global edge network
✅ Performance: <100ms latency
```

**Next time you push to main:** Automatic redeploy (2-3 minutes)

---

## **Option 2: CloudFront + S3 (AWS Showcase — 15 minutes)**

**Best for:** Demonstrating AWS architecture expertise, IaC mastery, Well-Architected patterns

### Prerequisites

```bash
# 1. Install Terraform (if not installed)
# https://www.terraform.io/downloads

# 2. Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1)
```

### Deploy

```bash
# 1. Navigate to infrastructure folder
cd infrastructure

# 2. Initialize Terraform
terraform init

# 3. Review what will be created
terraform plan

# 4. Deploy (type 'yes' when prompted)
terraform apply

# 5. Note the outputs:
# - cloudfront_distribution_id
# - cloudfront_domain_name
# - s3_bucket_name
# - deployment_url
```

**Deployment time:** 5-15 minutes for CloudFront to activate globally

**Result:**
```
✅ Live URL: https://d1234567890.cloudfront.net
✅ S3 bucket with versioning & encryption
✅ CloudFront CDN (99.99% uptime SLA)
✅ IaC infrastructure reproducible
✅ Security headers configured
✅ Performance: <50ms latency globally
✅ Cost: ~$2-5/month
```

### Upload Website Files

```bash
# Get S3 bucket name from terraform output
S3_BUCKET="diamitani-portfolio-web-123456789"

# Sync all files
aws s3 sync .. s3://$S3_BUCKET --delete \
  --exclude ".git/*" \
  --exclude "node_modules/*" \
  --exclude "*.tfstate*" \
  --cache-control "public, max-age=3600"

# Wait 5-10 minutes for CloudFront to propagate globally
```

### (Optional) Set Up GitHub Actions for Auto-Deployment

1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add these secrets:
   ```
   AWS_ACCESS_KEY_ID = [your-key]
   AWS_SECRET_ACCESS_KEY = [your-secret]
   S3_BUCKET_NAME = [from terraform output]
   CLOUDFRONT_DISTRIBUTION_ID = [from terraform output]
   ```
3. Next push to main: GitHub Actions auto-syncs to S3 + invalidates CloudFront

---

## **Option 3: Both (Complete Showcase — 20 minutes)**

**Best for:** Demonstrating complete DevOps mastery, multiple deployment targets, interview impact

### Deploy to Both

```bash
# 1. Start Vercel deployment (it's faster)
# Go to https://vercel.com/import and deploy
# While Vercel initializes...

# 2. In parallel, deploy CloudFront
cd infrastructure
terraform init
terraform plan
terraform apply
# (This takes 5-15 min to fully activate)

# 3. Upload files to S3 while CloudFront initializes
S3_BUCKET="diamitani-portfolio-web-123456789"
aws s3 sync .. s3://$S3_BUCKET --delete --cache-control "public, max-age=3600"
```

**Results:**
```
✅ Vercel:       https://aws-sa-portfolio.vercel.app
✅ CloudFront:   https://d1234567890.cloudfront.net
✅ Both always in sync (single source of truth: GitHub)
✅ Demonstrates platform mastery
```

**Interview talking points:**
- "I deploy to Vercel for speed"
- "CloudFront demonstrates AWS architecture expertise"
- "GitHub Actions handles CI/CD automation"
- "Infrastructure is code (Terraform)"
- "Same site, two deployment targets, one codebase"

---

## **Verification Checklist**

After deployment, verify with this checklist:

```bash
# Test website loads
curl -I https://[your-url]/

# Check performance
curl -H "Accept-Encoding: gzip" https://[your-url]/ | head -20

# Check security headers
curl -I https://[your-url]/ | grep -E "Cache-Control|X-Content|X-Frame"

# Test mobile responsiveness
# Visit https://[your-url] on mobile

# Run Lighthouse
# https://pagespeed.web.dev/
# Target: 95+ performance, 100 accessibility
```

---

## **What Happens Next**

### Every Time You Push to `main`:

**Vercel:**
- Automatic deployment (2-3 min)
- Preview URL in PR
- Instant invalidation

**CloudFront (if GitHub Actions set up):**
- Automatic S3 sync
- Automatic cache invalidation
- Email notification on deploy

**No manual steps needed** — just `git push`

---

## **Interview Gold**

Your deployed site demonstrates:

✅ **Technical Judgment** — Architecture decisions explained  
✅ **AWS Expertise** — Well-Architected principles applied  
✅ **DevOps Maturity** — IaC, CI/CD, multi-target deployment  
✅ **Builder Mentality** — Real projects, documented decisions  
✅ **Leadership** — Community involvement, mentoring  
✅ **Teaching** — YouTube, resources, open sharing  

**The story:**
> "This person doesn't just talk about AWS — they deploy to it. IaC, multi-region CDN, automated CI/CD. They understand scaling, cost optimization, and Well-Architected patterns because they live them."

---

## **Quick Reference**

| Task | Command | Time |
|------|---------|------|
| Deploy to Vercel | Go to vercel.com/import | 5 min |
| Deploy to CloudFront | `cd infrastructure && terraform apply` | 15 min |
| Upload files to S3 | `aws s3 sync .. s3://bucket` | 2 min |
| Set up GitHub Actions | Add secrets in GitHub → Auto-deploy | 10 min |
| Check Lighthouse | https://pagespeed.web.dev/ | 2 min |
| Invalidate CloudFront | `aws cloudfront create-invalidation ...` | 5 min |

---

## **Support**

- Terraform stuck? See: `infrastructure/README.md`
- Deployment guide: `DEPLOYMENT_GUIDE.md`
- Architecture questions? See: `ARCHITECTURE.md`
- Design system: See: `DESIGN.md`

---

## **My Recommendation**

1. **Right now:** Deploy to Vercel (5 min) — get live immediately
2. **In parallel:** Set up CloudFront (15 min) — showcase AWS expertise
3. **Tomorrow:** Enable GitHub Actions (10 min) — demonstrate CI/CD mastery

**Total: 30 minutes to full deployment + automation**

---

**Pick your path. Ship it. Get hired.** 🎯

```
┌─────────────────────────────────────────┐
│  [ ] Vercel Deploy (5 min)              │
│  [ ] CloudFront Deploy (15 min)         │
│  [ ] GitHub Actions Setup (10 min)      │
│  [ ] Lighthouse Check (2 min)           │
│                                         │
│  TOTAL: ~30 minutes to ship             │
└─────────────────────────────────────────┘
```
