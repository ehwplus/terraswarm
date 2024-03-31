##
## Docker service inputs
##

variable "name" {
  type        = string
  description = "The OpenTelemetry service name. Name must not be longer than `58 - len(namespace)`"
  nullable    = false
}

variable "namespace" {
  type        = string
  description = "The namespace of Docker Swarm"
  default     = null
}

variable "image" {
  type        = string
  description = "The image of OpenTelemetry"
  default     = null
}

variable "image_tag" {
  type        = string
  description = "The image tag of OpenTelemetry to specify version"
  default     = "latest"
}

variable "networks" {
  type        = list(string)
  description = "The networks attached"
  default     = []
}

variable "limit" {
  type = object({
    cores  = optional(number)
    memory = optional(number)
  })
  description = "The resources limit of service, memory unit is MB"
  default     = null
}

variable "reservation" {
  type = object({
    cores  = optional(number)
    memory = optional(number)
  })
  description = "The resource reservation of service, memory unit is MB"
  default     = null
}


##
## OpenTelemtry Collector inputs
##

variable "config" {
  type        = string
  description = "The static config file for OpenTelemtry Collector"
  default     = null
}

variable "service_port" {
  type        = number
  description = "The internal and external service port for OpenTelemetry receiver"
  nullable    = false
  default     = 4317
}

variable "auth" {
  type = object({
    server_address = optional(string)
    username       = string
    password       = string
  })
  description = <<EOT
    auth = {
      server_address = The address of the server for the authentication.
      username       = The password.
      password       = The username
    }
  EOT
  nullable    = true
  default     = null
  sensitive   = true
}
