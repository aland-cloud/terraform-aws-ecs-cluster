#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting ECS AL2023 initialization"

# ECS configuration
mkdir -p /etc/ecs

cat >/etc/ecs/ecs.config <<EOF
ECS_CLUSTER=${cluster_name}
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
ECS_ENABLE_CONTAINER_METADATA=true
ECS_ENABLE_SPOT_INSTANCE_DRAINING=true
EOF

# SSM Agent
echo "Checking SSM agent"

if ! rpm -q amazon-ssm-agent >/dev/null 2>&1; then
  dnf install -y amazon-ssm-agent
fi

systemctl enable amazon-ssm-agent
systemctl restart amazon-ssm-agent

# Docker log rotation
cat >/etc/logrotate.d/docker-containers <<'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 5
    daily
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /bin/kill -USR1 `cat /var/run/docker.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
EOF

# ECS Agent
echo "Starting ECS agent"

systemctl enable ecs
systemctl start ecs --no-block

# CloudWatch Agent
echo "Installing CloudWatch Agent"

dnf install -y amazon-cloudwatch-agent

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
{
  "logs": {
    "logs_collected": {
      "journald": {
        "collect_list": [
          {
            "log_group_name": "/ecs/ec2/system",
            "log_stream_name": "{instance_id}",
            "priority": "info"
          }
        ]
      },
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/ecs/ec2/cloud-init",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/ecs/ec2/user-data",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

systemctl enable amazon-cloudwatch-agent

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "ECS status:"
systemctl --no-pager status ecs || true

echo "SSM status:"
systemctl --no-pager status amazon-ssm-agent || true

echo "CloudWatch Agent status:"
systemctl --no-pager status amazon-cloudwatch-agent || true

echo "Successfully initialized ECS AL2023 instance"