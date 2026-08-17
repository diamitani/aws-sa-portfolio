output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.portfolio.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.portfolio.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.portfolio.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.portfolio.id
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.portfolio.arn
}

output "deployment_instructions" {
  description = "Instructions for next steps"
  value       = <<-EOT
    Deployment successful!

    Website URL: https://${aws_cloudfront_distribution.portfolio.domain_name}
    S3 Bucket: ${aws_s3_bucket.portfolio.id}
    CloudFront Distribution ID: ${aws_cloudfront_distribution.portfolio.id}

    Next steps:
    1. Add custom domain (optional) - Create a CNAME record in Route53/DNS pointing to ${aws_cloudfront_distribution.portfolio.domain_name}
    2. Test the site - Visit https://${aws_cloudfront_distribution.portfolio.domain_name}
    3. Upload content - Use GitHub Actions or AWS CLI

    To deploy via GitHub Actions:
    1. Add these GitHub Secrets:
       - AWS_ACCESS_KEY_ID
       - AWS_SECRET_ACCESS_KEY
       - CLOUDFRONT_DISTRIBUTION_ID: ${aws_cloudfront_distribution.portfolio.id}
    2. Push to main branch - Automatic deployment
  EOT
}
