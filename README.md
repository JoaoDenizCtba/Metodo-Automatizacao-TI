# Método Pessoal de Automação de Tarefas de TI

Este repositório documenta e disponibiliza um método modular e estruturado para automação de tarefas de TI em ambientes Windows, utilizando PowerShell, arquivos JSON e scripts especializados.

## Estrutura do Método

- **Separação por especialização**: cada script possui uma responsabilidade clara (ex: inventário, verificação de softwares, autenticação).
- **Matriz JSON**: centraliza informações de dispositivos, softwares obrigatórios e parâmetros.
- **Executor orquestrador**: um script principal que carrega a matriz e dispara os scripts especializados conforme necessidade.

## Objetivo

- Reduzir redundância e facilitar manutenção
- Permitir expansão modular e reutilização de código
- Otimizar o tempo do analista de infraestrutura

## Exemplos de Uso

- Autenticar máquina e verificar presença de softwares obrigatórios
- Gerar relatórios de conformidade com data e checklist
- Automatizar correções em endpoints via AD

## Autor

João Alberto R. Deniz Junior – Analista de Infraestrutura Sênior
