resource "aws_ecr_repository" "koel-ecr-repo" {
  name                 = "koel-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
