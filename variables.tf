
variable "stage" {
	default = "dev"
}

variable "resource_name" {
	default = "sum"
}

variable "aws_region" {
  description = "The name of the region"
	default = "eu-central-1"
}

variable "email_endpoint" {
  description = "The email which resoult sent to."
  # change email to your address and accept subscription after first request
  # ---------vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  default = "qi87gr+8k2jvvq2fc474@sharklasers.com" 
}
