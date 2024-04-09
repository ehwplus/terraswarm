
locals {
  mounts = setunion([
    {
      target         = "/etc/letsencrypt"
      source         = module.certbot_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = null
      volume_options = null
    },
    {
      target         = "/var/lib/letsencrypt"
      source         = module.certbot_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = null
      volume_options = null
    }
    ],
    var.mounts
  )

  ports = flatten(concat(
    var.certbot_standalone ? [
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
    ] : [],
    var.ports
  ))

  name      = coalesce(var.name, "certbot")
  namespace = coalesce(var.namespace, "gateway")
  image     = coalesce(var.custom_image, "certbot/certbot")
  image_tag = coalesce(var.image_tag, "v2.10.0")

}

module "certbot_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "certbot_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  mounts          = local.mounts
  ports           = local.ports
  args            = coalesce(var.args, ["certonly"])
  auth            = var.auth # container registry auth for private certbot images
  constraints     = var.constraints
  env             = var.env
  healthcheck     = var.healthcheck
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
