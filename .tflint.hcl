plugin "terraform" {
  enabled = true
  version = "0.6.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"

  preset = "recommended"
}

rule "terraform_module_pinned_source" {
  enabled          = false
  style            = "flexible"
  default_branches = ["main"]
}
