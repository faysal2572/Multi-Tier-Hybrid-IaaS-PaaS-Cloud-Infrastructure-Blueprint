# DB Subnet Group binds the private data subnets together
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = { Name = "Main DB Subnet Group" }
}

# PaaS Managed Relational Database Service (RDS)
resource "aws_db_instance" "postgres" {
  identifier             = "production-db"
  allocated_storage      = 20
  max_allocated_storage  = 100 # Storage Auto-scaling enabled
  engine                 = "postgres"
  engine_version         = "16.1"
  instance_class         = "db.t4g.micro" # Graviton processor (Cost-efficient)
  db_name                = "appdb"
  username               = "cloudadmin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  
  skip_final_snapshot    = true # Set to false for actual live business deployments
  multi_az               = false # Set to true for production high availability
}