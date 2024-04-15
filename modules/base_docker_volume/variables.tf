variable "name" {
  type        = string
  description = "The docker volume name"
  nullable    = false
}

variable "namespace" {
  type        = string
  description = "The namespace of Docker Swarm"
  default     = null
}

variable "driver" {
  type        = string
  description = "Driver type for the volume. Defaults to 'local'."
  default     = "local"
}

variable "driver_options" {
  type        = map(string)
  description = "Options specific to the driver."
  default     = {}
}
