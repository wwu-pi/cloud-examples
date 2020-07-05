### Logging

resource "aws_cloudwatch_log_group" "example-wordpress" {
  name = "/ecs/example-wordpress"
}

### Task Definition

resource "aws_ecs_task_definition" "example-wordpress" {
  family                   = "example-wordpress"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = <<CONTAINER_DEFINITIONS
  [
    {
      "name": "wordpress",
      "image": "wordpress:5.4",
      "essential": true,

      "cpu": 1024,
      "memory": 2048,
      "memoryReservation": 2048,

      "environment": [
        { "name": "WORDPRESS_DB_HOST",     "value": "${aws_route53_record.mysql_example_local.fqdn}" },
        { "name": "WORDPRESS_DB_USER",     "value": "example" },
        { "name": "WORDPRESS_DB_PASSWORD", "value": "example" },
        { "name": "WORDPRESS_DB_NAME",     "value": "example" }
      ],

      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.example-wordpress.name}",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  CONTAINER_DEFINITIONS
}

### Security Groups

resource "aws_security_group" "example-wordpress" {
  name   = "example-wordpress"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "example-wordpress-lb" {
  name   = "example-wordpress-lb"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### Load Balancer

resource "aws_lb_target_group" "example-wordpress" {
  name        = "example-wordpress"
  vpc_id      = aws_vpc.example.id
  target_type = "ip"
  protocol    = "HTTP"
  port        = 80

  stickiness {
    enabled         = true
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  health_check {
    enabled  = true
    interval = 10
    protocol = "HTTP"
    port     = 80
    path     = "/"
    matcher  = "200-399"
  }
}

resource "aws_lb" "example-wordpress" {
  name               = "example-wordpress"
  load_balancer_type = "application"
  internal           = false
  subnets            = aws_subnet.example[*].id
  security_groups    = [aws_security_group.example-wordpress-lb.id]
}

resource "aws_lb_listener" "example-wordpress" {
  load_balancer_arn = aws_lb.example-wordpress.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example-wordpress.arn
  }
}

### DNS Record

# Of cause a public DNS record could be configured in the same way
resource "aws_route53_record" "wordpress_example_local" {
  zone_id = aws_route53_zone.example_local.zone_id
  name    = "wordpress"
  type    = "A"

  alias {
    name                   = aws_lb.example-wordpress.dns_name
    zone_id                = aws_lb.example-wordpress.zone_id
    evaluate_target_health = true
  }
}

### ECS Service

resource "aws_ecs_service" "example-wordpress" {
  name            = "example-wordpress"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example-wordpress.arn
  launch_type     = "FARGATE"

  scheduling_strategy                = "REPLICA"
  desired_count                      = 3
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = aws_subnet.example[*].id
    security_groups  = [aws_security_group.example-wordpress.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example-wordpress.arn
    container_name   = "wordpress"
    container_port   = 80
  }

  depends_on = [aws_lb.example-wordpress]
}
