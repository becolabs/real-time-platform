### **Relatório de Entrega do Projeto: Plataforma de Análise de Streaming em Tempo Real**

**Status:** Fase 7 de 8 Concluída (Provisionamento da Infraestrutura na Nuvem)
**Data:** 09/07/2025

#### **Sumário Executivo**

A equipe de consultoria concluiu com sucesso a Fase 7 do projeto, que consistiu no provisionamento completo e automatizado da infraestrutura de nuvem na AWS. Utilizando a metodologia de Infraestrutura como Código (IaC) com Terraform, transformamos a arquitetura validada localmente em um ambiente de nuvem replicável, seguro e escalável. Este marco eleva o projeto de um protótipo funcional para uma solução com fundações prontas para produção, demonstrando competência em automação, segurança e arquitetura de nuvem, habilidades essenciais para a engenharia de dados moderna.

A infraestrutura agora consiste em uma rede privada virtual (VPC), um firewall granular (Security Group) e um servidor de aplicação (EC2), todos provisionados e gerenciados através de código versionado.

---

#### **1. O Desafio de Negócio**

Após validar o valor de negócio do pipeline de streaming em um ambiente local (Fases 1-6), o desafio passou a ser como implantar essa solução de forma confiável e escalável na nuvem. Uma implantação manual seria propensa a erros, difícil de replicar e impossível de gerenciar em escala. A necessidade era clara: criar um processo automatizado que garantisse que o ambiente de nuvem fosse uma réplica exata da arquitetura projetada, de forma segura e otimizada para custos.

---

#### **2. Arquitetura e Implementação da Solução na Nuvem**

Adotamos a Infraestrutura como Código (IaC) como o pilar desta fase, utilizando o Terraform para definir e provisionar todos os recursos necessários na AWS.

**Diagrama da Arquitetura da Infraestrutura (Simplificado):**
`[Internet] -> [Internet Gateway] -> [Route Table] -> [Public Subnet] -> [Security Group] -> [EC2 Instance]`

**Componentes Chave da Infraestrutura e Justificativas:**

*   **Rede (VPC, Subnet, IGW, Route Table):** Construímos uma fundação de rede isolada e segura, garantindo que nossos recursos não fiquem expostos por padrão. A sub-rede pública foi configurada para permitir o acesso controlado à internet, necessário para a instalação de software e comunicação das aplicações.
*   **Segurança (Security Group & Key Pair):**
    *   Implementamos um **firewall virtual (`aws_security_group`)** que segue o **princípio do menor privilégio**. O acesso administrativo (SSH, porta 22) foi restrito a um único endereço IP de desenvolvedor, enquanto apenas as portas das interfaces web (Metabase, Spark UI) foram expostas publicamente.
    *   Utilizamos um **par de chaves SSH (`aws_key_pair`)** para garantir a autenticação segura ao servidor, eliminando a necessidade de senhas.
*   **Computação (EC2 Instance):** Provisionamos uma máquina virtual (`aws_instance` do tipo `t2.micro`) para servir como nosso host de aplicação. A escolha do tipo de instância foi deliberadamente focada na otimização de custos, utilizando a camada gratuita da AWS para esta fase de validação.

---

#### **3. Resumo Técnico do Progresso e Desafios Superados**

Esta fase foi um exercício prático de depuração e resiliência, simulando desafios comuns em projetos de nuvem do mundo real:

1.  **Gerenciamento de Estado do Terraform:** Encontramos e resolvemos um conflito onde um recurso (a chave SSH) foi criado manualmente no console antes de ser gerenciado pelo Terraform. A solução foi aplicar o comando `terraform import`, uma técnica avançada que "adota" recursos existentes para o gerenciamento do IaC, garantindo uma única fonte de verdade.

2.  **Validação de API e Depuração de Formato:** Depuramos múltiplos erros retornados pela API da AWS, incluindo formatos de chave pública inválidos e IDs de AMI malformados. Isso reforçou a necessidade de rigor e atenção aos detalhes na escrita de código de infraestrutura.

3.  **Resolução de Conflitos de Arquitetura em Tempo Real:** O desafio mais significativo foi um erro indicando que o tipo de instância `t2.micro` não era suportado na Zona de Disponibilidade (AZ) escolhida aleatoriamente pela AWS. A solução foi tomar controle explícito da arquitetura, modificando nosso código Terraform para provisionar a sub-rede em uma AZ compatível (`us-west-2a`), demonstrando a capacidade de adaptar a infraestrutura a restrições do provedor de nuvem.

O resultado é uma infraestrutura **100% definida em código, estável e acessível**, com um servidor pronto para a implantação da nossa stack de aplicação.

---

#### **4. Próximos Passos (Fase 8: Implantação e Validação na Nuvem)**

Com o servidor provisionado e acessível, o foco agora se volta para a configuração final e validação do pipeline de ponta a ponta no ambiente de nuvem.

1.  **Configuração do Servidor (Ação Imediata):** Instalar as dependências necessárias no servidor EC2, incluindo Git, Docker e Docker Compose.
2.  **Implantação da Aplicação:** Clonar o repositório do projeto para o servidor e iniciar toda a stack de serviços (Kafka, Spark, ClickHouse, etc.) usando `docker-compose`.
3.  **Validação de Ponta a Ponta:** Executar o pipeline completo na nuvem e verificar se os dados fluem corretamente até o dashboard do Metabase, que agora estará acessível publicamente através do IP do servidor.
4.  **Desprovisionamento e Conclusão:** Após a validação, executar `terraform destroy` para desmontar toda a infraestrutura, demonstrando o ciclo de vida completo do IaC e garantindo o controle de custos.