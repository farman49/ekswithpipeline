output "pub_subnet_1" {
  value = aws_subnet.public-1.id
}
output "pub_subnet_2" {
  value = aws_subnet.public-2.id
}
output "security_group" {
  value = aws_security_group.allow_tls.id
}