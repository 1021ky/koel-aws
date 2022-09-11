resource "aws_cloudwatch_log_group" "koel-app-log-group" {
  name              = "/ecs/koel/app"
  retention_in_days = 7
}
