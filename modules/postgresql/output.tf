output "service" {
  value       = module.postgresql_docker_service.this
  description = "The PostgreSQL docker service."
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
