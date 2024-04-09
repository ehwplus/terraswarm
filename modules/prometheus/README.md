# prometheus

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_docker_volume"></a> [docker\_volume](#module\_docker\_volume) | ../base_docker_volume | n/a |
| <a name="module_this"></a> [this](#module\_this) | ../base_docker_service | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | The static config file for Prometheus | `string` | `null` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The image tag of Prometheus to specify version | `string` | `"latest"` | no |
| <a name="input_limit"></a> [limit](#input\_limit) | The resources limit of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The Prometheus service name. Name must not be longer than `58 - len(namespace)` | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace of Docker Swarm | `string` | `null` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | The networks attached | `list(string)` | `[]` | no |
| <a name="input_reservation"></a> [reservation](#input\_reservation) | The resource reservation of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_service_port"></a> [service\_port](#input\_service\_port) | The internal and external service port for Prometheus | `number` | `9090` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
