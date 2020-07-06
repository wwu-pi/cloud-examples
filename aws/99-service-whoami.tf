### Logging

resource "aws_cloudwatch_log_group" "example-whoami" {
  name = "/ecs/example-whoami"
}

### Task Definition

resource "aws_ecs_task_definition" "example-whoami" {
  family                   = "example-whoami"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = <<CONTAINER_DEFINITIONS
  [
    {
      "name": "whoami",
      "image": "jwilder/whoami",
      "essential": true,

      "cpu": 256,
      "memory": 512,
      "memoryReservation": 512,

      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.example-whoami.name}",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  CONTAINER_DEFINITIONS
}

### Security Groups

resource "aws_security_group" "example-whoami" {
  name   = "example-whoami"
  vpc_id = aws_vpc.example.id

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    cidr_blocks = [aws_vpc.example.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "example-whoami-lb" {
  name   = "example-whoami-lb"
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

resource "aws_lb_target_group" "example-whoami" {
  name        = "example-whoami"
  vpc_id      = aws_vpc.example.id
  target_type = "ip"
  protocol    = "HTTP"
  port        = 8000

  health_check {
    enabled  = true
    interval = 10
    protocol = "HTTP"
    port     = 8000
    path     = "/"
  }
}

resource "aws_lb" "example-whoami" {
  name               = "example-whoami"
  load_balancer_type = "application"
  internal           = false
  subnets            = aws_subnet.example[*].id
  security_groups    = [aws_security_group.example-whoami-lb.id]
}

resource "aws_lb_listener" "example-whoami" {
  load_balancer_arn = aws_lb.example-whoami.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example-whoami.arn
  }
}

### DNS Record

# Of cause a public DNS record could be configured in the same way
resource "aws_route53_record" "whoami_example_local" {
  zone_id = aws_route53_zone.example_local.zone_id
  name    = "whoami"
  type    = "A"

  alias {
    name                   = aws_lb.example-whoami.dns_name
    zone_id                = aws_lb.example-whoami.zone_id
    evaluate_target_health = true
  }
}

### ECS Service

resource "aws_ecs_service" "example-whoami" {
  name            = "example-whoami"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example-whoami.arn
  launch_type     = "FARGATE"

  scheduling_strategy                = "REPLICA"
  desired_count                      = 3
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = aws_subnet.example[*].id
    security_groups  = [aws_security_group.example-whoami.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example-whoami.arn
    container_name   = "whoami"
    container_port   = 8000
  }

  depends_on = [aws_lb.example-whoami]
}
