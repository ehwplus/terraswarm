output "this" {
  value       = docker_service.this
  description = "The output of the base docker service."
}

output "secrets" {
  value       = docker_secret.this
  description = "The secrets created with and for this base docker service."
}

output "configs" {
  value       = docker_config.this
  description = "The configs created with and for this base docker service."
}
