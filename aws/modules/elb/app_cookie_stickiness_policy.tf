#---------------------------------------------------
#Add APP cookie stickiness policy
#---------------------------------------------------
resource "aws_app_cookie_stickiness_policy" "app_cookie_stickiness_policy_http" {
  count = var.enable_app_cookie_stickiness_policy_http ? 1 : 0

  name          = var.app_cookie_stickiness_policy_http_name != "" ? var.app_cookie_stickiness_policy_http_name : "${lower(var.name)}-app-cookie-stickiness-policy-http-${lower(var.environment)}"
  load_balancer = var.elb_id != "" ? var.elb_id : element(concat(aws_elb.elb.*.id, [""]), 0)
  lb_port       = var.http_lb_port
  cookie_name   = var.cookie_name

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_elb.elb
  ]
}
resource "aws_app_cookie_stickiness_policy" "app_cookie_stickiness_policy_https" {
  count = var.enable_app_cookie_stickiness_policy_https ? 0 : 1

  name          = var.app_cookie_stickiness_policy_https_name != "" ? var.app_cookie_stickiness_policy_https_name : "${lower(var.name)}-app-cookie-stickiness-policy-https-${lower(var.environment)}"
  load_balancer = var.elb_id != "" ? var.elb_id : element(concat(aws_elb.elb.*.id, [""]), 0)
  lb_port       = var.https_lb_port
  cookie_name   = var.cookie_name

  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = [
    aws_elb.elb
  ]
}
