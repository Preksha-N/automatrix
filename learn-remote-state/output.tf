output "instance_id" {
  value = aws_instance.app_server.id
}

output "key-id" {
  value = aws_key_pair.example.id
}
output "elastic-ip" {
  value = aws_eip.fedora-eip.public_ip
}
output "ebs-volume-id" {
  value = aws_ebs_volume.example.id
}

