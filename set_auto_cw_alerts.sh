#!/bin/bash
AlarmPrefix=”autoCWalert”
region=$(curl http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)
InstanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
AMIID=$(curl http://169.254.169.254/latest/meta-data/ami-id 2>/dev/null)
EC2_NAME=$(aws ec2 describe-tags — region $region — filters “Name=resource-id,Values=$InstanceID” “Name=key,Values=Name” — output text | cut -f5)
InstanceType=$(curl http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null)
#device=$(df -h / | awk ‘{print$1}’ | sed ‘s/dev//’ | sed ‘s/^.//’ | sed ‘s/^.//’ | tail -1)
device=$(lsblk | egrep -i “part /” | awk ‘{print$1}’ | sed ‘s/├─//’ | head -1 | sed ‘s/└─//’)
fstype=$(df -hT / | awk ‘{print$2}’ | tail -1)
AutoScalingGroupName=$(aws autoscaling — region $region describe-auto-scaling-instances — instance-ids=”$InstanceID” | grep “AutoScalingGroupName” | sed ‘s/”AutoScalingGroupName”: “//g’ | sed ‘s/ //’ | rev | cut -c3- | rev)
AlarmPrefix=$EC2_NAME
# CPU Utilization
aws cloudwatch — region $region put-metric-alarm — alarm-name ${AlarmPrefix}_CPUUtilization_$InstanceID — alarm-description “Alarm when CPU exceeds 70 percent” — metric-name CPUUtilization — namespace AWS/EC2 — statistic Average — period 300 — threshold 70 — comparison-operator GreaterThanThreshold — dimensions “Name=InstanceId,Value=$InstanceID” — evaluation-periods 2 — alarm-actions arn:aws:sns:$region:891377187211:CloudwatchMonitoring — unit Percent
# Status check Fail
if [ -z “$AutoScalingGroupName” ];
then
aws cloudwatch — region $region put-metric-alarm — alarm-name ${AlarmPrefix}_StatusCheckFailed_$InstanceID — alarm-description “Alert on ec2 status check fail” — metric-name StatusCheckFailed — namespace AWS/EC2 — statistic Average — period 300 — threshold 0 — comparison-operator GreaterThanThreshold — dimensions “Name=InstanceId,Value=$InstanceID” — evaluation-periods 1 — alarm-actions arn:aws:sns:$region:891377187211:CloudwatchMonitoring — treat-missing-data breaching
else
aws cloudwatch — region $region put-metric-alarm — alarm-name ${AlarmPrefix}_StatusCheckFailed_$InstanceID — alarm-description “Alert on ec2 status check fail” — metric-name StatusCheckFailed — namespace AWS/EC2 — statistic Average — period 300 — threshold 0 — comparison-operator GreaterThanThreshold — dimensions “Name=InstanceId,Value=$InstanceID” — evaluation-periods 1 — alarm-actions arn:aws:sns:$region:891377187211:CloudwatchMonitoring
fi
# Disk /
if [ -z “$AutoScalingGroupName” ];
then
aws cloudwatch — region $region put-metric-alarm — alarm-name ${AlarmPrefix}_disk_used_percent_root_$InstanceID — alarm-description “Alert on Disk usage 80” — metric-name disk_used_percent — namespace CWAgent — statistic Average — period 300 — threshold 80 — comparison-operator GreaterThanThreshold — dimensions “Name=path,Value=/” “Name=InstanceId,Value=$InstanceID” “Name=ImageId,Value=$AMIID” “Name=InstanceType,Value=$InstanceType” “Name=device,Value=$device” “Name=fstype,Value=$fstype” — evaluation-periods 2 — alarm-actions arn:aws:sns:$region:891377187211:CloudwatchMonitoring — unit Percent
else
aws cloudwatch — region $region put-metric-alarm — alarm-name ${AlarmPrefix}_disk_used_percent_root_$InstanceID — alarm-description “Alert on Disk usage 80” — metric-name disk_used_percent — namespace CWAgent — statistic Average — period 300 — threshold 80 — comparison-operator GreaterThanThreshold — dimensions “Name=path,Value=/” “Name=InstanceId,Value=$InstanceID” “Name=AutoScalingGroupName,Value=$AutoScalingGroupName” “Name=ImageId,Value=$AMIID” “Name=InstanceType,Value=$InstanceType” “Name=device,Value=$device” “Name=fstype,Value=$fstype” — evaluation-periods 2 — alarm-actions arn:aws:sns:$region:891377187211:CloudwatchMonitoring — unit Percent
fi
# Memory Utilization
if [ -z “$AutoScalingGroupName” ];
then
aws cloudwatch — region $region put-metric-alarm — alarm-name ${AlarmPrefix}_mem_used_percent_$InstanceID — alarm-description “Alert on Memory usage 80” — metric-name mem_used_percent — namespace CWAgent — statistic Average — period 300 — threshold 80 — comparison-operator GreaterThanThreshold — dimensions “Name=InstanceId,Value=$InstanceID” “Name=ImageId,Value=$AMIID” “Name=InstanceType,Value=$InstanceType” — evaluation-periods 1 — alarm-actions arn:aws:sns:$region:891377187211:CloudwatchMonitoring — unit Percent
else
aws cloudwatch — region $region put-metric-alarm — alarm-name ${AlarmPrefix}_mem_used_percent_$InstanceID — alarm-description “Alert on Memory usage 80” — metric-name mem_used_percent — namespace CWAgent — statistic Average — period 300 — threshold 80 — comparison-operator GreaterThanThreshold — dimensions “Name=InstanceId,Value=$InstanceID” “Name=AutoScalingGroupName,Value=$AutoScalingGroupName” “Name=ImageId,Value=$AMIID” “Name=InstanceType,Value=$InstanceType” — evaluation-periods 1 — alarm-actions arn:aws:sns:$region:891377187211:CloudwatchMonitoring — unit Percent
fi
#END Of Script
