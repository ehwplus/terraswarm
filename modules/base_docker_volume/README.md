# base_docker_volume

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_docker"></a> [docker](#requirement\_docker) | 3.0.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_docker"></a> [docker](#provider\_docker) | 3.0.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [docker_volume.this](https://registry.terraform.io/providers/kreuzwerker/docker/3.0.2/docs/resources/volume) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_driver"></a> [driver](#input\_driver) | Driver type for the volume. Defaults to 'overlay2'. | `string` | `"overlay2"` | no |
| <a name="input_driver_options"></a> [driver\_options](#input\_driver\_options) | Options specific to the driver. | `map(string)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | The docker volume name | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace of Docker Swarm | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_this"></a> [this](#output\_this) | Outputs this docker volume resource |
<!-- END_TF_DOCS -->
