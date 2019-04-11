{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PutDataLake",
      "Effect": "Allow",
      "Action":[
        "s3:Put*",
        "s3:Get*",
        "s3:List*"
      ],
      "Resource":[
        "${audit_bucekt}",
        "${audit_bucekt}/*"
      ]
    }
  ]
}
