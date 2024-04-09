# Loki Module

Run Loki server to collect logs

## Usage

```hcl
# Setup Loki
module "loki" {
  source = "github.com/StarPortal/terraform-swarm-stack//modules/loki"

  name = "loki"
  config = templatefile("${path.root}/loki.yml", {})
}
```

Add `loki.yml` to configure service

> Only `inmemory` can work correctly for now

```yml
---
auth_enabled: false
server:
  http_listen_port: 3100

schema_config:
  configs:
    - from: 2021-08-01
      store: boltdb-shipper
      object_store: s3
      schema: v11
      index:
        prefix: index_
        period: 24h

common:
  path_prefix: /loki
  replication_factor: 1
  storage:
    s3:
      endpoint: minio
      bucketnames: loki-data
      access_key_id: loki
      secret_access_key: loki
      s3forcepathstyle: true
  ring:
    kvstore:
      store: inmemory

ruler:
  storage:
    s3:
      bucketnames: loki-ruler
```

## Module documentation

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
| <a name="input_config"></a> [config](#input\_config) | The static config file for Loki | `string` | `null` | no |
| <a name="input_constraints"></a> [constraints](#input\_constraints) | The container placement constraints | `list(string)` | `[]` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The image tag of Loki to specify version | `string` | `"latest"` | no |
| <a name="input_limit"></a> [limit](#input\_limit) | The resources limit of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The loki service name | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace of Docker Swarm | `string` | `null` | no |
| <a name="input_networks"></a> [networks](#input\_networks) | The networks attached | `list(string)` | `[]` | no |
| <a name="input_reservation"></a> [reservation](#input\_reservation) | The resource reservation of service, memory unit is MB | <pre>object({<br>    cores  = optional(number)<br>    memory = optional(number)<br>  })</pre> | `null` | no |
| <a name="input_service_port"></a> [service\_port](#input\_service\_port) | The internal and external service port for Loki | `number` | `3100` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_port"></a> [service\_port](#output\_service\_port) | The target port of the container running in the service |
| <a name="output_this"></a> [this](#output\_this) | The Loki service |
<!-- END_TF_DOCS -->
