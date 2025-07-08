### **Relatório de Entrega do Projeto: Plataforma de Análise de Streaming em Tempo Real**

**Status:** Fase 5 de 6 Concluída
**Data:** 08/07/2025

#### **Sumário Executivo**

A equipe de consultoria concluiu com sucesso a implementação e validação do pipeline de dados de ponta a ponta para a Plataforma de Análise de Streaming em Tempo Real. A solução atual ingere eventos de clickstream, processa-os em tempo real para calcular métricas de negócio (contagem de cliques por página) e persiste os resultados em um banco de dados analítico de alta performance (ClickHouse).

Este marco representa a transição da fase de construção da infraestrutura para a fase de geração de valor. O sistema está agora pronto para alimentar dashboards operacionais, permitindo que a empresa passe de uma postura reativa (análise de dados antigos) para uma proativa, respondendo instantaneamente ao comportamento do usuário com uma latência de segundos.

---

#### **1. O Desafio de Negócio**

O cliente, uma empresa de e-commerce em rápido crescimento, enfrentava uma lacuna crítica de visibilidade em suas operações. A infraestrutura de análise existente, baseada em processos batch noturnos, resultava em uma latência de até 24 horas para a obtenção de insights. Essa demora impedia a equipe de identificar picos de tráfego, detectar anomalias de navegação ou entender o fluxo do usuário em tempo hábil. A necessidade era clara: uma plataforma de dados capaz de processar um alto volume de eventos com latência de segundos, não horas.

---

#### **2. Arquitetura e Implementação da Solução**

Para atender a esses requisitos, projetamos e implementamos um pipeline de streaming robusto e escalável, utilizando tecnologias padrão de mercado, totalmente orquestrado em um ambiente local com Docker.

**Diagrama da Arquitetura Funcional:**
`[Produtor Python] -> [Apache Kafka] -> [Apache Spark] -> [ClickHouse] -> [Metabase (Próxima Fase)]`

**Componentes Chave e Justificativas:**

*   **Ingestão (Apache Kafka):** Atua como o "sistema nervoso central" da plataforma, absorvendo picos de tráfego e garantindo que nenhum dado seja perdido.
*   **Processamento (Apache Spark):** Executa a lógica de negócio em tempo real, incluindo a validação de qualidade de cada evento e a agregação de métricas em janelas de tempo de 1 minuto.
*   **Persistência (ClickHouse):** Um banco de dados colunar (OLAP) foi escolhido para armazenar os agregados. Sua arquitetura é otimizada para escritas em lote e leituras analíticas extremamente rápidas, tornando-o a base ideal para dashboards de BI responsivos.

---

#### **3. Resumo Técnico do Progresso e Desafios Superados**

A jornada até este ponto envolveu a montagem e depuração sistemática de todo o pipeline, superando desafios técnicos comuns em projetos de dados de nível sênior:

1.  **Estabilização da Infraestrutura:** A infraestrutura local, gerenciada pelo `docker-compose`, foi configurada e depurada para garantir a comunicação estável entre todos os serviços. Isso incluiu a resolução de problemas de conectividade de rede entre Kafka e Zookeeper e a configuração correta de listeners.

2.  **Gerenciamento de Dependências do Spark:** O job Spark foi configurado para buscar dinamicamente os conectores necessários (Kafka e JDBC) em tempo de execução, eliminando a necessidade de construir imagens Docker personalizadas e simplificando a manutenção.

3.  **Controle de Schema do Banco de Dados (DDL):** Identificamos que a criação automática de tabelas pelo Spark não era compatível com os requisitos da engine `MergeTree` do ClickHouse. Assumimos o controle explícito do DDL, implementando um script de inicialização (`init-db.sh`) que cria a tabela com a estrutura otimizada (`ORDER BY`, `PARTITION BY`), garantindo alta performance de escrita e leitura.

4.  **Resolução de Problemas de Permissão:** Durante a configuração, diagnosticamos e corrigimos um problema sutil de permissão de execução (`chmod +x`) no script de inicialização do ClickHouse, um desafio comum ao mapear volumes de sistemas de arquivos Windows/WSL para contêineres Linux.

5.  **Gerenciamento de Estado no Streaming:** A aplicação Spark utiliza a técnica de **watermarking** para gerenciar o estado das agregações em janela. Isso instrui o Spark a descartar estados antigos, prevenindo o crescimento indefinido da memória e garantindo a estabilidade da aplicação em execuções de longa duração.

O resultado é um pipeline de dados **100% funcional e estável**, que processa dados continuamente desde a fonte até o banco de dados analítico.

---

#### **5. Próximos Passos (Fase 6)**

Com o pipeline de dados validado, o foco agora se volta para a entrega de valor aos stakeholders de negócio.

1.  **Visualização (Ação Imediata):** Conectar o Metabase ao ClickHouse para criar um dashboard que exiba a contagem de cliques por página, atualizando-se automaticamente para refletir os dados em tempo real.
2.  **Monitoramento:** Integrar Prometheus e Grafana para monitorar a saúde do pipeline, incluindo métricas de latência, throughput e taxas de erro.
3.  **Implantação na Nuvem:** Adaptar a solução para ser provisionada na AWS usando Terraform, demonstrando a transição de um ambiente de desenvolvimento local para um ambiente de produção escalável.