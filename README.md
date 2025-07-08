# Projeto 1: Plataforma de Análise de Streaming em Tempo Real

## 🎯 Sumário Executivo

Este projeto implementa um pipeline de dados de ponta a ponta para a análise em tempo real de eventos de clickstream de um site de e-commerce. A solução ingere eventos de cliques de usuários, processa-os com o Apache Spark para calcular métricas de negócio em janelas de tempo (contagem de cliques por página a cada minuto) e persiste os resultados em um banco de dados analítico (ClickHouse) para visualização em um dashboard de BI (Metabase). O objetivo é fornecer insights operacionais com latência de segundos, demonstrando uma arquitetura escalável, resiliente e observável.

## 📈 O Desafio de Negócio

Uma empresa de e-commerce em crescimento precisa de visibilidade imediata sobre como os usuários interagem com sua plataforma. As análises baseadas em lotes (batch) existentes têm uma latência de horas, o que é muito lento para responder a tendências de navegação, identificar sessões de usuários com problemas ou detectar atividades fraudulentas (bots) em tempo hábil. A empresa necessita de uma solução que possa processar dezenas de milhares de eventos por segundo, garantindo ao mesmo tempo a qualidade e a integridade dos dados para a tomada de decisão.

## 🏗️ Arquitetura da Solução

A arquitetura foi projetada para ser escalável, resiliente e otimizada para custos, utilizando um modelo de desenvolvimento híbrido (local + nuvem). O fluxo de dados segue as melhores práticas de uma arquitetura de streaming moderna.

> **Nota:** O diagrama final será adicionado ao concluir o projeto.

### 🌊 Fluxo de Dados

1.  **Geração de Dados:** Um script Python (`data_producer`) simula eventos de clickstream em formato JSON e os publica em um tópico no Apache Kafka.
2.  **Ingestão e Buffer:** O Apache Kafka atua como um *message broker* central, recebendo os eventos em tempo real e funcionando como um buffer resiliente que desacopla os produtores dos consumidores.
3.  **Processamento em Stream:** Um job do Apache Spark (`stream_processor`) consome os dados do Kafka em micro-lotes. O processamento ocorre em várias etapas:
    -   **Parsing e Estruturação:** O JSON bruto é transformado em um DataFrame Spark com um schema bem definido e tipagem forte.
    -   **Validação de Qualidade:** Cada registro é validado contra regras de negócio (ex: `user_id` e `page_url` não podem ser nulos).
    -   **Agregação em Janela:** Os dados válidos são agregados em janelas de tempo de 1 minuto (*tumbling windows*). O uso de *watermarking* garante o tratamento correto de dados atrasados e o gerenciamento eficiente do estado da aplicação Spark.
4.  **Persistência:** Os resultados agregados são escritos via JDBC em uma tabela otimizada no ClickHouse, um banco de dados colunar de alta performance ideal para consultas analíticas.
5.  **Visualização:** O Metabase se conecta ao ClickHouse para consumir os dados agregados e exibi-los em dashboards interativos, fornecendo a camada de *Business Intelligence* para os stakeholders.

## 🛠️ Tech Stack (Pilha de Tecnologias)

| Componente | Tecnologia | Justificativa de Negócio/Técnica |
| :--- | :--- | :--- |
| **Geração de Dados** | Python (Faker, kafka-python) | Simula um ambiente de produção realista com dados dinâmicos. |
| **Message Broker** | Apache Kafka | Padrão da indústria para ingestão de dados em alto volume e baixa latência. Desacopla sistemas e garante resiliência. |
| **Processamento** | Apache Spark (PySpark) | Motor de processamento distribuído ideal para transformações complexas e agregações em streams de dados com alta performance. |
| **Banco de Dados** | ClickHouse | Banco de dados colunar otimizado para escritas em lote e leituras analíticas (OLAP) extremamente rápidas, perfeito para alimentar dashboards. |
| **BI / Visualização** | Metabase | Ferramenta de BI open-source que permite a criação rápida de dashboards e a exploração de dados de forma intuitiva. |
| **Infraestrutura** | Docker / Docker Compose | Permite a criação de um ambiente de desenvolvimento local completo e reprodutível, encapsulando todas as dependências. |
| **Infra como Código** | Terraform (Fase Futura) | Automatiza o provisionamento da infraestrutura na nuvem (AWS), garantindo consistência, reprodutibilidade e controle de versão. |

## 🚀 Guia de Execução Local

Este projeto é totalmente conteinerizado e gerenciado pelo Docker Compose para uma experiência de desenvolvimento simplificada.

### ✅ Pré-requisitos

-   Windows com WSL2, ou um sistema Linux/macOS
-   Docker e Docker Compose instalados
-   Git

### ⚙️ Passos para Execução

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/seu-usuario/seu-repositorio.git
    cd seu-repositorio
    ```

2.  **Permissão de Execução (Apenas na primeira vez):**
    O script de inicialização do ClickHouse precisa de permissão de execução.
    ```bash
    chmod +x ./clickhouse/init-db.sh
    ```

3.  **Inicie toda a infraestrutura:**
    Este comando irá iniciar Kafka, Zookeeper, Spark Master/Worker, ClickHouse e Metabase em modo *detached* (-d).
    ```bash
    docker-compose up -d
    ```
    Para verificar o status de todos os serviços, use `docker ps`.

4.  **Acesse as UIs para monitoramento:**
    -   **Spark Master UI:** [http://localhost:8080](http://localhost:8080)
    -   **Metabase UI:** [http://localhost:3000](http://localhost:3000)

5.  **Crie o tópico no Kafka (Apenas na primeira vez ou após `down -v`):**
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
    O comando `--packages` instrui o Spark a baixar dinamicamente os conectores JDBC e Kafka necessários.
    ```bash
    docker exec -it spark-master spark-submit \
      --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1,com.clickhouse:clickhouse-jdbc:0.5.0,org.apache.httpcomponents.client5:httpclient5:5.2.1 \
      /app/spark_processor/stream_processor.py
    ```
    Você verá os logs do Spark processando os dados em lotes e confirmando a escrita no ClickHouse.

## 📊 Fase 6: Visualização e Business Intelligence

Nesta fase, o objetivo é conectar a camada de BI (Metabase) aos dados agregados no ClickHouse para visualizar os resultados do pipeline e extrair valor de negócio.

### 6.1. Validação do Pipeline e Análise Crítica

Após configurar a conexão entre o Metabase e o ClickHouse, criamos um dashboard inicial para visualizar a contagem de cliques por página, com atualização automática a cada 15 segundos.

**Resultado Inicial:**

![Dashboard Inicial com Dados Simulados](/real-time-platform/jpeg/graf1.jpg)

**Análise Crítica:**
O dashboard acima confirma que o pipeline de ponta a ponta está **tecnicamente funcional**: eventos são gerados, processados pelo Spark e persistidos no ClickHouse, com os resultados sendo exibidos no Metabase em tempo real.

No entanto, ele **falha em gerar insights de negócio acionáveis**. Todas as barras do gráfico possuem uma contagem de "1". Isso ocorre porque o script `data_producer.py`, em sua versão inicial, utiliza a biblioteca `Faker` para gerar uma URL completamente nova e única para cada evento. Como resultado, ao agregar os dados em janelas de 1 minuto, cada página (`page_url`) aparece apenas uma vez, resultando em uma contagem de 1.

### 6.2. Resultado Final e Valor de Negócio

Após refinar o script `data_producer.py` para simular um comportamento de usuário mais realista (com páginas populares recebendo mais tráfego), o pipeline passou a gerar agregações significativas. O dashboard final agora fornece insights de negócio claros e em tempo real.

**Dashboard Final:**

![Dashboard Final com Dados Realistas](/real-time-platform/jpeg/graf2.jpg)

**Análise de Valor:**
Este dashboard demonstra o valor de negócio da solução de ponta a ponta:

*   **Visibilidade Operacional:** Stakeholders podem monitorar quais páginas estão com maior engajamento no último minuto.
*   **Tomada de Decisão Rápida:** Anomalias, como uma queda drástica de cliques em páginas críticas (ex: `/cart`), podem ser detectadas em segundos, em vez de horas.
*   **Validação de Arquitetura:** O gráfico prova que a arquitetura é capaz de ingerir, processar, agregar e visualizar dados com baixa latência, cumprindo o objetivo principal do projeto.

## ☁️ Fase 7: Implantação na Nuvem com IaC (Terraform)

Com a solução validada localmente, esta fase eleva o projeto a um nível de produção, automatizando a implantação da infraestrutura na nuvem da AWS usando Terraform. O objetivo é demonstrar a capacidade de criar um ambiente replicável, escalável e gerenciado como código, uma habilidade essencial para qualquer engenheiro de dados sênior ou arquiteto de soluções.

### 7.1. Configuração e Fundação da Rede

O primeiro passo na nuvem é construir uma fundação de rede segura e isolada para nossos serviços. Utilizando Terraform, definimos e provisionamos os seguintes recursos:

*   **Provedor AWS e Usuário IAM:** Configuração inicial do Terraform para se comunicar com a AWS de forma segura, utilizando um usuário IAM dedicado com permissões específicas, em vez do usuário root.
*   **Virtual Private Cloud (VPC):** Criação de uma rede privada (`10.0.0.0/16`) na região `us-west-2` (Oregon), isolando nossos recursos da internet pública por padrão.
*   **Sub-rede Pública:** Definição de uma sub-rede (`10.0.1.0/24`) dentro da VPC, projetada para hospedar recursos que precisam de acesso à internet.
*   **Gateway de Internet e Tabela de Rotas:** Configuração dos componentes necessários para permitir que os recursos na sub-rede pública se comuniquem com o mundo exterior, essencial para baixar pacotes e imagens Docker.

Todo o processo é definido em arquivos `.tf`, garantindo que a infraestrutura seja:
-   **Versionável:** Pode ser armazenada no Git, assim como o código da aplicação.
-   **Reprodutível:** Pode ser destruída (`terraform destroy`) e recriada (`terraform apply`) com um único comando, garantindo consistência.
-   **Documentada:** O próprio código serve como documentação clara da arquitetura da rede.

### 7.2. Próximos Passos na Nuvem

Com a fundação da rede estabelecida, os próximos passos se concentrarão em provisionar os componentes da aplicação:

1.  **Firewall (Security Groups):** Definir regras de firewall para controlar o tráfego de entrada (SSH, portas da aplicação) e saída para o nosso servidor.
2.  **Servidor de Aplicação (EC2):** Provisionar uma instância de máquina virtual que irá hospedar nossa stack Docker (Kafka, Spark, ClickHouse, etc.).
3.  **Configuração e Validação:** Automatizar a configuração do servidor EC2 para instalar o Docker, clonar nosso projeto e iniciar o pipeline de dados, validando a solução de ponta a ponta no ambiente de nuvem.