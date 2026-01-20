#!/bin/bash
set -euo pipefail

# Log user-data output (helps debugging)
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "starts initializing user-data script"

mkdir -p /etc/ecs
touch /etc/ecs/ecs.config

# Update the system (optional; can slow boot)
yum update -y

# Configure ECS agent
cat >/etc/ecs/ecs.config <<EOF
ECS_CLUSTER=${cluster_name}
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
ECS_ENABLE_CONTAINER_METADATA=true
ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
EOF

echo "install ssm agent"
if ! rpm -q amazon-ssm-agent >/dev/null 2>&1; then
  yum install -y amazon-ssm-agent
  echo "installed ssm agent"
else
  echo "ssm agent already installed"
fi

echo "enable/start ssm agent"
systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

# Start ECS agent (works on ECS-optimized AMI)
echo "enable/start ecs agent"
systemctl enable ecs
systemctl start ecs --no-block

echo "ecs status:"
systemctl --no-pager status ecs || true

echo "copy logs"
# Configure log rotation for Docker containers
cat > /etc/logrotate.d/docker-containers <<'EOF'
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

echo "install cloudwatch logs agent"
yum install -y awslogs

# Create awslogs config (SOC2-friendly: per-instance streamseams by instance-id)
cat >/etc/awslogs/awslogs.conf <<EOF
[general]
state_file = /var/lib/awslogs/agent-state

[/var/log/messages]
file = /var/log/messages
log_group_name = /ecs/ec2/system
log_stream_name = {instance_id}/messages
datetime_format = %b %d %H:%M:%S

[/var/log/cloud-init-output.log]
file = /var/log/cloud-init-output.log
log_group_name = /ecs/ec2/cloud-init
log_stream_name = {instance_id}/cloud-init
EOF

# Ensure region in awscli conf
if [ -n "$${region:-}" ] && [ -f /etc/awslogs/awscli.conf ]; then
  sed -i "s/^region = .*/region = $region/g" /etc/awslogs/awscli.conf || true
fi

systemctl enable awslogsd
systemctl restart awslogsd

echo "get instance id and region"
TOKEN=$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)

instance_id=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id || true)

region=$(curl -sS -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region || true)

echo "instance_id is $${instance_id:-unknown}"
echo "region is $${region:-unknown}"

# Update awslogs region if config exists
if [ -n "$${region:-}" ] && [ -f /etc/awslogs/awscli.conf ]; then
  sed -i "s/^region = .*/region = $region/g" /etc/awslogs/awscli.conf || true
fi

systemctl enable awslogsd
systemctl restart awslogsd

echo "successfully initialized user-data script for $${instance_id:-unknown}"