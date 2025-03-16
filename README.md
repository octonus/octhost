# Script de Configuração OCP

Este é o script de configuração oficial da Octonus Cloud Platform (OCP), desenvolvido para automatizar a instalação e configuração de ambientes Docker com diversas aplicações e ferramentas.

## Sobre a OCP

A Octonus Cloud Platform (OCP) é uma solução completa para gerenciamento de infraestrutura em nuvem e containers.
- Website: [octhost.com.br](https://octhost.com.br)
- Suporte: [suporte@octhost.com.br](mailto:suporte@octhost.com.br)

## Requisitos do Sistema

- Sistema Operacional: Ubuntu/Debian
- CPU: Mínimo 2 cores
- RAM: Mínimo 2GB
- Espaço em Disco: Mínimo 10GB
- Acesso root/sudo

## Funcionalidades Principais

### 1. Configuração do Sistema
- Atualização do sistema
- Configuração de fuso horário
- Configuração de hostname
- Configuração de rede

### 2. Gerenciamento Docker
- Instalação automatizada do Docker
- Configuração otimizada do daemon
- Gerenciamento de contêineres
- Gerenciamento de redes
- Gerenciamento de volumes

### 3. Instalação de Aplicações
- Traefik (Proxy Reverso)
- Portainer (Gerenciamento Docker)
- Stack de Monitoramento (Prometheus + Grafana)
- Bancos de Dados (PostgreSQL, MySQL, Redis)
- Chatwoot
- N8N
- TypeBot

### 4. Configuração de Segurança
- Configuração de Firewall (UFW)
- Gerenciamento de SSL/TLS
- Auditoria de Segurança
- Gerenciamento de Senhas

### 5. Backup e Restauração
- Backup automatizado
- Restauração de dados
- Agendamento de backups
- Retenção configurável
- Notificações por email

## Instalação

1. Clone o repositório:
```bash
git clone https://github.com/octhost/ocp-setup.git
cd ocp-setup
```

2. Torne o script executável:
```bash
chmod +x setup.sh
```

3. Execute o script como root:
```bash
sudo ./setup.sh
```

## Estrutura de Diretórios

```
/
├── setup.sh           # Script principal
├── modules/           # Módulos do script
│   ├── menu.sh       # Interface do usuário
│   ├── utils.sh      # Funções utilitárias
│   ├── docker.sh     # Gerenciamento Docker
│   ├── apps.sh       # Instalação de aplicações
│   ├── security.sh   # Configurações de segurança
│   └── backup.sh     # Sistema de backup
├── config/           # Arquivos de configuração
│   ├── ssl/         # Certificados SSL
│   ├── docker/      # Configurações Docker
│   └── apps/        # Configurações das aplicações
└── README.md        # Documentação
```

## Configurações

### Diretórios Padrão
- Logs: `/var/log/ocp/`
- Backups: `/var/backups/ocp/`
- Configurações: `/etc/ocp/`

### Portas Utilizadas
- 80: HTTP
- 443: HTTPS
- 8080: Traefik Dashboard
- 9000: Portainer
- 9090: Prometheus
- 3000: Grafana

## Segurança

O script implementa as seguintes medidas de segurança:
- Firewall configurado com UFW
- SSL/TLS com Let's Encrypt
- Senhas geradas automaticamente
- Backup criptografado
- Logs seguros
- Permissões restritas em arquivos sensíveis

## Backup

O sistema de backup inclui:
- Backup completo do ambiente
- Backup dos volumes Docker
- Backup das configurações
- Agendamento personalizável
- Retenção configurável
- Notificações por email

## Suporte

Para suporte técnico ou dúvidas:
- Email: suporte@octhost.com.br
- Website: https://octhost.com.br
- Documentação: https://docs.octhost.com.br

## Licença

Este software é proprietário e seu uso é restrito aos termos estabelecidos pela Octonus Cloud Platform (OCP).

## Notas de Versão

### Versão 3.0.0
- Interface em português do Brasil
- Sistema modular completo
- Melhorias na segurança
- Backup automatizado
- Interface intuitiva
- Suporte a múltiplas aplicações
- Gerenciamento Docker aprimorado
- Sistema de logs detalhado
