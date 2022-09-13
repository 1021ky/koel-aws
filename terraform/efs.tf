resource "aws_efs_file_system" "koel-efs" {
  creation_token = "koel-product"
  encrypted      = true
  depends_on = [
    aws_network_interface.koel-public-network-interface
  ]
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
  tags = {
    project  = "koel-efs"
    createby = "terraform"
  }
}

resource "aws_efs_mount_target" "efs-mount-target-2a" {
  depends_on = [
    aws_network_interface.koel-public-network-interface
  ]
  file_system_id  = aws_efs_file_system.koel-efs.id
  subnet_id       = aws_subnet.ecs-public-subnet1.id
  security_groups = [aws_security_group.koel-sg.id]

}

resource "aws_efs_mount_target" "efs-mount-target-2c" {
  depends_on = [
    aws_network_interface.koel-public-network-interface
  ]

  file_system_id  = aws_efs_file_system.koel-efs.id
  subnet_id       = aws_subnet.ecs-public-subnet2.id
  security_groups = [aws_security_group.koel-sg.id]
}

resource "aws_efs_access_point" "music" {
  file_system_id = aws_efs_file_system.koel-efs.id

  posix_user {
    gid = 65534
    uid = 65534
  }

  root_directory {
    path = "/music"
    creation_info {
      owner_gid   = 65534
      owner_uid   = 65534
      permissions = 0766
    }
  }

  tags = {
    Name     = "music"
    createby = "terraform"
  }
}

resource "aws_efs_access_point" "search_index" {
  file_system_id = aws_efs_file_system.koel-efs.id

  posix_user {
    gid = 65534
    uid = 65534
  }

  root_directory {
    path = "/search_index"
    creation_info {
      owner_gid   = 65534
      owner_uid   = 65534
      permissions = 0766
    }
  }

  tags = {
    Name     = "search_index"
    createby = "terraform"
  }
}

resource "aws_efs_access_point" "covers" {
  file_system_id = aws_efs_file_system.koel-efs.id

  posix_user {
    gid = 65534
    uid = 65534
  }

  root_directory {
    path = "/covers"
    creation_info {
      owner_gid   = 65534
      owner_uid   = 65534
      permissions = 0766
    }
  }

  tags = {
    Name     = "covers"
    createby = "terraform"
  }
}
