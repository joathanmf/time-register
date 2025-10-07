# Time Register

Sistema de relógio de ponto (API) desenvolvido como parte do teste técnico para a vaga de Ruby on Rails na Brobot.

## 📋 Índice

- [Descrição](#-descrição)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação e Setup](#-instalação-e-setup)
- [Como Executar](#-como-executar)
- [Documentação da API](#-documentação-da-api)
- [Arquitetura do Projeto](#-arquitetura-do-projeto)
- [Testes](#-testes)
- [Deploy](#-deploy)

## 📖 Descrição

Time Register é uma aplicação API-only desenvolvida em Ruby on Rails que gerencia registros de ponto de funcionários. O sistema permite o cadastro de usuários, registro de entrada e saída (clock in/clock out), além de geração assíncrona de relatórios em formato CSV.

### Principais Funcionalidades

- ✅ CRUD completo de usuários
- ✅ CRUD completo de registros de ponto (clockings)
- ✅ Validações de negócio (usuário não pode ter mais de um ponto aberto)
- ✅ Geração assíncrona de relatórios em CSV
- ✅ Acompanhamento do status de processamento de relatórios
- ✅ Download de relatórios gerados
- ✅ Sistema de filas com Sidekiq

## 🔧 Pré-requisitos

### Desenvolvimento Local (sem Docker)

- **Ruby** 3.4.2
- **PostgreSQL** 14 ou superior
- **Redis** 6 ou superior
- **Bundler**
- **Foreman** (para usar Procfile.dev)

### Desenvolvimento com Docker

- **Docker**
- **Docker Compose**

## 📦 Instalação e Setup

### 1. Clone do Repositório

```bash
git clone git@github.com:joathanmf/time-register.git
cd time-register
```

### 2. Instalação de Dependências

```bash
bundle install
```

### 3. Configuração de Variáveis de Ambiente

Copie o arquivo de exemplo e configure as variáveis:

```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas configurações locais (para desenvolvimento local sem Docker):

```env
# Rails environment
RAILS_ENV=development

# Database configuration
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=time_register_development

DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=time_register_development

# Redis configuration
REDIS_URL=redis://localhost:6379/0

# Rails configuration
RAILS_MAX_THREADS=5

# Production only
RAILS_MASTER_KEY=
SECRET_KEY_BASE=
```

### 4. Setup do Banco de Dados

#### Desenvolvimento Local

```bash
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed  # Opcional: popula com dados de exemplo
```

#### Com Docker

```bash
# Inicie os containers
docker-compose up -d

# Execute as migrações
docker-compose exec app rails db:create
docker-compose exec app rails db:migrate
docker-compose exec app rails db:seed  # Opcional
```

## 🚀 Como Executar

### Desenvolvimento Local com Procfile.dev

O projeto utiliza Foreman para gerenciar múltiplos processos (Rails server + Sidekiq):

```bash
# Execute todos os serviços
bin/dev
```

Isso iniciará:
- **Rails Server** na porta 3000
- **Sidekiq Worker** para processamento de jobs

A aplicação estará disponível em: `http://localhost:3000`

### Desenvolvimento com Docker Compose

```bash
# Inicie todos os containers (desenvolvimento)
docker-compose up -d

# Visualize os logs
docker-compose logs -f

# Visualize logs de um serviço específico
docker-compose logs -f app
docker-compose logs -f sidekiq

# Pare os containers
docker-compose down
```

A aplicação estará disponível em: `http://localhost:3000`

### Produção com Docker Compose

```bash
# Configurar variáveis de ambiente para produção
cp .env.example .env
# Edite .env com suas credenciais reais (RAILS_MASTER_KEY, SECRET_KEY_BASE, etc.)

# Inicie todos os containers (produção)
docker-compose -f docker-compose.production.yml up -d

# Visualize os logs
docker-compose -f docker-compose.production.yml logs -f

# Pare os containers
docker-compose -f docker-compose.production.yml down
```

### Executar Comandos no Container

```bash
# Rails console
docker-compose exec app rails console

# Executar migrações
docker-compose exec app rails db:migrate

# Executar seeds
docker-compose exec app rails db:seed

# Executar testes
docker-compose exec app rspec

# Bash no container
docker-compose exec app bash
```

## 📚 Documentação da API

### Base URL

```
http://localhost:3000/api/v1
```

### Endpoints

#### 👤 Users

##### Listar todos os usuários
```http
GET /api/v1/users
```

**Resposta (200 OK):**
```json
[
  {
    "id": 1,
    "name": "João Silva",
    "email": "joao@example.com",
    "created_at": "2025-10-06T10:00:00.000Z",
    "updated_at": "2025-10-06T10:00:00.000Z"
  }
]
```

##### Buscar um usuário
```http
GET /api/v1/users/:id
```

**Resposta (200 OK):**
```json
{
  "id": 1,
  "name": "João Silva",
  "email": "joao@example.com",
  "created_at": "2025-10-06T10:00:00.000Z",
  "updated_at": "2025-10-06T10:00:00.000Z"
}
```

**Resposta (404 Not Found):**
```json
{
  "error": "User not found"
}
```

##### Criar um usuário
```http
POST /api/v1/users
Content-Type: application/json
```

**Request Body:**
```json
{
  "user": {
    "name": "Maria Santos",
    "email": "maria@example.com"
  }
}
```

**Resposta (201 Created):**
```json
{
  "id": 2,
  "name": "Maria Santos",
  "email": "maria@example.com",
  "created_at": "2025-10-06T10:15:00.000Z",
  "updated_at": "2025-10-06T10:15:00.000Z"
}
```

**Resposta (422 Unprocessable Entity):**
```json
{
  "errors": [
    "Email has already been taken",
    "Name can't be blank"
  ]
}
```

##### Atualizar um usuário
```http
PUT /api/v1/users/:id
Content-Type: application/json
```

**Request Body:**
```json
{
  "user": {
    "name": "Maria Santos Silva"
  }
}
```

**Resposta (200 OK):**
```json
{
  "id": 2,
  "name": "Maria Santos Silva",
  "email": "maria@example.com",
  "created_at": "2025-10-06T10:15:00.000Z",
  "updated_at": "2025-10-06T10:20:00.000Z"
}
```

##### Deletar um usuário
```http
DELETE /api/v1/users/:id
```

**Resposta (204 No Content)**

##### Listar registros de ponto de um usuário
```http
GET /api/v1/users/:id/time_registers
```

**Resposta (200 OK):**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "clock_in": "2025-10-06T08:00:00.000Z",
    "clock_out": "2025-10-06T17:00:00.000Z",
    "created_at": "2025-10-06T08:00:00.000Z",
    "updated_at": "2025-10-06T17:00:00.000Z"
  }
]
```

#### ⏰ Time Registers

##### Listar todos os registros de ponto
```http
GET /api/v1/time_registers
```

**Resposta (200 OK):**
```json
[
  {
    "id": 1,
    "user_id": 1,
    "clock_in": "2025-10-06T08:00:00.000Z",
    "clock_out": "2025-10-06T17:00:00.000Z",
    "created_at": "2025-10-06T08:00:00.000Z",
    "updated_at": "2025-10-06T17:00:00.000Z"
  }
]
```

##### Buscar um registro de ponto
```http
GET /api/v1/time_registers/:id
```

**Resposta (200 OK):**
```json
{
  "id": 1,
  "user_id": 1,
  "clock_in": "2025-10-06T08:00:00.000Z",
  "clock_out": "2025-10-06T17:00:00.000Z",
  "created_at": "2025-10-06T08:00:00.000Z",
  "updated_at": "2025-10-06T17:00:00.000Z"
}
```

##### Criar um registro de ponto
```http
POST /api/v1/time_registers
Content-Type: application/json
```

**Request Body:**
```json
{
  "time_register": {
    "user_id": 1,
    "clock_in": "2025-10-06T08:00:00.000Z",
    "clock_out": null
  }
}
```

**Resposta (201 Created):**
```json
{
  "id": 2,
  "user_id": 1,
  "clock_in": "2025-10-06T08:00:00.000Z",
  "clock_out": null,
  "created_at": "2025-10-06T08:00:00.000Z",
  "updated_at": "2025-10-06T08:00:00.000Z"
}
```

**Resposta (422 Unprocessable Entity):**
```json
{
  "errors": [
    "User already has an open clocking",
    "Clock out must be after clock in"
  ]
}
```

##### Atualizar um registro de ponto
```http
PUT /api/v1/time_registers/:id
Content-Type: application/json
```

**Request Body:**
```json
{
  "time_register": {
    "clock_out": "2025-10-06T17:00:00.000Z"
  }
}
```

**Resposta (200 OK):**
```json
{
  "id": 2,
  "user_id": 1,
  "clock_in": "2025-10-06T08:00:00.000Z",
  "clock_out": "2025-10-06T17:00:00.000Z",
  "created_at": "2025-10-06T08:00:00.000Z",
  "updated_at": "2025-10-06T17:00:00.000Z"
}
```

##### Deletar um registro de ponto
```http
DELETE /api/v1/time_registers/:id
```

**Resposta (204 No Content)**

#### 📊 Reports

##### Solicitar geração de relatório
```http
POST /api/v1/users/:id/reports
Content-Type: application/json
```

**Request Body:**
```json
{
  "start_date": "2025-10-01",
  "end_date": "2025-10-31"
}
```

**Resposta (201 Created):**
```json
{
  "process_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "queued"
}
```

##### Consultar status do relatório
```http
GET /api/v1/reports/:process_id/status
```

**Resposta (200 OK):**
```json
{
  "process_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "progress": 100
}
```

**Status possíveis:**
- `queued` - Relatório na fila
- `processing` - Relatório sendo processado
- `completed` - Relatório pronto para download
- `failed` - Erro no processamento

##### Download do relatório
```http
GET /api/v1/reports/:process_id/download
```

**Resposta (200 OK):**
- Content-Type: `text/csv`

**Resposta (422 Unprocessable Entity):**
```json
{
  "error": "Report not ready. Status: processing"
}
```

**Resposta (404 Not Found):**
```json
{
  "error": "Report not found"
}
```

### Códigos de Status HTTP

| Código | Descrição |
|--------|-----------|
| 200 | OK - Requisição bem-sucedida |
| 201 | Created - Recurso criado com sucesso |
| 204 | No Content - Requisição bem-sucedida sem conteúdo de retorno |
| 404 | Not Found - Recurso não encontrado |
| 422 | Unprocessable Entity - Erro de validação |
| 500 | Internal Server Error - Erro interno do servidor |

## 🏗️ Arquitetura do Projeto

### Estrutura de Pastas

O projeto segue a estrutura padrão do Ruby on Rails com ênfase em Services para lógica de negócio:

```
app/
├── controllers/
│   └── api/
│       └── v1/              # Controllers versionados da API
│           ├── users_controller.rb
│           ├── time_registers_controller.rb
│           └── reports_controller.rb
├── jobs/
│   └── reports/             # Background jobs
│       └── generate_job.rb
├── models/
│   ├── user.rb
│   ├── clocking.rb          # TimeRegister foi renomeado para Clocking
│   └── report_process.rb
└── services/
    └── reports/             # Serviços de geração de relatórios
        ├── base_report.rb   # Template Method
        ├── csv_report.rb    # Strategy
        ├── create_service.rb
        ├── report_factory.rb # Factory
        ├── builders/
        │   └── csv_builder.rb # Builder
        ├── calculators/    # Cálculos auxiliares
        └── formatters/     # Formatação de dados
```

### Design Patterns Utilizados

#### 1. **Template Method Pattern** (`base_report.rb`)
Define o esqueleto do algoritmo de geração de relatórios, permitindo que subclasses sobrescrevam etapas específicas.

```ruby
# Classe base define o fluxo
class BaseReport
  def generate
    report_process.mark_as_processing!
    content = build_content          # Método abstrato
    attach_file(content)
    report_process.reload
  end
  
  def build_content
    raise NotImplementedError
  end
end
```

#### 2. **Strategy Pattern** (`csv_report.rb`)
Encapsula diferentes estratégias de geração de relatórios (CSV, PDF, etc.).

```ruby
class CsvReport < BaseReport
  def build_content
    # Implementação específica para CSV
  end
end
```

#### 3. **Builder Pattern** (`csv_builder.rb`)
Constrói objetos complexos passo a passo (construção do CSV).

```ruby
class CsvBuilder
  def build_header
    # Constrói cabeçalho
  end
  
  def build_body(data)
    # Constrói corpo
  end
end
```

#### 4. **Factory Pattern** (`report_factory.rb`)
Cria instâncias de diferentes tipos de relatórios baseado em parâmetros.

```ruby
class ReportFactory
  def self.create(type:, report_process:)
    case type
    when :csv
      CsvReport.new(report_process)
    # Outros tipos...
    end
  end
end
```

### Decisões Técnicas

#### 1. **Clocking vs TimeRegister**
Optei por usar `Clocking` ao invés de `TimeRegister` porque `TimeRegister` já faz parte do namespace do Rails e poderia conflitar com funcionalidades internas do framework.

#### 2. **Serialização JSON Nativa**
Utilizo o serializador JSON nativo do Rails por se tratar de uma aplicação mais simples. Em um cenário de produção com necessidades mais complexas, utilizaria gems como **Alba** (com OJ) ou **Blueprinter** para ter mais controle sobre a serialização.

#### 3. **Foreman e Procfile.dev**
Embora o Docker Compose seja usado conforme solicitado, optei por também disponibilizar o Foreman com `Procfile.dev` para agilizar o desenvolvimento local, já que é uma ferramenta que utilizo no dia a dia e permite iniciar rapidamente todos os serviços necessários.

#### 4. **Refatoração para Design Patterns**
Inicialmente, concentrei toda a lógica de geração de relatórios em um único serviço devido ao tempo. Porém, refatorei aplicando Design Patterns e princípios SOLID para:
- **Single Responsibility:** Cada classe tem uma responsabilidade única
- **Open/Closed:** Fácil extensão sem modificar código existente
- **Dependency Inversion:** Depende de abstrações, não de implementações concretas
- Melhor manutenabilidade e facilidade de expansão

#### 5. **Sidekiq como Adapter**
Escolhi o **Sidekiq** como adapter para ActiveJob por ser amplamente utilizado na comunidade Ruby, ter excelente performance e ser familiar tanto para mim quanto para a maioria dos desenvolvedores Rails.

#### 6. **Rails 7.2**
Utilizei Rails 7.2.2.2 pela maior familiaridade e por ser a versão que mais utilizo no dia a dia, além de contar com todas as features modernas do framework.

#### 7. **Claude Sonnet 4.5 como Assistente**
Utilizei IA (Claude Sonnet 4.5) para auxiliar em tarefas repetitivas e para brainstorming de ideias, permitindo focar na lógica de negócio e arquitetura.

### Princípios SOLID Aplicados

- **S**ingle Responsibility: Cada service tem uma responsabilidade específica
- **O**pen/Closed: Fácil adicionar novos tipos de relatórios sem modificar código existente
- **L**iskov Substitution: Subclasses de BaseReport são intercambiáveis
- **I**nterface Segregation: Interfaces coesas e específicas
- **D**ependency Inversion: Controllers dependem de abstrações (Services)

## 🧪 Testes

### Estrutura de Testes

```
spec/
├── models/                   # Testes de modelo (validações, associações)
│   ├── user_spec.rb
│   ├── clocking_spec.rb
│   └── report_process_spec.rb
├── requests/                 # Testes de endpoints da API
│   └── api/v1/
│       ├── users_spec.rb
│       ├── time_registers_spec.rb
│       └── reports_spec.rb
├── services/                 # Testes de services
│   └── reports/
│       ├── builders/
│       │   └── csv_builder_spec.rb
│       ├── calculators/
│       │   └── work_time_calculator_spec.rb
│       ├── formatters/
│       │   └── date_time_formatter_spec.rb
│       ├── create_service_spec.rb
│       ├── base_report_spec.rb
│       ├── csv_report_spec.rb
│       └── report_factory_spec.rb
├── jobs/                     # Testes de background jobs
│   └── reports/
│       └── generate_job_spec.rb
├── integration/              # Testes de fluxo completo
│   ├── user_management_flow_spec.rb
│   ├── time_register_flow_spec.rb
│   ├── report_generation_flow_spec.rb
│   └── work_day_simulation_spec.rb
└── factories/                # Factories do FactoryBot
    ├── users.rb
    ├── clockings.rb
    └── report_processes.rb
```

### Como Executar os Testes

#### Todos os testes
```bash
# Desenvolvimento local
bundle exec rspec

# Com Docker
docker-compose exec app rspec
```

#### Testes específicos
```bash
# Testar apenas models
bundle exec rspec spec/models

# Testar apenas requests
bundle exec rspec spec/requests

# Testar um arquivo específico
bundle exec rspec spec/models/user_spec.rb
```

#### Com formato de documentação
```bash
bundle exec rspec --format documentation
```

### Cobertura de Testes

O projeto conta com cobertura de testes em:

- ✅ **Model specs:** Validações, associações e métodos de modelo
- ✅ **Request specs:** Todos os endpoints da API (Users, TimeRegisters, Reports)
- ✅ **Service specs:** Lógica de negócio em services
- ✅ **Job specs:** Processamento assíncrono de relatórios
- ✅ **Integration specs:** Fluxos completos end-to-end
  - Gerenciamento de usuários
  - Registro de ponto
  - Geração de relatórios
  - Simulação de dia de trabalho

**Meta de cobertura:** 90%+ (conforme especificado no desafio)

### Ferramentas de Teste

- **RSpec:** Framework de testes
- **FactoryBot:** Criação de dados para testes
- **Faker:** Geração de dados fake realistas
- **Shoulda Matchers:** Matchers para validações e associações Rails

## 🚢 Deploy (TODO)

## 📝 Licença

Este projeto foi desenvolvido como parte de um teste técnico para a Brobot.

## 🙏 Agradecimentos

- Brobot pela oportunidade
