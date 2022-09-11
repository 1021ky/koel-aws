# resource "aws_lb" "koel-lb" {
#   load_balancer_type = "application"
#   name               = "koel-lb"
#   # タスクの起動を許可するサブネット
#   subnets = [
#     aws_subnet.ecs-public-subnet1.id,
#     aws_subnet.ecs-public-subnet2.id,
#   ]
#   # タスクに紐付けるセキュリティグループ
#   security_groups = [
#     aws_security_group.koel-sg.id
#   ]
#   tags = {
#     Name      = "koel-lb"
#     CreatedBy = "terraform"
#   }
# }

# resource "aws_lb_listener" "koel-lb-listener" {
#   load_balancer_arn = aws_lb.koel-lb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"

#   certificate_arn = aws_acm_certificate.koel-acm-certificate.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.koel-lb-target-group.arn
#   }
#   tags = {
#     Name      = "koel-lb-listener"
#     CreatedBy = "terraform"
#   }
# }

# resource "aws_lb_target_group" "koel-lb-target-group" {
#   name = "koel-lb-target-group"

#   vpc_id = aws_vpc.koel-public-vpc.id

#   # 振り分け先
#   port        = 80
#   protocol    = "HTTP"
#   target_type = "ip"

#   health_check {
#     port = 80
#     path = "/"
#   }
#   tags = {
#     Name      = "koel-lb-target-group"
#     CreatedBy = "terraform"
#   }
# }

# resource "aws_lb_listener_rule" "koel-lb-listener-rule" {
#   listener_arn = aws_lb_listener.koel-lb-listener.arn

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.koel-lb-target-group.arn
#   }

#   condition {
#     path_pattern {
#       values = ["*"]
#     }
#   }
#   tags = {
#     Name      = "koel-lb-listener-rule"
#     CreatedBy = "terraform"
#   }
# }
