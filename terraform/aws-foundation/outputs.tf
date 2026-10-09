output "ec2_ip" {
  description = "IP de l'EC2"
  value       = aws_instance.ec2.public_ip
}