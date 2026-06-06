# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = var.db_subnet_group_name
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name        = var.db_subnet_group_name
    Environment = var.environment
  }
}

# RDS Aurora MySQL Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = var.db_identifier
  engine                  = "aurora-mysql"
  engine_version          = "8.0.mysql_aurora.3.02.0"
  database_name           = "webappdb"
  master_username         = var.db_username
  master_password         = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.database_security_group_id]
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  enable_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name        = var.db_identifier
    Environment = var.environment
  }
}

# Primary RDS Instance
resource "aws_rds_cluster_instance" "primary" {
  cluster_identifier = aws_rds_cluster.main.id
  identifier         = "${var.db_identifier}-primary"
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = {
    Name        = "${var.db_identifier}-primary"
    Environment = var.environment
  }
}

# Secondary RDS Instance (Read Replica)
resource "aws_rds_cluster_instance" "replica" {
  cluster_identifier = aws_rds_cluster.main.id
  identifier         = "${var.db_identifier}-replica"
  instance_class     = "db.t3.small"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  tags = {
    Name        = "${var.db_identifier}-replica"
    Environment = var.environment
  }
}
