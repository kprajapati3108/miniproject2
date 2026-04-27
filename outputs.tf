output "template_instance_public_ip" {
  value = aws_instance.template_instance.public_ip
}

output "template_ami_id" {
  value = aws_ami_from_instance.template_ami.id
}

output "db_instance_identifier" {
  value = aws_db_instance.db.id
}

output "db_snapshot_identifier" {
  value = aws_db_snapshot.db_snapshot.id
}

output "asg_name" {
  value = aws_autoscaling_group.asg.name
}
