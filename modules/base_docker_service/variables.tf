################################################################################
# Service
################################################################################

variable "name" {
  type        = string
  description = "The service name which must not be longer than 63 characters. This name will also be used as a network alias for all attached networks."
  nullable    = false
}

variable "namespace" {
  type        = string
  description = "(Optional) The namespace of Docker Swarm"
  default     = null
}

variable "image" {
  type        = string
  description = "The docker image name excluding the image tag"
}

variable "image_tag" {
  type        = string
  description = "(Optional) The image tag of the docker image. Defaults to: latest"
  default     = "latest"
}

variable "command" {
  type        = list(string)
  description = "(Optional) The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service."
  default     = null
}

variable "args" {
  type        = list(string)
  description = "(Optional) The arguments to pass to the docker image"
  default     = null
}

variable "env" {
  type        = map(string)
  description = "(Optional) The environmental variables to pass to the docker image"
  default     = null
}

variable "secrets" {
  type = set(object({
    file_name = string
    # secret_id   = string # secret will be created and we take that resource id
    file_gid    = optional(string, "0")
    file_mode   = optional(number, 0444)
    file_uid    = optional(string, "0")
    secret_name = optional(string, null)
    secret_data = string
  }))
  description = "(Optional) The secrets to create with and add to the docker container. Creates docker secrets from non-terraform-resources."
  default     = []
}

variable "secret_map" {
  type = map(object({
    file_name = string
    # secret_id   = string # secret will be created and we take that resource id
    file_gid    = optional(string, "0")
    file_mode   = optional(number, 0444)
    file_uid    = optional(string, "0")
    secret_name = optional(string, null)
    secret_data = string
  }))
  validation {
    condition = can(alltrue([
      for value in var.secret_map : regex("^(0?[0-9]{3})$", value.file_mode)
    ]))
    error_message = "Invalid configs.key.file_mode input, must comply with regex '^(0?[0-9]{3})$'."
  }
  description = <<EOT
    (Optional) Similar to the secrets variable but allows for docker secret creation from terraform resources.
    
    secret_map = {
      key = {
        file_name   = Represents the final filename in the filesystem.
        secret_id   = ID of the specific secret that we're referencing.
        file_gid    = Represents the file GID. Defaults to '0'.
        file_mode   = Represents represents the FileMode of the file. Defaults to '0o444'.
        file_uid    = Represents the file UID. Defaults to '0'.
        secret_name = Name of the secret that this references, but this is just provided for lookup/display purposes. The config in the reference will be identified by its ID.

      }
    }
  EOT
  default     = {}
}

variable "configs" {
  type = set(object({
    file_name = string
    # config_id   = string # config will be created and we take that resource id
    file_gid    = optional(string)
    file_mode   = optional(number, 0444)
    file_uid    = optional(string)
    config_name = optional(string, null)
    config_data = string
  }))
  validation {
    condition = can(alltrue([
      for value in var.configs : value.file_mode == null || regex("^(0?[0-7]{3})$", value.file_mode)
    ]))
    error_message = "Invalid configs.key.file_mode input, must comply with regex '^(0?[0-7]{3})$'."
  }
  description = <<EOT
    configs = [{
      config_id   = ID of the specific config that we're referencing
      file_name   = Represents the final filename in the filesystem
      config_name = Name of the config that this references, but this is just provided for lookup/display purposes. The config in the reference will be identified by its ID
      file_gid    = Represents the file GID. Defaults to '0'.
      file_mode   = Represents represents the FileMode of the file. Defaults to '0o444'.
      file_uid    = Represents the file UID. Defaults to '0'.
    }]
  EOT
  default     = []
}

variable "mounts" {
  type = set(object({
    target = string
    type   = string
    # bind_options conflict with volume, so we omit it from the input!
    # bind_options   = optional(object({ propagation = optional(string) }), null),
    read_only      = optional(bool, false)
    source         = optional(string)
    tmpfs_options  = optional(object({ mode = optional(number), size_bytes = optional(number) }), null)
    volume_options = optional(object({ driver_name = optional(string), driver_options = optional(map(string)), labels = optional(map(string)), no_copy = optional(bool) }), {})
  }))
  description = <<EOT
    mounts = [{
      target        = Container path
      type          = The mount type
      source        = Mount source (e.g. a volume name, a host path)
      read_only     = Whether the mount should be read-only
      tmpfs_options = {
        mode       = The permission mode for the tmpfs mount in an integer
        size_bytes = The size for the tmpfs mount in bytes
      }
      volume_options = {
        driver_name    = Name of the driver to use to create the volume
        driver_options = key/value map of driver specific options
        labels         = [{
          label = Name of the label
          value = Value of the label
        }]
        no_copy        = Populate volume with data from the target.
      }
    }]
  EOT
  default     = []
}

variable "labels" {
  type        = map(string)
  description = "(Optional) Labels to add to the service and container"
  default     = {}
}

variable "constraints" {
  type        = set(string)
  description = "(Optional) The container placement constraints"
  default     = []
}

variable "limit" {
  type = object({
    cores  = optional(number)
    memory = optional(number)
  })
  description = "(Optional) The resources limit of service, memory unit is MB"
  default     = null
}

variable "reservation" {
  type = object({
    cores  = optional(number)
    memory = optional(number)
  })
  description = "(Optional) The resource reservation of service, memory unit is MB"
  default     = null
}

variable "restart_policy" {
  type = object({
    condition    = optional(string)
    delay        = optional(string)
    max_attempts = optional(number)
    window       = optional(string)
  })
  validation {
    condition     = can(regex("^(none|on-failure|any)$", var.restart_policy.condition))
    error_message = "Invalid input, options: \"none\", \"on-failure\", \"any\"."
  }
  validation {
    condition     = can(regex("^([0-9]+s)$", var.restart_policy.delay))
    error_message = "Invalid delay input, must comply with regex '^([0-9]+s)$'."
  }
  validation {
    condition     = can(regex("^([0-9]+s)$", var.restart_policy.window))
    error_message = "Invalid window input, must comply with regex '^([0-9]+s)$'."
  }
  description = <<EOT
    restart_policy = {
      condition    = Condition for restart; possible options are "none" which does not automatically restart, "on-failure" restarts on non-zero exit, "any" (default) restarts regardless of exit status.
      delay        = Delay between restart attempts (default is 5s) (ms|s|m|h).
      max_attempts = How many times to attempt to restart a container before giving up (default: 0, i.e. never give up). If the restart does not succeed within the configured window, this attempt doesn't count toward the configured max_attempts value. For example, if max_attempts is set to '2', and the restart fails on the first attempt, more than two restarts must be attempted.
      window       = The time window used to evaluate the restart policy (default value is 5s, 0 means unbounded) (ms|s|m|h).
    }
  EOT
  default = {
    condition    = "any"
    delay        = "5s"
    max_attempts = 0
    window       = "5s"
  }
}

# TODO join var.networks and network_aliases to have different hostnames per network?
variable "networks" {
  type        = set(string)
  description = "(Optional) The networks attached to this service"
  default     = []
}
variable "network_aliases" {
  type        = list(string)
  description = "(Optional) Aliases (alternative hostnames) for this service on all specified networks. Other containers on the same network can use either the service name or this alias to connect to one of the service's containers. See https://docs.docker.com/compose/compose-file/compose-file-v3/#aliases for more information."
  default     = []
}

variable "mode" {
  type = object({
    global = optional(bool, false)
    replicated = optional(object({
      replicas = number
    }), { replicas = 1 })
  })
  validation {
    condition     = var.mode.replicated.replicas > 0
    error_message = "Replicas must be greather than zero"
  }
  description = <<EOT
    type = {
      global = The global service mode. Defaults to 'false'.
      replicated = {
        replicas = The amount of replicas of the service. Defaults to '1'.
      }
    }
  EOT
  default = {
    global = false,
    replicated = {
      replicas = 1
    }
  }
}

variable "ports" {
  type = list(object({
    target_port    = number,
    name           = optional(string),
    protocol       = optional(string, "tcp"),
    publish_mode   = optional(string, "ingress")
    published_port = optional(number),
  }))
  validation {
    condition = can(alltrue([
      for port in var.ports : regex("^(tcp|udp|sctp)$", port.protocol)
    ]))
    error_message = "Invalid port.[].protocol input, must be one of: \"tcp\", \"udp\", \"sctp\"."
  }
  validation {
    condition = can(alltrue([
      for port in var.ports : regex("^(ingress|host)$", port.publish_mode)
    ]))
    error_message = "Invalid port.[].publish_mode input, must be one of: \"ingress\", \"host\"."
  }
  description = <<EOT
    ports = [{
      target_port    = The port inside the container.
      name           = A random name for the port.
      protocol       = Represents the protocol of a port: tcp, udp or sctp. Defaults to 'tcp'.
      publish_mode   = Represents the mode in which the port is to be published: 'ingress' or 'host'. Defaults to 'ingress'.
      published_port = The port on the swarm hosts.
    }]
  EOT
  default     = []
}

variable "auth" {
  type = object({
    server_address = optional(string)
    username       = string
    password       = string
  })
  description = <<EOT
    auth = {
      server_address = The address of the server for the authentication against a private docker registry.
      username       = The password.
      password       = The username.
    }
  EOT
  nullable    = true
  sensitive   = true
  default     = null
}

variable "healthcheck" {
  type = object({
    test         = list(string)
    interval     = optional(string, "0s")
    timeout      = optional(string, "0s")
    retries      = optional(number, 0)
    start_period = optional(string, "0s")
  })
  validation {
    condition     = var.healthcheck == null || can(regex("^([0-9]+s)$", var.healthcheck.interval))
    error_message = "Invalid interval input, must comply with regex '^([0-9]+s)$'."
  }
  validation {
    condition     = var.healthcheck == null || can(regex("^([0-9]+s)$", var.healthcheck.timeout))
    error_message = "Invalid timeout input, must comply with regex '^([0-9]+s)$'."
  }
  validation {
    condition     = var.healthcheck == null || can(regex("^([0-9]+s)$", var.healthcheck.start_period))
    error_message = "Invalid start_period input, must comply with regex '^([0-9]+s)$'."
  }
  description = <<EOT
    healthcheck = {
      test         = The test to be performed in CMD format.
      interval     = Time between running the check (ms|s|m|h). Defaults to '0s'.
      timeout      = Maximum time to allow one check to run (ms|s|m|h). Defaults to '0s'.
      retries      = Consecutive failures needed to report unhealthy. Defaults to '0'.
      start_period = Start period for the container to initialize before counting retries towards unstable (ms|s|m|h). Defaults to '0s'.
    }
  EOT
  nullable    = true
  default     = null
}
