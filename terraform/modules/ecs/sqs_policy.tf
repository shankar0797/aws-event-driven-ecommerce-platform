# ---------------------------------------------------------
# ECS Task Role - SQS Permission
# ---------------------------------------------------------

resource "aws_iam_role_policy" "task_sqs" {
  name = "${var.cluster_name}-sqs-policy"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = var.sqs_queue_arn
      }
    ]
  })
}


