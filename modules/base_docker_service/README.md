# base_docker_service

This module serves as a canonical foundation for higher level services.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.2 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | 3.0.2 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_docker"></a> [docker](#provider\_docker) | 3.0.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [docker_config.this](https://registry.terraform.io/providers/kreuzwerker/docker/3.0.2/docs/resources/config) | resource |
| [docker_secret.this](https://registry.terraform.io/providers/kreuzwerker/docker/3.0.2/docs/resources/secret) | resource |
| [docker_service.this](https://registry.terraform.io/providers/kreuzwerker/docker/3.0.2/docs/resources/service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_args"></a> [args](#input\_args) | (Optional) The arguments to pass to the docker image | `list(string)` | `null` | no |
| <a name="input_auth"></a> [auth](#input\_auth) | (Optional) The authentication for a private docker registry.<br><br>    auth = {<br>      server\_address = The address of the server for the authentication against a private docker registry.<br>      username       = The password.<br>      password       = The username.<br>    } | <pre>object({<br>    server_address = optional(string)<br>    username       = string<br>    password       = string<br>  })</pre> | `null` | no |
| <a name="input_command"></a> [command](#input\_command) | (Optional) The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service. | `list(string)` | `null` | no |
| <a name="input_configs"></a> [configs](#input\_configs) | (Optional) A list of configs that will be created and mounted by the service.<br><br>    configs = [{<br>      config\_id   = ID of the specific config that we're referencing<br>      file\_name   = Represents the final filename in the filesystem<br>      config\_name = Name of the config that this references, but this is just provided for lookup/display purposes. The config in the reference will be identified by its ID<br>      file\_gid    = Represents the file GID. Defaults to '0'.<br>      file\_mode   = Represents represents the FileMode of the file. Defaults to '0o444'.<br>      file\_uid    = Represents the file UID. Defaults to '0'.<br>    }] | <pre>set(object({<br>    file_name = string<br>    # config_id   = string # config will be created and we take that resource id<br>    file_gid    = optional(string)<br>    file_mode   = optional(number, 0444)<br>    file_uid    = optional(string)<br>    config_name = optional(string, null)<br>    config_data = string<br>  }))</pre> | `[]` | no |
| <a name="input_constraints"></a> [constraints](#input\_constraints) | (Optional) The container placement constraints | `set(string)` | `[]` | no |
| <a name="input_env"></a> [env](#input\_env) | (Optional) The environmental variables to pass to the docker image | `map(string)` | `null` | no |
| <a name="input_healthcheck"></a> [healthcheck](#input\_healthcheck) | healthcheck = {<br>      test         = The test to be performed in CMD format.<br>      interval     = Time between running the check (ms\|s\|m\|h). Defaults to '0s'.<br>      timeout      = Maximum time to allow one check to run (ms\|s\|m\|h). Defaults to '0s'.<br>      retries      = Consecutive failures needed to report unhealthy. Defaults to '0'.<br>      start\_period = Start period for the container to initialize before counting retries towards unstable (ms\|s\|m\|h). Defaults to '0s'.<br>    } | <pre>object({<br>    test         = list(string)<br>    interval     = optional(string, "0s")<br>    timeout      = optional(string, "0s")<br>    retries      = optional(number, 0)<br>    start_period = optional(string, "0s")<br>  })</pre> | `null` | no |
| <a name="input_image"></a> [image](#input\_image) | The docker image name excluding the image tag | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | (Optional) The image tag of the docker image. Defaults to: latest | `string` | `"latest"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | (Optional) Labels to add to the service and container | `map(string)` | `{}` | no |
| <a name="input_limit"></a> [limit](#input\_limit) | (Optional) The resources limit of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | (Optional) The service mode. Defaults to 'replicated' with replicas set to 1.<br>    type = {<br>      global = The global service mode. Defaults to 'false'.<br>      replicated = {<br>        replicas = The amount of replicas of the service. Defaults to '1'.<br>      }<br>    } | <pre>object({<br>    global = optional(bool, false)<br>    replicated = optional(object({<br>      replicas = number<br>    }), { replicas = 1 })<br>  })</pre> | <pre>{<br>  "global": false,<br>  "replicated": {<br>    "replicas": 1<br>  }<br>}</pre> | no |
| <a name="input_mounts"></a> [mounts](#input\_mounts) | (Optional) Mounts of this docker service.<br><br>    mounts = [{<br>      target        = Container path<br>      type          = The mount type<br>      source        = Mount source (e.g. a volume name, a host path)<br>      read\_only     = Whether the mount should be read-only<br>      tmpfs\_options = {<br>        mode       = The permission mode for the tmpfs mount in an integer<br>        size\_bytes = The size for the tmpfs mount in bytes<br>      }<br>      volume\_options = {<br>        driver\_name    = Name of the driver to use to create the volume<br>        driver\_options = key/value map of driver specific options<br>        labels         = [{<br>          label = Name of the label<br>          value = Value of the label<br>        }]<br>        no\_copy        = Populate volume with data from the target.<br>      }<br>    }] | <pre>set(object({<br>    target = string<br>    type   = string<br>    # bind_options conflict with volume, so we omit it from the input!<br>    # bind_options   = optional(object({ propagation = optional(string) }), null),<br>    read_only      = optional(bool, false)<br>    source         = optional(string)<br>    tmpfs_options  = optional(object({ mode = optional(number), size_bytes = optional(number) }), null)<br>    volume_options = optional(object({ driver_name = optional(string), driver_options = optional(map(string)), labels = optional(map(string)), no_copy = optional(bool) }), null)<br>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The service name which must not be longer than 63 characters. This name will also be used as a network alias for all attached networks. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | (Optional) The namespace of Docker Swarm | `string` | `null` | no |
| <a name="input_network_aliases"></a> [network\_aliases](#input\_network\_aliases) | (Optional) Aliases (alternative hostnames) for this service on all specified networks. Other containers on the same network can use either the service name or this alias to connect to one of the service's containers. See https://docs.docker.com/compose/compose-file/compose-file-v3/#aliases for more information. | `list(string)` | `[]` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | (Optional) Attaches this service to the following network IDs. You can also supply names but those will force replacement in the terraform state. | `set(string)` | `[]` | no |
| <a name="input_ports"></a> [ports](#input\_ports) | (Optional) The ports to expose on the swarm for the service.<br><br>    ports = [{<br>      target\_port    = The port inside the container.<br>      name           = A random name for the port.<br>      protocol       = Represents the protocol of a port: tcp, udp or sctp. Defaults to 'tcp'.<br>      publish\_mode   = Represents the mode in which the port is to be published: 'ingress' or 'host'. Defaults to 'ingress'.<br>      published\_port = The port on the swarm hosts.<br>    }] | <pre>list(object({<br>    target_port    = number,<br>    name           = optional(string),<br>    protocol       = optional(string, "tcp"),<br>    publish_mode   = optional(string, "ingress")<br>    published_port = optional(number),<br>  }))</pre> | `[]` | no |
| <a name="input_reservation"></a> [reservation](#input\_reservation) | (Optional) The resource reservation of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>    generic_resources = optional(object({<br>      discrete_resources_spec = optional(set(string))<br>      named_resources_spec    = optional(set(string))<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy) | (Optional) Restart policy for containers.<br><br>    restart\_policy = {<br>      condition    = Condition for restart; possible options are "none" which does not automatically restart, "on-failure" restarts on non-zero exit, "any" (default) restarts regardless of exit status.<br>      delay        = Delay between restart attempts (default is 5s) (ms\|s\|m\|h).<br>      max\_attempts = How many times to attempt to restart a container before giving up (default: 0, i.e. never give up). If the restart does not succeed within the configured window, this attempt doesn't count toward the configured max\_attempts value. For example, if max\_attempts is set to '2', and the restart fails on the first attempt, more than two restarts must be attempted.<br>      window       = The time window used to evaluate the restart policy (default value is 5s, 0 means unbounded) (ms\|s\|m\|h).<br>    } | <pre>object({<br>    condition    = optional(string, "any")<br>    delay        = optional(string, "5s")<br>    max_attempts = optional(number, 0)<br>    window       = optional(string, "5s")<br>  })</pre> | <pre>{<br>  "condition": "any",<br>  "delay": "5s",<br>  "max_attempts": 0,<br>  "window": "5s"<br>}</pre> | no |
| <a name="input_secret_map"></a> [secret\_map](#input\_secret\_map) | (Optional) Similar to the secrets variable but allows for docker secret creation from terraform resources.<br><br>    secret\_map = {<br>      key = {<br>        file\_name   = Represents the final filename in the filesystem.<br>        secret\_id   = ID of the specific secret that we're referencing.<br>        file\_gid    = Represents the file GID. Defaults to '0'.<br>        file\_mode   = Represents represents the FileMode of the file. Defaults to '0o444'.<br>        file\_uid    = Represents the file UID. Defaults to '0'.<br>        secret\_name = Name of the secret that this references, but this is just provided for lookup/display purposes. The config in the reference will be identified by its ID.<br>      }<br>    } | <pre>map(object({<br>    file_name = string<br>    # secret_id   = string # secret will be created and we take that resource id<br>    file_gid    = optional(string, "0")<br>    file_mode   = optional(number, 0444)<br>    file_uid    = optional(string, "0")<br>    secret_name = optional(string, null)<br>    secret_data = string<br>  }))</pre> | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | (Optional) The secrets to create with and add to the docker container. Creates docker secrets from non-terraform-resources. | <pre>set(object({<br>    file_name   = optional(string)<br>    secret_id   = optional(string, null) # secret_id will be auto-generated if not provided; secrets with secret_id must exist beforehand<br>    file_gid    = optional(string, "0")<br>    file_mode   = optional(number, 0444)<br>    file_uid    = optional(string, "0")<br>    secret_name = optional(string, null)<br>    secret_data = string<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configs"></a> [configs](#output\_configs) | The configs created with and for this base docker service. |
| <a name="output_secrets"></a> [secrets](#output\_secrets) | The secrets created with and for this base docker service. |
| <a name="output_this"></a> [this](#output\_this) | The output of the base docker service. |
<!-- END_TF_DOCS -->
