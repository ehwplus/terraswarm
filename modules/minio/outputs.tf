output "minio_docker_service" {
  value       = module.minio_docker_service.this
  description = "The minio docker service"
}

output "service_name" {
  value       = module.minio_docker_service.this.name
  description = "The minio docker service name"
}

output "network_alias" {
  value       = var.name
  description = "The default hostname which can be resolved within the attached networks"
}

output "docker_volume" {
  value       = module.minio_docker_volume.this
  description = "The docker_volume resource underlying minio"
}

output "access_key" {
  value       = random_string.minio_access_key.result
  description = "The minio access_key string"
  sensitive   = true
}

output "secret_key" {
  value       = random_password.minio_secret_key.result
  description = "The minio secret_key string"
  sensitive   = true
}
