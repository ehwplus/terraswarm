# grafana

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.2 |
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | 3.0.2 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_grafana_docker_service"></a> [grafana\_docker\_service](#module\_grafana\_docker\_service) | github.com/ehwplus/terraswarm//modules/base_docker_service | main |
| <a name="module_grafana_docker_volume"></a> [grafana\_docker\_volume](#module\_grafana\_docker\_volume) | github.com/ehwplus/terraswarm//modules/base_docker_volume | main |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auth"></a> [auth](#input\_auth) | (Optional) The authentication for a private docker registry.<br><br>    auth = {<br>      server\_address = The address of the server for the authentication against a private docker registry.<br>      username       = The password.<br>      password       = The username.<br>    } | <pre>object({<br>    server_address = optional(string)<br>    username       = string<br>    password       = string<br>  })</pre> | `null` | no |
| <a name="input_constraints"></a> [constraints](#input\_constraints) | (Optional) The container placement constraints | `set(string)` | `[]` | no |
| <a name="input_custom_image"></a> [custom\_image](#input\_custom\_image) | The docker image name excluding the image tag | `string` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | (Optional) The environmental variables to pass to the docker image | `map(string)` | `null` | no |
| <a name="input_grafana_config"></a> [grafana\_config](#input\_grafana\_config) | The config file for Grafana | `string` | `null` | no |
| <a name="input_grafana_service_port"></a> [grafana\_service\_port](#input\_grafana\_service\_port) | The internal and external service port for Grafana | `number` | `3000` | no |
| <a name="input_healthcheck"></a> [healthcheck](#input\_healthcheck) | healthcheck = {<br>      test         = The test to be performed in CMD format.<br>      interval     = Time between running the check (ms\|s\|m\|h). Defaults to '0s'.<br>      timeout      = Maximum time to allow one check to run (ms\|s\|m\|h). Defaults to '0s'.<br>      retries      = Consecutive failures needed to report unhealthy. Defaults to '0'.<br>      start\_period = Start period for the container to initialize before counting retries towards unstable (ms\|s\|m\|h). Defaults to '0s'.<br>    } | <pre>object({<br>    test         = list(string)<br>    interval     = optional(string, "0s")<br>    timeout      = optional(string, "0s")<br>    retries      = optional(number, 0)<br>    start_period = optional(string, "0s")<br>  })</pre> | `null` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | (Optional) The image tag of the docker image. Defaults to: latest | `string` | `"latest"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | (Optional) Labels to add to the service and container | `map(string)` | `{}` | no |
| <a name="input_limit"></a> [limit](#input\_limit) | (Optional) The resources limit of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | (Optional) The service mode. Defaults to 'replicated' with replicas set to 1.<br>    type = {<br>      global = The global service mode. Defaults to 'false'.<br>      replicated = {<br>        replicas = The amount of replicas of the service. Defaults to '1'.<br>      }<br>    } | <pre>object({<br>    global = optional(bool, false)<br>    replicated = optional(object({<br>      replicas = number<br>    }), { replicas = 1 })<br>  })</pre> | <pre>{<br>  "global": false,<br>  "replicated": {<br>    "replicas": 1<br>  }<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The service name which must not be longer than 63 characters. This name will also be used as a network alias for all attached networks. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | (Optional) The namespace of Docker Swarm | `string` | `null` | no |
| <a name="input_network_aliases"></a> [network\_aliases](#input\_network\_aliases) | (Optional) Aliases (alternative hostnames) for this service on all specified networks. Other containers on the same network can use either the service name or this alias to connect to one of the service's containers. See https://docs.docker.com/compose/compose-file/compose-file-v3/#aliases for more information. | `list(string)` | `[]` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | (Optional) The networks attached to this service | `set(string)` | `[]` | no |
| <a name="input_reservation"></a> [reservation](#input\_reservation) | (Optional) The resource reservation of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>    generic_resources = optional(object({<br>      discrete_resources_spec = optional(set(string))<br>      named_resources_spec    = optional(set(string))<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy) | (Optional) Restart policy for containers.<br><br>    restart\_policy = {<br>      condition    = Condition for restart; possible options are "none" which does not automatically restart, "on-failure" restarts on non-zero exit, "any" (default) restarts regardless of exit status.<br>      delay        = Delay between restart attempts (default is 5s) (ms\|s\|m\|h).<br>      max\_attempts = How many times to attempt to restart a container before giving up (default: 0, i.e. never give up). If the restart does not succeed within the configured window, this attempt doesn't count toward the configured max\_attempts value. For example, if max\_attempts is set to '2', and the restart fails on the first attempt, more than two restarts must be attempted.<br>      window       = The time window used to evaluate the restart policy (default value is 5s, 0 means unbounded) (ms\|s\|m\|h).<br>    } | <pre>object({<br>    condition    = optional(string, "any")<br>    delay        = optional(string, "5s")<br>    max_attempts = optional(number, 0)<br>    window       = optional(string, "5s")<br>  })</pre> | <pre>{<br>  "condition": "any",<br>  "delay": "5s",<br>  "max_attempts": 0,<br>  "window": "5s"<br>}</pre> | no |
| <a name="input_secret_map"></a> [secret\_map](#input\_secret\_map) | (Optional) Similar to the secrets variable but allows for docker secret creation from terraform resources.<br><br>    secret\_map = {<br>      key = {<br>        file\_name   = Represents the final filename in the filesystem.<br>        secret\_id   = ID of the specific secret that we're referencing.<br>        file\_gid    = Represents the file GID. Defaults to '0'.<br>        file\_mode   = Represents represents the FileMode of the file. Defaults to '0o444'.<br>        file\_uid    = Represents the file UID. Defaults to '0'.<br>        secret\_name = Name of the secret that this references, but this is just provided for lookup/display purposes. The config in the reference will be identified by its ID.<br>      }<br>    } | <pre>map(object({<br>    file_name = string<br>    # secret_id   = string # secret will be created and we take that resource id<br>    file_gid    = optional(string, "0")<br>    file_mode   = optional(number, 0444)<br>    file_uid    = optional(string, "0")<br>    secret_name = optional(string, null)<br>    secret_data = string<br>  }))</pre> | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | (Optional) The secrets to create with and add to the docker container. Creates docker secrets from non-terraform-resources. | <pre>set(object({<br>    file_name = string<br>    # secret_id   = string # secret will be created and we take that resource id<br>    file_gid    = optional(string, "0")<br>    file_mode   = optional(number, 0444)<br>    file_uid    = optional(string, "0")<br>    secret_name = optional(string, null)<br>    secret_data = string<br>  }))</pre> | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_this"></a> [this](#output\_this) | The grafana docker service. |
<!-- END_TF_DOCS -->
