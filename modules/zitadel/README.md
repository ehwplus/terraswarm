# tempo

used for tracing

## Terminology

Check https://grafana.com/docs/tempo/latest/traces/#terminology for more information.

## Module documentation

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_minio"></a> [minio](#module\_minio) | ../minio | n/a |
| <a name="module_this"></a> [this](#module\_this) | ../base_docker_service | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | The static config file for Tempo | `string` | `null` | no |
| <a name="input_constraints"></a> [constraints](#input\_constraints) | The container placement constraints | `list(string)` | `[]` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The image tag of Tempo to specify version | `string` | `"latest"` | no |
| <a name="input_limit"></a> [limit](#input\_limit) | The resources limit of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The Tempo service name | `string` | `"tempo"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace of Docker Swarm | `string` | `null` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | The networks attached | `list(string)` | `[]` | no |
| <a name="input_reservation"></a> [reservation](#input\_reservation) | The resource reservation of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_service_port"></a> [service\_port](#input\_service\_port) | The internal and external service port for Tempo | `number` | `3200` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_minio"></a> [minio](#output\_minio) | minio blob storage for Tempo. |
| <a name="output_this"></a> [this](#output\_this) | Tempo base docker service module output |
<!-- END_TF_DOCS -->
