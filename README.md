# Projeto 1: Plataforma de Análise de Streaming em Tempo Real

## 🎯 Sumário Executivo

Este projeto implementa um pipeline de dados de ponta a ponta para a análise em tempo real de eventos de clickstream de um site de e-commerce. A solução ingere eventos de cliques de usuários, processa-os com o Apache Spark para calcular métricas de negócio em janelas de tempo e persiste os resultados em um banco de dados analítico (ClickHouse) para visualização em um dashboard de BI (Metabase). O objetivo é fornecer insights operacionais com latência de segundos, demonstrando uma arquitetura escalável, resiliente e gerenciada como código (IaC).

## 📈 O Desafio de Negócio

Uma empresa de e-commerce em crescimento precisa de visibilidade imediata sobre como os usuários interagem com sua plataforma. As análises baseadas em lotes (batch) existentes têm uma latência de horas, o que é muito lento para responder a tendências de navegação, identificar sessões de usuários com problemas ou detectar atividades fraudulentas (bots) em tempo hábil. A empresa necessita de uma solução que possa processar dezenas de milhares de eventos por segundo, garantindo ao mesmo tempo a qualidade e a integridade dos dados para a tomada de decisão.

## 🏗️ Arquitetura da Solução

A arquitetura foi projetada para ser escalável, resiliente e otimizada para custos, utilizando um modelo de desenvolvimento híbrido (local + nuvem).

> **Nota:** O diagrama final da arquitetura completa será adicionado ao concluir o projeto.

### 🌊 Fluxo de Dados

1.  **Geração de Dados:** Um script Python (`data_producer`) simula eventos de clickstream e os publica no Apache Kafka.
2.  **Ingestão e Buffer:** O Apache Kafka atua como um *message broker* central, desacoplando produtores e consumidores.
3.  **Processamento em Stream:** Um job do Apache Spark (`stream_processor`) consome os dados, valida sua qualidade, e os agrega em janelas de tempo de 1 minuto com *watermarking* para gerenciar dados atrasados.
4.  **Persistência:** Os resultados agregados são escritos via JDBC no ClickHouse, um banco de dados colunar de alta performance.
5.  **Visualização:** O Metabase se conecta ao ClickHouse para exibir os dados em dashboards interativos em tempo real.

## 🛠️ Tech Stack (Pilha de Tecnologias)

| Componente | Tecnologia | Justificativa de Negócio/Técnica |
| :--- | :--- | :--- |
| **Geração de Dados** | Python (Faker, kafka-python) | Simula um ambiente de produção realista com dados dinâmicos. |
| **Message Broker** | Apache Kafka | Padrão da indústria para ingestão de dados em alto volume e baixa latência. Desacopla sistemas e garante resiliência. |
| **Processamento** | Apache Spark (PySpark) | Motor de processamento distribuído ideal para transformações complexas e agregações em streams de dados com alta performance. |
| **Banco de Dados** | ClickHouse | Banco de dados colunar otimizado para escritas em lote e leituras analíticas (OLAP) extremamente rápidas, perfeito para alimentar dashboards. |
| **BI / Visualização** | Metabase | Ferramenta de BI open-source que permite a criação rápida de dashboards e a exploração de dados de forma intuitiva. |
| **Infraestrutura Local** | Docker / Docker Compose | Permite a criação de um ambiente de desenvolvimento local completo e reprodutível, encapsulando todas as dependências. |
| **Infraestrutura na Nuvem** | AWS (EC2, VPC, S3) | Provedor de nuvem líder de mercado, oferecendo os blocos de construção para uma infraestrutura escalável e segura. |
| **Infra como Código** | Terraform | Automatiza o provisionamento da infraestrutura na nuvem (AWS), garantindo consistência, reprodutibilidade e controle de versão. |

---

## 🚀 Guia de Execução

Este projeto foi projetado para ser executado tanto localmente (para desenvolvimento e testes rápidos) quanto na nuvem da AWS (para validação em um ambiente de produção simulado).

### 1. Execução Local com Docker

Este modo é ideal para desenvolver, testar e entender o fluxo de dados sem incorrer em custos de nuvem.

#### ✅ Pré-requisitos Locais

-   Windows com WSL2, ou um sistema Linux/macOS
-   Docker e Docker Compose instalados
-   Git

#### ⚙️ Passos para Execução Local

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/seu-usuario/seu-repositorio.git
    cd seu-repositorio
    ```

2.  **Permissão de Execução (Apenas na primeira vez):**
    ```bash
    chmod +x ./clickhouse/init-db.sh
    ```

3.  **Inicie toda a infraestrutura:**
    ```bash
    docker-compose up -d
    ```

4.  **Acesse as UIs para monitoramento:**
    -   **Spark Master UI:** [http://localhost:8080](http://localhost:8080)
    -   **Metabase UI:** [http://localhost:3030](http://localhost:3030) (Note a porta 3030)

5.  **Crie o tópico no Kafka:**
    ```bash
    docker exec -it kafka kafka-topics --create \
      --bootstrap-server kafka:9092 \
      --topic clickstream_events \
      --partitions 1 \
      --replication-factor 1
    ```

6.  **Inicie o produtor de dados (em um novo terminal):**
    ```bash
    python data_producer/data_producer.py
    ```

7.  **Inicie o processador de stream Spark (em outro terminal):**
    ```bash
    docker exec -it spark-master spark-submit \
      --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,com.clickhouse:clickhouse-jdbc:0.5.0,org.apache.httpcomponents.client5:httpclient5:5.2.1 \
      /app/spark_processor/stream_processor.py
    ```

### 2. Execução na Nuvem com Terraform e AWS

Este modo demonstra a capacidade de provisionar e implantar a solução em um ambiente de nuvem de forma automatizada, validando a arquitetura em um cenário realista.

#### ✅ Pré-requisitos da Nuvem

-   Uma conta AWS.
-   AWS CLI instalado e configurado.
-   Terraform instalado.
-   Um par de chaves SSH criado na sua conta AWS.

#### ⚙️ Passos para Execução na Nuvem

1.  **Navegue até o diretório do Terraform:**
    ```bash
    cd terraform
    ```

2.  **Configure a Infraestrutura:**
    -   Edite o arquivo `main.tf` para configurar seu endereço IP na regra de SSH do Security Group.
    -   Adicione sua chave pública SSH (extraída do seu arquivo `.pem`) ao recurso `aws_key_pair`.
    -   O tipo de instância está configurado como `t3.micro` para um equilíbrio entre performance e custo (dentro do Free Tier).

3.  **Provisione a Infraestrutura:**
    ```bash
    terraform init  # Apenas na primeira vez
    terraform apply # Para criar a infraestrutura
    ```

4.  **Acesse o Servidor:**
    -   Obtenha o IP público da instância EC2 criada no console da AWS.
    -   Conecte-se via SSH:
        ```bash
        ssh -i /caminho/para/sua/chave.pem ubuntu@IP_PUBLICO_DA_INSTANCIA
        ```

5.  **Configure o Servidor e Implante a Aplicação (Dentro do SSH):**
    -   **Instale as dependências (Git, Docker, etc.):**
        ```bash
        # Atualiza o sistema
        sudo apt-get update && sudo apt-get upgrade -y
        # Instala dependências e o Git
        sudo apt-get install -y ca-certificates curl gnupg git
        # Instala o Docker (script completo nos relatórios do projeto)
        # ...
        ```
    -   **Clone o repositório, configure permissões e execute o `docker compose`** conforme os passos da execução local.

6.  **Acesse as UIs:**
    Após a implantação, as interfaces estarão disponíveis nos seguintes endereços:
    -   **Spark Master UI:** `http://<IP_PUBLICO_DA_INSTANCIA>:8080`
    -   **Metabase UI:** `http://<IP_PUBLICO_DA_INSTANCIA>:3030`

7.  **Desprovisione a Infraestrutura:**
    **IMPORTANTE:** Para evitar custos, destrua toda a infraestrutura após a validação.
    ```bash
    # No diretório terraform, na sua máquina local
    terraform destroy
    ```

---

## 💡 Lições Aprendidas e Próximas Etapas

*   **Dimensionamento de Instâncias (Right-Sizing):** A implantação inicial em uma instância `t2.micro` falhou devido à sobrecarga de recursos durante a inicialização simultânea de múltiplos serviços. A migração para uma `t3.micro`, que possui um modelo de créditos de CPU mais flexível, resolveu o problema de responsividade. Isso destaca a importância de escolher o tipo de instância adequado para a carga de trabalho, mesmo em fases de teste.
*   **Ciclo de Vida de IaC:** O projeto demonstrou o ciclo de vida completo da Infraestrutura como Código: provisionamento (`apply`), modificação (mudança do tipo de instância) e desprovisionamento (`destroy`), tudo gerenciado de forma controlada e previsível.
*   **Depuração Multi-camada:** Os desafios enfrentados exigiram depuração em todas as camadas da stack: código Terraform, configurações da AWS (Security Groups, AZs), sistema operacional do servidor (UFW) e a própria aplicação (Docker).

**Próximas Etapas (Para um Projeto em Produção):**
1.  **Utilizar Serviços Gerenciados:** Migrar de serviços auto-hospedados em EC2 para serviços gerenciados da AWS (ex: Amazon MSK para Kafka, Amazon EMR para Spark, Amazon RDS/Redshift para o banco de dados) para aumentar a resiliência e reduzir a sobrecarga operacional.
2.  **Automação de CI/CD:** Criar um pipeline de CI/CD (ex: com GitHub Actions) para automatizar os testes e a implantação da aplicação sempre que houver uma alteração no código.
3.  **Monitoramento e Alertas:** Implementar uma solução de monitoramento robusta (ex: Prometheus/Grafana ou Amazon CloudWatch) para observar a saúde da aplicação e da infraestrutura, com alertas para falhas ou anomalias.

---

---

## 📊 Resultados e Valor de Negócio

O pipeline foi validado com sucesso, culminando em um dashboard no Metabase que exibe a contagem de cliques por página em tempo real.

![Dashboard Final com Dados Realistas](/jpeg/graf2.jpg)

**Análise de Valor:**
*   **Visibilidade Operacional:** Stakeholders podem monitorar o engajamento das páginas no último minuto.
*   **Tomada de Decisão Rápida:** Anomalias, como uma queda drástica de cliques em páginas críticas (ex: `/cart`), podem ser detectadas em segundos.
*   **Validação de Arquitetura:** O gráfico prova que a arquitetura é capaz de ingerir, processar, agregar e visualizar dados com baixa latência, cumprindo o objetivo principal do projeto.