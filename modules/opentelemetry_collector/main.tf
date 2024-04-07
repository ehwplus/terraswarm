locals {
  mounts = [
    {
      target    = "/var/run/docker.sock"
      source    = "/var/run/docker.sock"
      type      = "bind"
      read_only = true
    },
    {
      target    = "/var/lib/docker/containers"
      source    = "/var/lib/docker/containers"
      type      = "bind"
      read_only = true
    }
  ]

  configs = [
    {
      config_data = var.config
      file_name   = local.this_config_file_name
      file_mode   = 0700
    }
  ]

  ports = flatten(concat(
    [
      {
        target_port  = var.service_port,
        name         = "grpc",
        protocol     = "tcp",
        publish_mode = "ingress"
      }
    ],
    var.ports
  ))

  name      = coalesce(var.name, "opentelemetry")
  namespace = coalesce(var.namespace, "o11y")
  image     = coalesce(var.custom_image, "otel/opentelemetry-collector")
  image_tag = coalesce(var.image_tag, "0.90.1")

  # From the docs (https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/service#command):
  #   The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also
  #   passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service.
  #
  # So in accordance with https://github.com/open-telemetry/opentelemetry-collector-releases/blob/main/distributions/otelcol/Dockerfile
  # we have to include the entrypoint from the Dockerfile in the service command array.
  command               = ["/otelcol", "--config", local.this_config_file_name]
  this_config_file_name = "/etc/otelcol/config.yaml"
}

module "opentelemetry_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  mounts          = local.mounts
  ports           = local.ports
  command         = local.command
  args            = var.args
  auth            = var.auth # container registry auth for private traefik images
  configs         = local.configs
  constraints     = var.constraints
  env             = var.env
  healthcheck     = var.healthcheck
  labels          = var.labels
  limit           = var.limit
  mode            = { global = true } # use otel as a node log agent as well
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map
  secrets         = var.secrets
}
