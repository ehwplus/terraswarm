output "service" {
  value       = module.this.this
  description = "The PostgreSQL service"
}

output "user" {
  value       = random_string.postgres_user.result
  description = "The PostgreSQL user"
  sensitive   = true
}

output "password" {
  value       = random_password.postgres_password.result
  description = "The PostgreSQL password"
  sensitive   = true
}
