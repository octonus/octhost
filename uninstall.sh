#!/bin/bash

# Script de Desinstalação OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

# Cores
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
CIANO='\033[0;36m'
BRANCO='\033[1;37m'
SEM_COR='\033[0m'

# Verifica se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${VERMELHO}Este script precisa ser executado como root${SEM_COR}"
    exit 1
fi

# Função para confirmar ação
confirmar() {
    local mensagem=$1
    local resposta
    
    echo -e "${AMARELO}$mensagem${SEM_COR}"
    read -p "Digite 'sim' para confirmar: " resposta
    
    if [[ "${resposta,,}" != "sim" ]]; then
        echo -e "${VERMELHO}Operação cancelada pelo usuário${SEM_COR}"
        exit 1
    fi
}

# Função para exibir progresso
mostrar_progresso() {
    local descricao=$1
    echo -ne "${CIANO}$descricao...${SEM_COR}"
}

# Função para confirmar conclusão
confirmar_conclusao() {
    echo -e "${VERDE} Concluído!${SEM_COR}"
}

# Função para backup dos dados
fazer_backup() {
    local dir_backup="/var/backups/ocp/uninstall_$(date +%Y%m%d_%H%M%S)"
    
    mostrar_progresso "Criando backup dos dados"
    mkdir -p "$dir_backup"
    
    # Backup das configurações
    if [ -d "/etc/ocp" ]; then
        tar -czf "$dir_backup/config.tar.gz" /etc/ocp
    fi
    
    # Backup dos logs
    if [ -d "/var/log/ocp" ]; then
        tar -czf "$dir_backup/logs.tar.gz" /var/log/ocp
    fi
    
    # Backup dos volumes Docker
    if command -v docker &> /dev/null; then
        mkdir -p "$dir_backup/volumes"
        for volume in $(docker volume ls -q | grep "ocp"); do
            docker run --rm -v $volume:/source:ro -v "$dir_backup/volumes":/backup alpine tar -czf "/backup/${volume}.tar.gz" -C /source .
        done
    fi
    
    confirmar_conclusao
    echo -e "${BRANCO}Backup salvo em: $dir_backup${SEM_COR}"
}

# Função para parar e remover contêineres
remover_conteineres() {
    mostrar_progresso "Parando contêineres"
    docker ps -a --format '{{.Names}}' | grep "ocp" | xargs -r docker stop
    confirmar_conclusao
    
    mostrar_progresso "Removendo contêineres"
    docker ps -a --format '{{.Names}}' | grep "ocp" | xargs -r docker rm -f
    confirmar_conclusao
}

# Função para remover volumes
remover_volumes() {
    mostrar_progresso "Removendo volumes Docker"
    docker volume ls -q | grep "ocp" | xargs -r docker volume rm
    confirmar_conclusao
}

# Função para remover redes
remover_redes() {
    mostrar_progresso "Removendo redes Docker"
    docker network ls --format '{{.Name}}' | grep "ocp\|proxy" | xargs -r docker network rm
    confirmar_conclusao
}

# Função para remover arquivos
remover_arquivos() {
    mostrar_progresso "Removendo arquivos de configuração"
    rm -rf /etc/ocp
    confirmar_conclusao
    
    mostrar_progresso "Removendo logs"
    rm -rf /var/log/ocp
    confirmar_conclusao
    
    mostrar_progresso "Removendo scripts"
    rm -f /usr/local/bin/ocp
    rm -rf /opt/ocp
    confirmar_conclusao
}

# Função para remover cron jobs
remover_cron() {
    mostrar_progresso "Removendo tarefas agendadas"
    crontab -l | grep -v "ocp" | crontab -
    confirmar_conclusao
}

# Função para limpar regras de firewall
limpar_firewall() {
    if command -v ufw &> /dev/null; then
        mostrar_progresso "Removendo regras do firewall"
        # Remove regras específicas do OCP
        ufw delete allow 80/tcp
        ufw delete allow 443/tcp
        ufw delete allow 8080/tcp
        confirmar_conclusao
    fi
}

# Função principal
main() {
    echo -e "${BRANCO}Script de Desinstalação OCP${SEM_COR}"
    echo -e "${BRANCO}========================================${SEM_COR}"
    
    # Confirmação inicial
    confirmar "ATENÇÃO: Este script irá remover completamente o OCP e todos os seus dados. Esta ação não pode ser desfeita."
    
    # Pergunta sobre backup
    echo -e "\n${AMARELO}Deseja criar um backup antes de prosseguir? (Recomendado) [S/n]${SEM_COR}"
    read -r resposta
    if [[ ! "${resposta,,}" =~ ^n ]]; then
        fazer_backup
    fi
    
    echo -e "\n${BRANCO}Iniciando processo de desinstalação...${SEM_COR}"
    
    # Remove componentes
    remover_conteineres
    remover_volumes
    remover_redes
    remover_cron
    limpar_firewall
    remover_arquivos
    
    echo -e "\n${VERDE}Desinstalação concluída com sucesso!${SEM_COR}"
    
    # Mensagem sobre backup
    if [ -d "/var/backups/ocp" ]; then
        echo -e "\n${AMARELO}NOTA: Os backups anteriores foram mantidos em /var/backups/ocp${SEM_COR}"
        echo -e "${AMARELO}Você pode removê-los manualmente se desejar.${SEM_COR}"
    fi
    
    # Pergunta sobre remoção do Docker
    echo -e "\n${AMARELO}Deseja remover o Docker também? [s/N]${SEM_COR}"
    read -r resposta
    if [[ "${resposta,,}" =~ ^s ]]; then
        mostrar_progresso "Removendo Docker"
        apt-get remove --purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        apt-get autoremove -y
        rm -rf /var/lib/docker
        confirmar_conclusao
    fi
    
    echo -e "\n${BRANCO}Obrigado por usar OCP!${SEM_COR}"
    echo -e "${BRANCO}Para suporte: suporte@octhost.com.br${SEM_COR}"
    echo -e "${BRANCO}Website: https://octhost.com.br${SEM_COR}"
}

# Executa função principal
main "$@"
