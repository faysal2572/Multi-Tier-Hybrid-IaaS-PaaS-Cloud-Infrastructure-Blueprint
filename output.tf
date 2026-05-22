output "alb_dns_name" {
  description = "The public URL used to access the application"
  value       = aws_lb.external.dns_name
}

output "database_endpoint" {
  description = "The private connection endpoint for the PaaS Database"
  value       = aws_db_instance.postgres.endpoint
}