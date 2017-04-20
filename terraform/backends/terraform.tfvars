terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }
}

state_bucket = "grk-tfstates"

vpc_state_key = "vpc"

region = "eu-west-1"

backend_name = "demo"

ddb_name = "demo-int-attendees"

ddb_read_cap = "100"

ddb_write_cap = "100"
