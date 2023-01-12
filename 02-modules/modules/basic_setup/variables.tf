variable "environment" {
  description = "Environment name, can be dev or prod"
  type        = string
  validation {
    condition     = contains(["prod", "dev"], var.environment) # conains is a terrafomr function (see more about functions in the docs)
    error_message = "Valid values for environment are only 'dev' or 'prod"
  }
}
