output "zitadel_service" {
  value       = module.zitadel_docker_service.this
  description = "The Zitadel service."
}

output "postgres" {
  value       = module.postgres_docker_service.this
  description = "The Zitadel PostgreSQL database."
  sensitive   = true
}

output "masterkey" {
  value       = random_password.masterkey.result
  description = "The Zitadel master key."
  sensitive   = true
}
