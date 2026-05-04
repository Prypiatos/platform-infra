output "control_plane_public_ip" {
  description = "Public IP address currently assigned to the control-plane instance."
  value       = aws_instance.nodes["control-plane"].public_ip
}

output "control_plane_elastic_ip" {
  description = "Elastic IP attached to the control-plane instance. This is the stable address you should use."
  value       = aws_eip.control_plane.public_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of the worker nodes."
  value = {
    worker_1 = aws_instance.nodes["worker-1"].private_ip
    worker_2 = aws_instance.nodes["worker-2"].private_ip
  }
}

output "ssh_commands" {
  description = "Example SSH commands for connecting to each node. Replace /path/to/your-key.pem with your private key path."
  value = {
    control_plane = "ssh -i /path/to/your-key.pem ubuntu@${aws_eip.control_plane.public_ip}"
    worker_1      = "ssh -i /path/to/your-key.pem ubuntu@${aws_instance.nodes["worker-1"].public_ip}"
    worker_2      = "ssh -i /path/to/your-key.pem ubuntu@${aws_instance.nodes["worker-2"].public_ip}"
  }
}
