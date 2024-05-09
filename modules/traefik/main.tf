
locals {
  certificate = {
    # set source to traefik_docker_volume if driver is not local
    source = coalesce(var.traefik_certificate.source, module.traefik_docker_volume.this.name)
    type   = coalesce(var.traefik_certificate.type, "volume")
  }

  mounts = toset(concat([
    {
      target         = "/var/run/docker.sock"
      source         = "/var/run/docker.sock"
      type           = "bind"
      read_only      = true
      tmpfs_options  = {}
      volume_options = {}
    },
    {
      target        = var.traefik_certificate.target
      source        = local.certificate.source
      type          = local.certificate.type
      read_only     = false
      tmpfs_options = {}
      volume_options = {
        driver_name    = var.traefik_certificate.driver_name
        driver_options = var.traefik_certificate.driver_options
      }
    },
    {
      target         = "/etc/traefik"
      source         = module.traefik_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = {}
      volume_options = {}
    }
    # {
    #   target = "/etc/certificates"
    #   source = local.certificate.source
    #   type   = local.certificate.type
    #   volume_options = {
    #     driver_options = var.certificate.driver
    #   }
    # }
    ],
    tolist(var.mounts)
  ))

  ports = flatten(concat(
    [
      {
        target_port  = 80,
        name         = "http",
        protocol     = "tcp",
        publish_mode = "ingress"
      },
      {
        target_port  = 443,
        name         = "https",
        protocol     = "tcp",
        publish_mode = "ingress"
      },
    ],
    var.ports
  ))

  args = concat(["--ping=true"], var.args)

  healthcheck = merge({ test = ["traefik", "healthcheck"] }, var.healthcheck)

  name      = coalesce(var.name, "traefik")
  namespace = coalesce(var.namespace, "gateway")
  image     = coalesce(var.custom_image, "traefik")
  image_tag = coalesce(var.image_tag, "v3.0")
}

// trunk-ignore-all(tflint/terraform_module_pinned_source)

module "traefik_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "traefik_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  mounts          = local.mounts
  ports           = local.ports
  args            = local.args
  healthcheck     = local.healthcheck
  auth            = var.auth # container registry auth for private traefik images
  configs         = [{ config_data = var.traefik_config, file_name = "/etc/traefik/traefik.yaml", file_mode = 0740 }]
  constraints     = var.constraints
  env             = var.env
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map
  secrets         = var.secrets
}
