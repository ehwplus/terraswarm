locals {
  name      = coalesce(var.name, "grafana")
  namespace = coalesce(var.namespace, "dashboard")
  image     = coalesce(var.custom_image, "grafana/grafana")
  image_tag = coalesce(var.image_tag, "9.5.14")

  this_config_file_name = "/etc/grafana/grafana.ini"
  grafana_mount_path    = "/var/lib/grafana"
  grafana_internal_port = 3000

  configs = var.grafana_config == null ? [] : [
    {
      config_data = var.grafana_config
      file_name   = local.this_config_file_name
      file_mode   = 0444
    }
  ]

  env = merge({
    "GF_AUTH_DISABLE_LOGIN_FORM" = true
    "GF_AUTH_ANONYMOUS_ENABLED"  = true
    "GF_AUTH_ANONYMOUS_ORG_ROLE" = "Admin"
    "GF_INSTALL_PLUGINS"         = "grafana-piechart-panel"
  }, var.env)

  # healthcheck = coalesce(
  #   var.healthcheck, {
  #     test         = ["CMD", "wget", "http://localhost:${local.grafana_internal_port}/api/health"]
  #     interval     = "10s"
  #     timeout      = "15s"
  #     retries      = 10
  #     start_period = "40s"
  #   }
  # )
  healthcheck = merge({ test = ["curl", "http://localhost:${local.grafana_internal_port}/api/health"] }, var.healthcheck)

  mounts = [{
    target         = local.grafana_mount_path
    source         = module.grafana_docker_volume.this.name
    type           = "volume"
    read_only      = false
    tmpfs_options  = {}
    volume_options = {}
  }]

  ports = [
    {
      target_port    = var.grafana_service_port
      name           = "web-ui"
      protocol       = "tcp"
      publish_mode   = "ingress"
      published_port = local.grafana_internal_port
    }
  ]
}

module "grafana_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "grafana_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  configs         = local.configs
  env             = local.env
  mounts          = local.mounts
  ports           = local.ports
  healthcheck     = local.healthcheck
  auth            = var.auth # container registry auth for private prometheus images
  constraints     = var.constraints
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map
  secrets         = var.secrets

  depends_on = [module.grafana_docker_volume]
}
