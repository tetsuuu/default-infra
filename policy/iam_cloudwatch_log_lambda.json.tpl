{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaCreateLog",
      "Action": [
                "logs:CreateLogGroup"
      ],
      "Effect": "Allow",
      "Resource": "${logs_arn}:*"
    },
    {
      "Sid": "LambdaPutLog",
      "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "${log_group}"
    }
  ]
}
