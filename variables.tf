variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "item_tag" {
  type        = string
  description = "Main tag value"
}

variable "item_tag_template" {
  type        = string
  description = "Template tag value"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_engine" {
  type        = string
  description = "Database engine"
}

variable "db_engine_version" {
  type        = string
  description = "Database engine version"
}

variable "db_username" {
  type        = string
  description = "RDS username"
}

variable "ami_name" {
  type        = string
  description = "Name for AMI"
}

variable "db_snapshot_identifier" {
  type        = string
  description = "Identifier for DB snapshot"
}
