output "redis_service" {
  value       = module.redis_docker_service.redis_service
  description = "The Redis service."
}

# output "postgres_service" {
#   value       = module.postgres_docker_service.this
#   description = "The PostgreSQL service."
# }

output "jwt_auth_secret" {
  value       = random_bytes.jwt_auth_secret
  description = "The Infisical auth secret."
  sensitive   = true
}

output "encryption_key" {
  value       = random_password.encryption_key
  description = "The Infisical encryption key."
  sensitive   = true
}
