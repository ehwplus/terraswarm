output "this" {
  value       = module.postgresql_docker_service.this
  description = "The PostgreSQL docker service."
}

output "postgresql_secret" {
  value       = module.postgresql_docker_service.secrets
  description = "The PostgreSQL docker secrets."
}

output "user" {
  value       = random_string.postgres_user.result
  description = "The PostgreSQL user."
  sensitive   = true
}

output "password" {
  value       = random_password.postgres_password.result
  description = "The PostgreSQL password."
  sensitive   = true
}
