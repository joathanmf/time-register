# Desafio Técnico - Desenvolvedor Ruby on Rails Pleno

## Visão Geral
Criar um projeto Ruby on Rails com o nome **"time-register"** (sistema de relógio de ponto) que demonstre conhecimentos em desenvolvimento de APIs RESTful, processamento assíncrono, containerização e documentação.

## Requisitos Técnicos
- Ruby on Rails (versão 6.0 ou superior)
- API-only application
- PostgreSQL como banco de dados
- Processamento de background jobs
- Docker para containerização
- **RSpec para testes** (obrigatório - toda funcionalidade deve ser testada)

---

## Desafio 1 - API RESTful para Relógio de Ponto

### Entidades
**User:**
- `id` (integer, primary key)
- `name` (string, required)
- `email` (string, required, unique)
- `created_at` / `updated_at`

**TimeRegister:**
- `id` (integer, primary key)
- `user_id` (integer, foreign key)
- `clock_in` (datetime, required)
- `clock_out` (datetime, optional)
- `created_at` / `updated_at`

### Endpoints Obrigatórios

#### Users
- `GET /api/v1/users` - Lista todos os usuários
- `GET /api/v1/users/:id` - Retorna um usuário específico
- `POST /api/v1/users` - Cria um novo usuário
- `PUT /api/v1/users/:id` - Atualiza um usuário
- `DELETE /api/v1/users/:id` - Remove um usuário
- `GET /api/v1/users/:id/time_registers` - Lista registros de ponto do usuário

#### Time Registers
- `GET /api/v1/time_registers` - Lista todos os registros de ponto
- `GET /api/v1/time_registers/:id` - Retorna um registro específico
- `POST /api/v1/time_registers` - Cria um novo registro de ponto
- `PUT /api/v1/time_registers/:id` - Atualiza um registro
- `DELETE /api/v1/time_registers/:id` - Remove um registro

### Validações Obrigatórias
- Usuário não pode ter mais de um registro de ponto "aberto" (sem clock_out)
- Clock_out deve ser posterior ao clock_in
- Validações de formato de email

### Testes Obrigatórios
- **Model specs:** Validações e associações
- **Request specs:** Todos os endpoints da API
- **Service/Job specs:** Processamento assíncrono
- **Integration specs:** Fluxos completos
- Cobertura mínima de 90%

---

## Desafio 2 - Processamento Assíncrono de Relatórios

### Funcionalidade
Implementar sistema de geração de relatórios de ponto em background usando Active Job.

### Endpoints Obrigatórios
- `POST /api/v1/users/:id/reports` - Solicita geração de relatório
  - Parâmetros: `start_date`, `end_date`
  - Resposta: `{ "process_id": "uuid", "status": "queued" }`

- `GET /api/v1/reports/:process_id/status` - Consulta status do processo
  - Resposta: `{ "process_id": "uuid", "status": "processing|completed|failed", "progress": 75 }`

- `GET /api/v1/reports/:process_id/download` - Download do relatório
  - Resposta: Arquivo CSV ou redirecionamento para URL temporária

### Requisitos Técnicos
- Usar Active Job com adapter de sua escolha 
- Gerar relatório em formato CSV
- Armazenar arquivos temporariamente
- Tratamento de erros adequado

---

## Desafio 3 - Population de Dados

### Funcionalidade
Implementar script para popular a aplicação com dados simulados para demonstração e testes.

### Requisitos Obrigatórios
- Criar aproximadamente **100 usuários** com dados realistas
- Gerar **20 registros de ponto** para cada usuário
- Dados devem simular cenários reais:
  - Horários comerciais (8h às 18h)
  - Intervalos de almoço
  - Variações de entrada/saída
  - Períodos de diferentes meses
- Script deve ser **idempotente** (pode ser executado múltiplas vezes)

---

## Desafio 4 - Documentação Completa

### README.md Obrigatório
Criar documentação completa incluindo:

#### Seções Obrigatórias:
1. **Título e Descrição** do projeto
2. **Pré-requisitos** (Ruby, Docker, etc.)
3. **Instalação e Setup**
   - Clone do repositório
   - Instalação de dependências
   - Setup do banco de dados
   - Configuração de variáveis de ambiente
4. **Como Executar**
   - Desenvolvimento local
   - Via Docker
   - Execução de testes
5. **Documentação da API**
   - Lista completa de endpoints
   - Exemplos de request/response
   - Códigos de status HTTP
6. **Arquitetura do Projeto**
   - Estrutura de pastas
   - Padrões utilizados
   - Decisões técnicas
7. **Testes**
   - Como executar
   - Cobertura
8. **Deploy** (instruções básicas)

---

## Desafio 5 - Containerização

### Docker Obrigatório
Containerizar a aplicação completa:

#### Arquivos Necessários:
- `Dockerfile` otimizado para produção
- `docker-compose.yml` para desenvolvimento
- `.dockerignore` adequado

#### Requisitos:
- **Multi-stage build** no Dockerfile
- Container da aplicação Rails
- Container PostgreSQL
- Network isolada entre containers
- Volumes persistentes para dados
- Healthchecks implementados
- Variáveis de ambiente configuráveis

#### Comandos que devem funcionar:
```bash
# Desenvolvimento
docker-compose up -d
docker-compose exec app rails db:create db:migrate
docker-compose exec app rspec
```

---