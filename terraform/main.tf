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
  enable_dns_support = true
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

  # AÇÃO: Especificamos explicitamente a Zona de Disponibilidade
  # para garantir a compatibilidade com o tipo de instância t2.micro.
  availability_zone = "us-west-2a"

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

# -----------------------------------------------------------------------------
# SECURITY GROUP
# Define o firewall virtual para o nosso servidor de aplicacao EC2.
# -----------------------------------------------------------------------------
resource "aws_security_group" "rtp_server_sg" {
  name        = "rtp-server-sg"
  # Descrição principal corrigida
  description = "Permite acesso SSH (restrito) e portas das UIs da aplicacao"
  vpc_id      = aws_vpc.main.id

  # --- Regras de Entrada (Ingress) ---

  # Regra 1: Acesso Administrativo (SSH)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["179.0.58.161/32"] # Seu IP já está aqui
    # Descrição corrigida
    description = "Permite acesso SSH para o desenvolvedor"
  }

  # Regra 2: Acesso a UI do Metabase
  ingress {
    from_port   = 3030
    to_port     = 3030
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # Descrição corrigida
    description = "Permite acesso publico a UI do Metabase"
  }

  # Regra 3: Acesso a UI do Spark Master
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # Descrição corrigida
    description = "Permite acesso publico a UI do Spark Master"
  }

  # Regra 4: Acesso a UI do Spark Worker
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # Descrição corrigida
    description = "Permite acesso publico a UI do Spark Worker"
  }
  
  # Regra 5: Acesso a UI de Jobs do Spark
  ingress {
    from_port   = 4040
    to_port     = 4040
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # Descrição corrigida
    description = "Permite acesso publico a UI de Jobs do Spark"
  }

  # --- Regra de Saída (Egress) ---
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    # Adicionando uma descricao aqui também, por consistencia
    description = "Permite todo o trafego de saida"
  }

  tags = {
    Name    = "rtp-server-sg"
    Project = "Real-Time Platform"
  }
}

# -----------------------------------------------------------------------------
# CHAVE SSH
# Referencia a chave pública que criamos no console da AWS.
# -----------------------------------------------------------------------------
resource "aws_key_pair" "rtp_key" {
  # O nome deve corresponder EXATAMENTE ao nome que você deu no console da AWS.
  key_name   = "rtp-key-pair"
  # O Terraform não precisa do conteúdo da chave, apenas do nome para associá-la.
  # No entanto, para garantir que o Terraform possa gerenciar a chave,
  # podemos fornecer a chave pública. É uma prática mais robusta.
  # Para extrair a chave pública do seu arquivo .pem, use o comando:
  # ssh-keygen -y -f ~/keypair/rtp-key-pair.pem
  # E cole a saída aqui.
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCUS5afEWJBOuwuKQlb5fhzuWJURKGpsl+WZhFn//QyPmo6B8QmAo1YHswFBbM4A9lJIP6av5L6biyakEPxAAg0c1z9qMp63qGsM+fwvX1OsFL+bmP1qPPK6SIz7DNU1E5y0MC49D1o6ewWywXBjAdCSRll7EE/ueo7sZBYfRSMoIWc8ThjbmNloDySrCIuvdjCDany8Dj5rvtECPYkxeZlDcJ46tTWrERXPcXlKZ8M/nm7fKwNpIiGMFBNxmPpLDMcPEMCVfGn/++uc9unsUHuaA18IQlM63nxsoszx6InYzEE7Nk7aKxQAy0l/XmTZz2CcQi8gbCoy8waCBH6nWMD" 
}

# -----------------------------------------------------------------------------
# SERVIDOR DE APLICAÇÃO (EC2)
# A máquina virtual que irá hospedar nossa stack Docker.
# -----------------------------------------------------------------------------
resource "aws_instance" "rtp_server" {
  # O "Porquê" da AMI: Usamos uma imagem oficial do Ubuntu 22.04 LTS.
  # É estável, bem suportada e está no Free Tier da AWS.
  # Este ID de AMI é específico para a região us-west-2.
  ami           = "ami-0ec1bf4a8f92e7bd1"

  # O "Porquê" do Tipo de Instância: t2.micro é elegível para o Free Tier,
  # minimizando os custos durante o desenvolvimento e validação.
  instance_type = "t3.micro"

  # Associa a instância à nossa sub-rede pública.
  subnet_id     = aws_subnet.public.id

  # Associa nosso firewall (Security Group) à instância.
  vpc_security_group_ids = [aws_security_group.rtp_server_sg.id]

  # Associa a chave SSH para permitir o login seguro.
  key_name      = aws_key_pair.rtp_key.key_name

  # Dependência explícita para garantir que o IGW esteja pronto antes de lançar a instância.
  # Isso evita race conditions onde a instância tenta acessar a internet antes que a rota exista.
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name    = "rtp-server"
    Project = "Real-Time Platform"
  }
}