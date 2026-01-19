#!/bin/bash

echo 'starts initializing user-data script'

mkdir -p /etc/ecs/
touch /etc/ecs/ecs.config

# Update the system
yum update -y

# Configure ECS agent
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config

# Enable ECS task draining on instance termination
echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true" >> /etc/ecs/ecs.config

echo 'install ssm agent'
# Install SSM agent (for Session Manager)
if ! rpm -q amazon-ssm-agent >/dev/null 2>&1; then
  yum install -y amazon-ssm-agent
fiecho 'installed ssm agent'


# Start and enable SSM agent
echo 'enable ssm agent'
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
echo 'enable ssm agent'

# Start ECS agent
systemctl enable ecs
systemctl start ecs

# Verify ECS agent is running and registered
echo "Waiting for ECS agent to start and register with cluster..."
sleep 30
systemctl status ecs

echo 'copy logs'
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
echo 'copy logs'

echo 'get instance id and region'
# Get EC2 instance metadata using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
instance_id=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
region=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
echo 'got instance id and region'

echo "instance_id is $instance_id"

sed -i "s/region = us-east-1/region = $region/g" /etc/awslogs/awscli.conf

systemctl enable awslogsd
systemctl start awslogsd

echo 'successfully initialized user-data script for $instance_id'
