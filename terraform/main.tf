# Bloco de configuração do Terraform.
# Define os provedores necessários e suas versões.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Bloco de configuração do provedor (provider).
# Configura o provedor AWS, especificando a região onde os recursos serão criados.
provider "aws" {
  region = "us-west-2"
}

# --- Rede (Networking) ---

# 1. Virtual Private Cloud (VPC)
# A fundação isolada para todos os nossos recursos de nuvem.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  # --- Configurações Críticas de DNS ---
  # Habilita o suporte a DNS dentro da VPC (padrão já é true, mas é bom ser explícito).
  enable_dns_support   = true
  # Habilita a atribuição de nomes de host DNS públicos para instâncias na VPC.
  # Isso é crucial para a exibição de nomes e para a resolução de nomes de instâncias.
  enable_dns_hostnames = true

  tags = {
    Name = "rtp-vpc" # 'rtp' = Real-Time Platform
  }
}

# 2. Sub-rede Pública
# Uma sub-rede dentro da nossa VPC onde o servidor EC2 irá residir.
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24" # Um sub-range de IPs da VPC para esta sub-rede

  # Importante: Permite que instâncias nesta sub-rede recebam um IP público automaticamente.
  map_public_ip_on_launch = true

  tags = {
    Name = "rtp-public-subnet"
  }
}

# 3. Gateway de Internet
# Permite a comunicação entre a nossa VPC e a internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rtp-igw"
  }
}

# 4. Tabela de Rotas
# Define as regras de roteamento para o tráfego que sai da nossa sub-rede.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Rota padrão: todo o tráfego (0.0.0.0/0) é direcionado para o nosso Gateway de Internet.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rtp-public-route-table"
  }
}

# 5. Associação da Tabela de Rotas
# Conecta nossa tabela de rotas à nossa sub-rede pública.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Saídas (Outputs) ---
# Exibe informações importantes após a aplicação e força a resolução completa dos recursos.

output "vpc_id" {
  description = "O ID da nossa VPC principal."
  value       = aws_vpc.main.id
}

output "vpc_dns_hostnames_enabled" {
  description = "Confirma se os nomes de host DNS estão habilitados na VPC."
  value       = aws_vpc.main.enable_dns_hostnames
}