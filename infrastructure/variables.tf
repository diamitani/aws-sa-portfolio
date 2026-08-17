variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for portfolio website"
  type        = string
  default     = "diamitani-portfolio-web"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
