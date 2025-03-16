#!/bin/bash

# Script de Verificação e Diagnóstico OCP
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

# Variáveis
VERSAO_MINIMA_DOCKER="20.10.0"
DIR_BASE="/etc/ocp"
ARQUIVO_LOG="/var/log/ocp/check-$(date +%Y%m%d).log"

# Função para registrar no log
registrar() {
    local nivel=$1
    local mensagem=$2
    local data_hora=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$data_hora] [$nivel] $mensagem" >> "$ARQUIVO_LOG"
}

# Função para exibir status
mostrar_status() {
    local teste=$1
    local status=$2
    printf "${BRANCO}%-50s${SEM_COR}" "$teste"
    case $status in
        "OK") echo -e "${VERDE}[OK]${SEM_COR}" ;;
        "FALHA") echo -e "${VERMELHO}[FALHA]${SEM_COR}" ;;
        "AVISO") echo -e "${AMARELO}[AVISO]${SEM_COR}" ;;
    esac
}

# Verifica requisitos do sistema
verificar_sistema() {
    echo -e "\n${AZUL}=== Verificando Requisitos do Sistema ===${SEM_COR}"
    
    # CPU
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        mostrar_status "Núcleos de CPU ($cpu_cores)" "AVISO"
        registrar "AVISO" "Sistema possui apenas $cpu_cores núcleos de CPU"
    else
        mostrar_status "Núcleos de CPU ($cpu_cores)" "OK"
    fi
    
    # Memória
    local memoria_total=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$memoria_total" -lt 2048 ]; then
        mostrar_status "Memória RAM (${memoria_total}MB)" "AVISO"
        registrar "AVISO" "Sistema possui apenas ${memoria_total}MB de RAM"
    else
        mostrar_status "Memória RAM (${memoria_total}MB)" "OK"
    fi
    
    # Espaço em disco
    local disco_livre=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$disco_livre" -lt 10240 ]; then
        mostrar_status "Espaço em Disco (${disco_livre}MB)" "AVISO"
        registrar "AVISO" "Sistema possui apenas ${disco_livre}MB de espaço livre"
    else
        mostrar_status "Espaço em Disco (${disco_livre}MB)" "OK"
    fi
}

# Verifica instalação do Docker
verificar_docker() {
    echo -e "\n${AZUL}=== Verificando Docker ===${SEM_COR}"
    
    # Verifica se Docker está instalado
    if ! command -v docker &> /dev/null; then
        mostrar_status "Docker Instalado" "FALHA"
        registrar "ERRO" "Docker não está instalado"
        return 1
    fi
    mostrar_status "Docker Instalado" "OK"
    
    # Verifica versão do Docker
    local versao_docker=$(docker --version | awk '{print $3}' | sed 's/,//')
    if ! [[ "$(printf '%s\n' "$VERSAO_MINIMA_DOCKER" "$versao_docker" | sort -V | head -n1)" = "$VERSAO_MINIMA_DOCKER" ]]; then
        mostrar_status "Versão do Docker ($versao_docker)" "AVISO"
        registrar "AVISO" "Versão do Docker ($versao_docker) é menor que a recomendada ($VERSAO_MINIMA_DOCKER)"
    else
        mostrar_status "Versão do Docker ($versao_docker)" "OK"
    fi
    
    # Verifica status do serviço Docker
    if ! systemctl is-active --quiet docker; then
        mostrar_status "Serviço Docker" "FALHA"
        registrar "ERRO" "Serviço Docker não está em execução"
    else
        mostrar_status "Serviço Docker" "OK"
    fi
    
    # Verifica rede proxy
    if ! docker network ls | grep -q "proxy"; then
        mostrar_status "Rede Docker 'proxy'" "FALHA"
        registrar "ERRO" "Rede Docker 'proxy' não encontrada"
    else
        mostrar_status "Rede Docker 'proxy'" "OK"
    fi
}

# Verifica diretórios e permissões
verificar_diretorios() {
    echo -e "\n${AZUL}=== Verificando Diretórios e Permissões ===${SEM_COR}"
    
    local diretorios=(
        "/etc/ocp"
        "/var/log/ocp"
        "/var/backups/ocp"
        "/etc/ocp/ssl"
        "/etc/ocp/docker"
        "/etc/ocp/apps"
    )
    
    for dir in "${diretorios[@]}"; do
        if [ ! -d "$dir" ]; then
            mostrar_status "Diretório $dir" "FALHA"
            registrar "ERRO" "Diretório $dir não encontrado"
        else
            local perms=$(stat -c "%a" "$dir")
            if [ "$perms" != "750" ]; then
                mostrar_status "Permissões $dir ($perms)" "AVISO"
                registrar "AVISO" "Permissões incorretas em $dir: $perms (deveria ser 750)"
            else
                mostrar_status "Diretório $dir" "OK"
            fi
        fi
    done
}

# Verifica serviços em execução
verificar_servicos() {
    echo -e "\n${AZUL}=== Verificando Serviços ===${SEM_COR}"
    
    # Verifica Traefik
    if docker ps | grep -q "traefik"; then
        mostrar_status "Traefik" "OK"
    else
        mostrar_status "Traefik" "FALHA"
        registrar "ERRO" "Serviço Traefik não está em execução"
    fi
    
    # Verifica Portainer
    if docker ps | grep -q "portainer"; then
        mostrar_status "Portainer" "OK"
    else
        mostrar_status "Portainer" "FALHA"
        registrar "ERRO" "Serviço Portainer não está em execução"
    fi
}

# Verifica configurações de segurança
verificar_seguranca() {
    echo -e "\n${AZUL}=== Verificando Configurações de Segurança ===${SEM_COR}"
    
    # Verifica UFW
    if ! command -v ufw &> /dev/null; then
        mostrar_status "Firewall (UFW)" "FALHA"
        registrar "ERRO" "UFW não está instalado"
    else
        if ! ufw status | grep -q "active"; then
            mostrar_status "Firewall (UFW)" "AVISO"
            registrar "AVISO" "UFW está instalado mas não está ativo"
        else
            mostrar_status "Firewall (UFW)" "OK"
        fi
    fi
    
    # Verifica SSL
    if [ ! -d "$DIR_BASE/ssl" ] || [ -z "$(ls -A $DIR_BASE/ssl)" ]; then
        mostrar_status "Certificados SSL" "AVISO"
        registrar "AVISO" "Nenhum certificado SSL encontrado"
    else
        mostrar_status "Certificados SSL" "OK"
    fi
}

# Verifica configuração de backup
verificar_backup() {
    echo -e "\n${AZUL}=== Verificando Sistema de Backup ===${SEM_COR}"
    
    # Verifica diretório de backup
    if [ ! -d "/var/backups/ocp" ]; then
        mostrar_status "Diretório de Backup" "FALHA"
        registrar "ERRO" "Diretório de backup não encontrado"
    else
        mostrar_status "Diretório de Backup" "OK"
    fi
    
    # Verifica backups recentes
    local ultimo_backup=$(find /var/backups/ocp -type f -name "backup_*.tar.gz" -mtime -7 | wc -l)
    if [ "$ultimo_backup" -eq 0 ]; then
        mostrar_status "Backups Recentes" "AVISO"
        registrar "AVISO" "Nenhum backup encontrado nos últimos 7 dias"
    else
        mostrar_status "Backups Recentes ($ultimo_backup)" "OK"
    fi
}

# Função principal
main() {
    # Cria diretório de log se não existir
    mkdir -p "$(dirname "$ARQUIVO_LOG")"
    
    echo -e "${BRANCO}Iniciando verificação do sistema OCP...${SEM_COR}"
    registrar "INFO" "Iniciando verificação do sistema"
    
    verificar_sistema
    verificar_docker
    verificar_diretorios
    verificar_servicos
    verificar_seguranca
    verificar_backup
    
    echo -e "\n${BRANCO}Verificação concluída. Log salvo em: $ARQUIVO_LOG${SEM_COR}"
    
    # Verifica se houve erros ou avisos
    if grep -q "ERRO" "$ARQUIVO_LOG"; then
        echo -e "\n${VERMELHO}Foram encontrados ERROS durante a verificação.${SEM_COR}"
        echo -e "${VERMELHO}Por favor, revise o arquivo de log para mais detalhes.${SEM_COR}"
    elif grep -q "AVISO" "$ARQUIVO_LOG"; then
        echo -e "\n${AMARELO}Foram encontrados AVISOS durante a verificação.${SEM_COR}"
        echo -e "${AMARELO}Por favor, revise o arquivo de log para mais detalhes.${SEM_COR}"
    else
        echo -e "\n${VERDE}Todos os testes foram concluídos com sucesso!${SEM_COR}"
    fi
}

# Executa função principal
main "$@"
