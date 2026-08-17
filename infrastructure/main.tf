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
  region = var.aws_region
}

# S3 Bucket for Website
resource "aws_s3_bucket" "portfolio" {
  bucket = var.s3_bucket_name

  tags = {
    Name        = "Portfolio Website"
    Environment = "production"
    Owner       = "Patrick Diamitani"
    Project     = "AWS SA Portfolio"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "portfolio" {
  name                              = "portfolio-oac"
  description                       = "Portfolio OAC for S3"
  origin_access_control_origin_type = "s3"
}

# S3 Bucket Policy for CloudFront
resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudFrontReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.portfolio.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.portfolio.arn
          }
        }
      }
    ]
  })
}

# Cache Policy for HTML (short TTL)
resource "aws_cloudfront_cache_policy" "html_cache" {
  name            = "portfolio-html-cache"
  comment         = "Cache policy for HTML files (1 hour)"
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

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# Cache Policy for Static Assets (long TTL)
resource "aws_cloudfront_cache_policy" "static_cache" {
  name            = "portfolio-static-cache"
  comment         = "Cache policy for static assets (1 year)"
  default_ttl     = 604800
  max_ttl         = 31536000
  min_ttl         = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "portfolio" {
  enabled             = true
  default_root_object = "index.html"
  http_version        = "http2and3"

  origin {
    domain_name              = aws_s3_bucket.portfolio.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.portfolio.id
  }

  # Default cache behavior for HTML
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"
    compress         = true

    cache_policy_id = aws_cloudfront_cache_policy.html_cache.id

    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior for static assets
  cache_behaviors = [
    {
      path_pattern     = "*.js"
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "S3Origin"
      compress         = true

      cache_policy_id = aws_cloudfront_cache_policy.static_cache.id

      viewer_protocol_policy = "redirect-to-https"
    },
    {
      path_pattern     = "*.css"
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "S3Origin"
      compress         = true

      cache_policy_id = aws_cloudfront_cache_policy.static_cache.id

      viewer_protocol_policy = "redirect-to-https"
    },
    {
      path_pattern     = "*.webp"
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "S3Origin"
      compress         = true

      cache_policy_id = aws_cloudfront_cache_policy.static_cache.id

      viewer_protocol_policy = "redirect-to-https"
    },
    {
      path_pattern     = "*.png"
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "S3Origin"
      compress         = true

      cache_policy_id = aws_cloudfront_cache_policy.static_cache.id

      viewer_protocol_policy = "redirect-to-https"
    },
    {
      path_pattern     = "*.jpg"
      allowed_methods  = ["GET", "HEAD"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "S3Origin"
      compress         = true

      cache_policy_id = aws_cloudfront_cache_policy.static_cache.id

      viewer_protocol_policy = "redirect-to-https"
    }
  ]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name      = "Portfolio CloudFront"
    ManagedBy = "Terraform"
  }
}

# CloudWatch Log Group for CloudFront
resource "aws_cloudwatch_log_group" "cloudfront" {
  name              = "/aws/cloudfront/portfolio"
  retention_in_days = 7

  tags = {
    Name      = "Portfolio CloudFront Logs"
    ManagedBy = "Terraform"
  }
}
