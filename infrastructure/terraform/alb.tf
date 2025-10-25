# Application Load Balancer para enrutar tráfico HTTP/HTTPS hacia Lambdas

# ALB principal en subnets públicas
resource "aws_lb" "main" {
  name               = "${local.prefix}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = merge(local.common_tags, {
    Name = "${local.prefix}-${var.environment}-alb"
    Type = "LoadBalancer"
  })
}

# Target Groups para Lambdas
resource "aws_lb_target_group" "tg_health" {
  name        = "${local.prefix}-${var.environment}-tg-health"
  target_type = "lambda"
}

resource "aws_lb_target_group" "tg_productos" {
  name        = "${local.prefix}-${var.environment}-tg-productos"
  target_type = "lambda"
}

resource "aws_lb_target_group" "tg_inventario" {
  name        = "${local.prefix}-${var.environment}-tg-inventario"
  target_type = "lambda"
}

resource "aws_lb_target_group" "tg_ventas" {
  name        = "${local.prefix}-${var.environment}-tg-ventas"
  target_type = "lambda"
}

resource "aws_lb_target_group" "tg_reportes" {
  name        = "${local.prefix}-${var.environment}-tg-reportes"
  target_type = "lambda"
}

# Permisos para que ALB invoque las Lambdas (uno por función)
resource "aws_lambda_permission" "alb_health" {
  statement_id  = "allow-alb-invoke-health"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg_health.arn
}

resource "aws_lambda_permission" "alb_productos" {
  statement_id  = "allow-alb-invoke-productos"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.productos_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg_productos.arn
}

resource "aws_lambda_permission" "alb_inventario" {
  statement_id  = "allow-alb-invoke-inventario"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inventario_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg_inventario.arn
}

resource "aws_lambda_permission" "alb_ventas" {
  statement_id  = "allow-alb-invoke-ventas"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ventas_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg_ventas.arn
}

resource "aws_lambda_permission" "alb_reportes" {
  statement_id  = "allow-alb-invoke-reportes"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reportes_lambda.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.tg_reportes.arn
}

# Adjuntar Lambdas a sus Target Groups
resource "aws_lb_target_group_attachment" "health" {
  target_group_arn = aws_lb_target_group.tg_health.arn
  target_id        = aws_lambda_function.health_lambda.arn
  depends_on       = [aws_lambda_permission.alb_health]
}

resource "aws_lb_target_group_attachment" "productos" {
  target_group_arn = aws_lb_target_group.tg_productos.arn
  target_id        = aws_lambda_function.productos_lambda.arn
  depends_on       = [aws_lambda_permission.alb_productos]
}

resource "aws_lb_target_group_attachment" "inventario" {
  target_group_arn = aws_lb_target_group.tg_inventario.arn
  target_id        = aws_lambda_function.inventario_lambda.arn
  depends_on       = [aws_lambda_permission.alb_inventario]
}

resource "aws_lb_target_group_attachment" "ventas" {
  target_group_arn = aws_lb_target_group.tg_ventas.arn
  target_id        = aws_lambda_function.ventas_lambda.arn
  depends_on       = [aws_lambda_permission.alb_ventas]
}

resource "aws_lb_target_group_attachment" "reportes" {
  target_group_arn = aws_lb_target_group.tg_reportes.arn
  target_id        = aws_lambda_function.reportes_lambda.arn
  depends_on       = [aws_lambda_permission.alb_reportes]
}

# Listener HTTP (80). En producción, ideal redirigir a HTTPS; aquí se hace forward.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_health.arn
  }
}

# Listener HTTPS (443) opcional si hay certificado ACM
resource "aws_lb_listener" "https" {
  count             = var.alb_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_health.arn
  }
}

# Reglas de routing por path (HTTP)
resource "aws_lb_listener_rule" "path_productos" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_productos.arn
  }

  condition {
    path_pattern {
      values = ["/productos*"]
    }
  }
}

resource "aws_lb_listener_rule" "path_inventario" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_inventario.arn
  }

  condition {
    path_pattern {
      values = ["/inventario*"]
    }
  }
}

resource "aws_lb_listener_rule" "path_ventas" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_ventas.arn
  }

  condition {
    path_pattern {
      values = ["/ventas*"]
    }
  }
}

resource "aws_lb_listener_rule" "path_reportes" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_reportes.arn
  }

  condition {
    path_pattern {
      values = ["/reportes*"]
    }
  }
}