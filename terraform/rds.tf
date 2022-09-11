
resource "aws_rds_cluster" "koel-rds-cluster" {
  cluster_identifier = "koel-rds-cluster"
  engine             = "aurora-mysql"
  # engine_version                  = "2.07.1"
  master_username                 = "koel"
  master_password                 = "koelpassw0rd"
  port                            = 3306
  database_name                   = "koel"
  vpc_security_group_ids          = [aws_security_group.koel-rds-sg.id]
  db_subnet_group_name            = aws_db_subnet_group.koel-db-subnet-group.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.koel-rds-cluster-parameter-group.name
  availability_zones              = ["us-west-2a", "us-west-2b"]
  skip_final_snapshot             = true
  apply_immediately               = true

  engine_mode = "serverless"

  scaling_configuration {
    //接続がない場合に、一時停止する
    auto_pause = true
    //一時停止するまでの時間(秒)
    seconds_until_auto_pause = 300
    //スケール可能なキャパシティーユニットの最大値
    max_capacity = 2
    //キャパシティーユニットの最小値
    min_capacity = 1
    //タイムアウト時に強制的にスケーリング
    timeout_action = "ForceApplyCapacityChange"
  }
  tags = {
    Name      = "koel-rds-cluster"
    CreatedBy = "terraform"
  }
  lifecycle {
    ignore_changes = [availability_zones]
  }
}

output "rds_endpoint" {
  value = aws_rds_cluster.koel-rds-cluster.endpoint
}

resource "aws_db_subnet_group" "koel-db-subnet-group" {
  name       = "koel-db-subnet-group"
  subnet_ids = toset([aws_subnet.koel-rds-subnet1.id, aws_subnet.koel-rds-subnet2.id])

  tags = {
    Name      = "koel-db-subnet-group"
    CreatedBy = "terraform"
  }
}

resource "aws_rds_cluster_parameter_group" "koel-rds-cluster-parameter-group" {
  name   = "koel-rds-cluster-parameter-group"
  family = "aurora-mysql5.7"
  tags = {
    Name      = "koel-rds-cluster-parameter-group"
    CreatedBy = "terraform"
  }
}

resource "aws_db_parameter_group" "koel-db-parameter-group" {
  name   = "koel-db-parameter-group"
  family = "aurora-mysql5.7"

  tags = {
    Name      = "koel-db-parameter-group"
    CreatedBy = "terraform"
  }
}
