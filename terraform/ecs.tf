resource "aws_ecs_cluster" "koel-ecs-cluster" {
  name = "koel-ecs-cluster"
  tags = {
    Name     = "koel-ecs-cluster"
    createby = "terraform"
  }
}

# output "koel-ecs-cluster-endpoint" {
#   value = aws_ecs_cluster.koel-ecs-cluster.
# }

resource "aws_ecs_service" "koel-ecs-service" {
  # depends_on      = [aws_lb_listener_rule.koel-lb-listener-rule]
  name                   = "koel-ecs-service"
  cluster                = aws_ecs_cluster.koel-ecs-cluster.name
  task_definition        = aws_ecs_task_definition.koel-ecs-task.arn
  enable_execute_command = true
  desired_count          = 1
  launch_type            = "FARGATE"
  # iam_role               = aws_iam_role.koel-service-role.arn
  network_configuration {
    assign_public_ip = true
    # タスクの起動を許可するサブネット
    subnets = [
      aws_subnet.ecs-public-subnet1.id,
      aws_subnet.ecs-public-subnet2.id,
    ]
    # タスクに紐付けるセキュリティグループ
    security_groups = [
      aws_security_group.koel-sg.id
    ]
  }

  # ECSタスクの起動後に紐付けるELBターゲットグループ
  # load_balancer {
  #   target_group_arn = aws_lb_target_group.koel-lb-target-group.arn
  #   container_name   = "nginx"
  #   container_port   = "80"
  # }

  # デプロイ毎にタスク定義が更新されるため、リソース初回作成時を除き変更を無視
  # ref https://dev.classmethod.jp/articles/terraform-ecs-fargate-apache-run/
  # lifecycle {
  #   ignore_changes = [task_definition]
  # }
}

resource "aws_ecs_task_definition" "koel-ecs-task" {
  depends_on = [
    aws_efs_file_system.koel-efs
  ]
  family = "koel-ecs-task"

  requires_compatibilities = ["FARGATE"]
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  cpu    = "256" # =0.25vCPU
  memory = "512" # =0.5GB

  network_mode       = "awsvpc"
  task_role_arn      = aws_iam_role.koel-ecs-task-role.arn
  execution_role_arn = aws_iam_role.koel-ecs-exection-role.arn

  # ref https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_definition_parameters.html
  container_definitions = jsonencode(
    [
      {
        name = "my-koel",
        # docker build -t docker build -t my-koel:0.1 .
        # docker tag my-koel:0.1 682816909333.dkr.ecr.us-west-2.amazonaws.com/koel-ecr-repo:latest
        # docker push 682816909333.dkr.ecr.us-west-2.amazonaws.com/koel-ecr-repo:latest
        image = "682816909333.dkr.ecr.us-west-2.amazonaws.com/koel-ecr-repo:latest",
        portMappings = [
          {
            containerPort = 80
            hostPort      = 80
            protocol      = "tcp"
          }
        ],
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-region        = "us-west-2",
            awslogs-stream-prefix = "koel-app",
            awslogs-group         = "/ecs/koel/app"
          }
        },
        environment = [
          {
            "name" : "DB_CONNECTION",
            "value" : "mysql"
          },
          {
            "name" : "DB_DATABASE",
            "value" : "koel"
          },
          {
            "name" : "DB_HOST",
            "value" : aws_rds_cluster.koel-rds-cluster.endpoint
          },
          {
            "name" : "DB_USERNAME",
            "value" : "koel"
          },
          {
            "name" : "DB_PASSWORD",
            "value" : "koelpassw0rd"
          },
          {
            "name" : "APP_KEY",
            "value" : "base64:u3yl70bhw/5wX0xvd3Y0h1ZHPIjS9q5ZNqfH9waTaac="
          },
        ],
        "mountPoints" : [
          {
            "sourceVolume" : "music",
            "containerPath" : "/music",
          },
          {
            "sourceVolume" : "covers",
            "containerPath" : "/var/www/html/public/img/covers",
          },
          {
            "sourceVolume" : "search_index",
            "containerPath" : "/var/www/html/storage/search-indexes",
          }
        ]
      }
    ]
  )
  volume {
    name = "music"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.koel-efs.id
      transit_encryption = "ENABLED"
      # transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.music.id
      }
    }
  }
  volume {
    name = "covers"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.koel-efs.id
      transit_encryption = "ENABLED"
      # transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.covers.id
      }
    }
  }
  volume {
    name = "search_index"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.koel-efs.id
      transit_encryption = "ENABLED"
      # transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.search_index.id
      }
    }
  }
  tags = {
    Name     = "koel-ecs-task"
    createby = "terraform"
  }
}

resource "aws_iam_role" "koel-ecs-task-role" {
  name               = "koel-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.koel-ecs-task-policy-document.json

  inline_policy {
    name   = "ecs-exec"
    policy = data.aws_iam_policy_document.ecs-exec.json
  }
}

data "aws_iam_policy_document" "koel-ecs-task-policy-document" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "amazon-ecs-task-execution-role-policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "ecs-exec-policy" {
  name   = "ecs-exec-policy"
  policy = data.aws_iam_policy_document.ecs-exec.json
}

data "aws_iam_policy_document" "ecs-exec" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role" "koel-ecs-exection-role" {
  name               = "koel-ecs-exection-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-task-ecs-task-exec-role-policy-document.json

  inline_policy {
    name   = "ecr-access-policy"
    policy = data.aws_iam_policy_document.ecr-access-policy.json
  }
}

resource "aws_iam_role_policy_attachment" "koel-ecs-exection-policy-attachment" {
  role       = aws_iam_role.koel-ecs-exection-role.name
  policy_arn = aws_iam_policy.ecs-exec-policy.arn
}

data "aws_iam_policy_document" "ecs-task-ecs-task-exec-role-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecr-access-policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
}
