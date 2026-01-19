#!/bin/bash

# Update the system
yum update -y

# Configure ECS agent
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
echo ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true >> /etc/ecs/ecs.config
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config

# Enable ECS task draining on instance termination
echo ECS_ENABLE_SPOT_INSTANCE_DRAINING=true >> /etc/ecs/ecs.config

# Configure CloudWatch agent for better monitoring
echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config

# Install SSM agent if not already present (for Session Manager)
if ! rpm -q amazon-ssm-agent; then
    yum install -y amazon-ssm-agent
fi

# Start and enable SSM agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Start ECS agent
systemctl enable ecs
systemctl start ecs

# Configure log rotation for Docker containers
cat > /etc/logrotate.d/docker-containers << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 5
    daily
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /bin/kill -USR1 `cat /var/run/docker.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
EOF

# Install CloudWatch Logs agent
yum install -y awslogs

# Configure CloudWatch Logs
cat > /etc/awslogs/awslogs.conf << 'EOF'
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = /aws/ec2/ecs/${cluster_name}/var/log/dmesg
log_stream_name = {instance_id}

[/var/log/messages]
file = /var/log/messages
log_group_name = /aws/ec2/ecs/${cluster_name}/var/log/messages
log_stream_name = {instance_id}
datetime_format = %b %d %H:%M:%S

[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log
log_group_name = /aws/ec2/ecs/${cluster_name}/var/log/ecs/ecs-init.log
log_stream_name = {instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ

[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log
log_group_name = /aws/ec2/ecs/${cluster_name}/var/log/ecs/ecs-agent.log
log_stream_name = {instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
EOF

region=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
sed -i "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

systemctl enable awslogsd
systemctl start awslogsd
