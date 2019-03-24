resource "aws_cloudwatch_event_rule" "container_stop_event" {
  count         = "${var.slack_webhook_url != "" ? 1 : 0 }"
  name          = "${var.region}-container-deploy-error-rule"
  description   = "Detect Task deploy error"
  event_pattern = "${file("./event/task_stopped_event.json")}"
}

resource "aws_cloudwatch_event_target" "container_deploy_error_notification" {
  count = "${var.slack_webhook_url != "" ? 1 : 0 }"
  arn   = "${aws_lambda_function.container_deploy_error_notification.arn}"
  rule  = "${aws_cloudwatch_event_rule.container_stop_event.name}"
}
