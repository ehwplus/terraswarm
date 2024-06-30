output "redis_service" {
  value       = module.redis_docker_service.this
  description = "The Redis service."
}

output "password" {
  value       = random_password.redis_password.result
  description = "The Redis password."
  sensitive   = true
}

output "host" {
  value       = local.name
  description = "The Redis service name which is also a network alias."
}

output "port" {
  value       = var.service_port
  description = "The Redis service port."
}