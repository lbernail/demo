terragrunt = {
  remote_state = {
    backend = "s3"

    config = {
      encrypt = "true"
      bucket  = "grk-tfstates"
      key     = "${path_relative_to_include()}"
      region  = "eu-west-1"
    }
  }
}
