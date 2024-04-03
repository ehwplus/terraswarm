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

  name      = coalesce(var.name, "opentelemetry")
  namespace = coalesce(var.namespace, "o11y")
  image_tag = coalesce(var.image_tag, "0.90.1")

  image = coalesce(var.image, "otel/opentelemetry-collector")

  # From the docs (https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/service#command):
  #   The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also
  #   passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service.
  #
  # So in accordance with https://github.com/open-telemetry/opentelemetry-collector-releases/blob/main/distributions/otelcol/Dockerfile
  # we have to include the entrypoint from the Dockerfile in the service command array.
  command               = ["/otelcol", "--config", "${local.this_config_file_name}"]
  this_config_file_name = "/etc/otelcol/config.yaml"
}

module "opentelemetry_docker_service" {
  source      = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"
  name        = local.name
  namespace   = local.namespace
  image       = local.image
  image_tag   = local.image_tag
  command     = local.command
  mounts      = local.mounts
  networks    = compact(flatten(var.networks))
  mode        = { global = true } # use otel as a node log agent as well
  limit       = var.limit
  reservation = var.reservation
  auth        = var.auth
  ports = [
    {
      target_port  = var.service_port,
      name         = "grpc",
      protocol     = "tcp",
      publish_mode = "ingress"
    }
  ]
  configs = [
    {
      config_data = var.config
      file_name   = local.this_config_file_name
      file_mode   = 0700
    }
  ]
}
