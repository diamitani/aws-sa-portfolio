terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Use S3 + DynamoDB for state management (see backend setup below)
  # backend "s3" {
  #   bucket         = "diamitani-terraform-state"
  #   key            = "portfolio/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
}

# ========================================
# S3 Bucket for Static Website
# ========================================

resource "aws_s3_bucket" "portfolio_web" {
  bucket = "diamitani-portfolio-web-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Patrick Diamitani Portfolio"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_versioning" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ========================================
# CloudFront Origin Access Identity
# ========================================

resource "aws_cloudfront_origin_access_identity" "portfolio_oai" {
  comment = "OAI for Patrick Diamitani portfolio"
}

# ========================================
# S3 Bucket Policy (CloudFront Access Only)
# ========================================

resource "aws_s3_bucket_policy" "portfolio_web" {
  bucket = aws_s3_bucket.portfolio_web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.portfolio_oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.portfolio_web.arn}/*"
      }
    ]
  })
}

# ========================================
# ACM Certificate (HTTPS)
# ========================================

resource "aws_acm_certificate" "portfolio" {
  domain_name       = var.domain_name != "" ? var.domain_name : "diamitani-portfolio.example.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Portfolio SSL Certificate"
  }
}

# ========================================
# CloudFront Distribution
# ========================================

resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100" # US, Europe, Asia

  origin {
    domain_name            = aws_s3_bucket.portfolio_web.bucket_regional_domain_name
    origin_id              = "S3Origin"
    origin_access_identity = aws_cloudfront_origin_access_identity.portfolio_oai.cloudfront_access_identity_path

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.portfolio_oai.cloudfront_access_identity_path
    }
  }

  # Cache behavior for HTML files (short TTL)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

      headers = ["Accept-Encoding"]
    }

    min_ttl     = 0
    default_ttl = 3600    # 1 hour
    max_ttl     = 86400   # 24 hours

    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior for CSS/JS/Images (long TTL)
  cache_behavior {
    path_pattern     = "*.{css,js,png,jpg,jpeg,gif,svg,webp,woff,woff2}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

      headers = ["Accept-Encoding"]
    }

    min_ttl     = 86400     # 1 day
    default_ttl = 604800    # 7 days
    max_ttl     = 31536000  # 1 year

    viewer_protocol_policy = "allow-all"
  }

  # Error page handling
  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 300
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 300
    response_code         = 200
    response_page_path    = "/index.html"
  }

  # Security headers
  viewer_certificate {
    cloudfront_default_certificate = var.domain_name == "" ? true : null
    acm_certificate_arn            = var.domain_name != "" ? aws_acm_certificate.portfolio.arn : null
    ssl_support_method             = var.domain_name != "" ? "sni-only" : null
    minimum_protocol_version       = var.domain_name != "" ? "TLSv1.2_2021" : null
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "Portfolio CloudFront Distribution"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ========================================
# Route53 DNS Record (Optional)
# ========================================

resource "aws_route53_record" "portfolio" {
  count   = var.hosted_zone_id != "" ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.portfolio.domain_name
    zone_id                = aws_cloudfront_distribution.portfolio.hosted_zone_id
    evaluate_target_health = false
  }
}

# ========================================
# Data Sources
# ========================================

data "aws_caller_identity" "current" {}

# ========================================
# Outputs
# ========================================

output "s3_bucket_name" {
  value       = aws_s3_bucket.portfolio_web.bucket
  description = "S3 bucket name for the portfolio website"
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.portfolio.domain_name
  description = "CloudFront distribution domain name"
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.portfolio.id
  description = "CloudFront distribution ID for invalidations"
}

output "cloudfront_zone_id" {
  value       = aws_cloudfront_distribution.portfolio.hosted_zone_id
  description = "CloudFront hosted zone ID (for Route53)"
}

output "deployment_url" {
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "https://${aws_cloudfront_distribution.portfolio.domain_name}"
  description = "Website deployment URL"
}
