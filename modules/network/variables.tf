# modules/network/main.tf
# Define la infraestructura de red: VPC, Subredes, Gateways y Ruteo.

# Obtener las Zonas de Disponibilidad (AZs) en la región actual
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Crear la VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc-${var.environment}"
  })
}

# 2. Crear el Internet Gateway (para las subredes públicas)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.project_name}-igw-${var.environment}"
  })
}

# 3. Crear Subredes Públicas
resource "aws_subnet" "public" {
  # Crea una subred por cada CIDR en la variable
  count                   = length(var.public_sn_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_sn_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Asigna IPs públicas automáticamente

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-sn-${count.index + 1}-${var.environment}"
  })
}

# 4. Crear Subredes Privadas (para la aplicación)
resource "aws_subnet" "private" {
  count             = length(var.private_sn_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_sn_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-sn-${count.index + 1}-${var.environment}"
  })
}

# 5. Crear Subredes de Base de Datos (aisladas)
resource "aws_subnet" "database" {
  count             = length(var.database_sn_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_sn_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-database-sn-${count.index + 1}-${var.environment}"
  })
}

# 6. Crear el NAT Gateway (para que las subredes privadas salgan a internet)
# Se necesita una IP Elástica (EIP) primero
resource "aws_eip" "nat" {
  # Creamos una EIP por cada subred pública (para alta disponibilidad)
  count      = length(var.public_sn_cidrs)
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}-${var.environment}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_sn_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.project_name}-nat-gw-${count.index + 1}-${var.environment}"
  })
}

# 7. Tablas de Ruteo
# Tabla de ruteo para subredes públicas (tráfico a 0.0.0.0/0 -> Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-public-rt-${var.environment}"
  })
}

# Tabla de ruteo para subredes privadas (tráfico a 0.0.0.0/0 -> NAT Gateway)
resource "aws_route_table" "private" {
  # Creamos una tabla de ruteo por cada AZ/NAT Gateway
  count  = length(var.private_sn_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-rt-${count.index + 1}-${var.environment}"
  })
}

# Tabla de ruteo para subredes de BD (sin salida a internet)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-database-rt-${var.environment}"
  })
}

# 8. Asociaciones de Ruteo
# Asociar subredes públicas a la tabla pública
resource "aws_route_table_association" "public" {
  count          = length(var.public_sn_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Asociar subredes privadas a sus tablas privadas (una por AZ)
resource "aws_route_table_association" "private" {
  count          = length(var.private_sn_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Asociar subredes de BD a la tabla de BD
resource "aws_route_table_association" "database" {
  count          = length(var.database_sn_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# 9. Grupo de subredes para RDS
resource "aws_db_subnet_group" "database" {
  name       = "${var.project_name}-db-subnet-group-${var.environment}"
  subnet_ids = [for s in aws_subnet.database : s.id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group-${var.environment}"
  })
}

