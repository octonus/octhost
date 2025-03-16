#!/bin/bash

# Script de Configuração OCP
# Versão: 3.0.0
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

# Definição de cores
VERMELHO='\033[0;31m'
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
MAGENTA='\033[0;35m'
CIANO='\033[0;36m'
BRANCO='\033[1;37m'
SEM_COR='\033[0m'

# Variáveis globais
DIR_TRABALHO=$(pwd)
ARQUIVO_LOG="${DIR_TRABALHO}/setup.log"
DIR_CONFIG="${DIR_TRABALHO}/config"
DIR_TEMP="${DIR_TRABALHO}/temp"
VERSAO="3.0.0"

# Tratamento de erros
set -euo pipefail
trap 'tratamento_erro $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# Verifica se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${VERMELHO}Este script precisa ser executado como root${SEM_COR}"
    exit 1
fi

# Funções
tratamento_erro() {
    local codigo_saida=$1
    local num_linha=$2
    local bash_lineno=$3
    local ultimo_comando=$4
    local rastreamento_func=$5
    
    echo -e "${VERMELHO}Erro ocorreu no script em:${SEM_COR}"
    echo "Código de saída: $codigo_saida"
    echo "Número da linha: $num_linha"
    echo "Comando: $ultimo_comando"
    echo "Rastreamento de função: $rastreamento_func"
    
    # Registra erro
    registrar_erro "Código: $codigo_saida, Linha: $num_linha, Comando: $ultimo_comando"
    
    limpeza
    exit $codigo_saida
}

registrar() {
    local msg=$1
    local nivel=${2:-INFO}
    local data_hora=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$data_hora] [$nivel] $msg" >> "$ARQUIVO_LOG"
}

registrar_erro() {
    registrar "$1" "ERRO"
}

registrar_info() {
    registrar "$1" "INFO"
}

limpeza() {
    registrar_info "Limpando arquivos temporários..."
    rm -rf "$DIR_TEMP"
}

verificar_dependencias() {
    local deps=("curl" "wget" "jq" "docker" "openssl")
    local faltando=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            faltando+=("$dep")
        fi
    done
    
    if [ ${#faltando[@]} -ne 0 ]; then
        echo -e "${VERMELHO}Dependências faltando: ${faltando[*]}${SEM_COR}"
        echo "Instalando dependências faltantes..."
        apt-get update && apt-get install -y "${faltando[@]}"
    fi
}

mostrar_banner() {
    clear
    echo -e "${AZUL}"
    cat << "EOF"
 ██████╗  ██████╗██████╗ 
██╔═══██╗██╔════╝██╔══██╗
██║   ██║██║     ██████╔╝
██║   ██║██║     ██╔═══╝ 
╚██████╔╝╚██████╗██║     
 ╚═════╝  ╚═════╝╚═╝     
EOF
    echo -e "${SEM_COR}"
    echo -e "${BRANCO}Script de Configuração OCP v${VERSAO}${SEM_COR}"
    echo -e "${BRANCO}========================================${SEM_COR}"
    echo -e "${BRANCO}Octonus Cloud Platform${SEM_COR}"
    echo -e "${BRANCO}https://octhost.com.br${SEM_COR}"
    echo -e "${BRANCO}========================================${SEM_COR}"
}

inicializar_diretorios() {
    mkdir -p "$DIR_CONFIG"
    mkdir -p "$DIR_TEMP"
    mkdir -p "$DIR_CONFIG/ssl"
    mkdir -p "$DIR_CONFIG/docker"
    mkdir -p "$DIR_CONFIG/apps"
    touch "$ARQUIVO_LOG"
    chmod 750 "$DIR_CONFIG"
    chmod 640 "$ARQUIVO_LOG"
    
    registrar_info "Estrutura de diretórios inicializada"
}

verificar_requisitos_sistema() {
    # Verifica CPU
    local nucleos_cpu=$(nproc)
    if [ "$nucleos_cpu" -lt 2 ]; then
        echo -e "${VERMELHO}Aviso: Sistema possui menos de 2 núcleos de CPU${SEM_COR}"
        registrar_erro "CPU insuficiente: $nucleos_cpu núcleos"
    fi
    
    # Verifica RAM
    local ram_total=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$ram_total" -lt 2048 ]; then
        echo -e "${VERMELHO}Aviso: Sistema possui menos de 2GB de RAM${SEM_COR}"
        registrar_erro "RAM insuficiente: $ram_total MB"
    fi
    
    # Verifica espaço em disco
    local espaco_livre=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$espaco_livre" -lt 10240 ]; then
        echo -e "${VERMELHO}Aviso: Menos de 10GB de espaço livre em disco${SEM_COR}"
        registrar_erro "Espaço em disco insuficiente: $espaco_livre MB"
    fi
}

carregar_modulos() {
    # Carrega módulos necessários
    source "$DIR_TRABALHO/modules/menu.sh"
    source "$DIR_TRABALHO/modules/utils.sh"
    source "$DIR_TRABALHO/modules/docker.sh"
    source "$DIR_TRABALHO/modules/apps.sh"
    source "$DIR_TRABALHO/modules/security.sh"
    source "$DIR_TRABALHO/modules/backup.sh"
    
    # Inicializa módulos
    inicializar_utils
    inicializar_apps
    inicializar_seguranca
    inicializar_backup_module
    
    registrar_info "Módulos carregados com sucesso"
}

verificar_atualizacoes() {
    registrar_info "Verificando atualizações..."
    # Implementar verificação de atualizações aqui
}

main() {
    mostrar_banner
    
    echo -e "${CIANO}Inicializando sistema...${SEM_COR}"
    inicializar_diretorios
    
    echo -e "${CIANO}Verificando dependências...${SEM_COR}"
    verificar_dependencias
    
    echo -e "${CIANO}Verificando requisitos do sistema...${SEM_COR}"
    verificar_requisitos_sistema
    
    echo -e "${CIANO}Carregando módulos...${SEM_COR}"
    carregar_modulos
    
    echo -e "${CIANO}Verificando atualizações...${SEM_COR}"
    verificar_atualizacoes
    
    # Inicia o menu principal
    mostrar_menu_principal
    
    limpeza
}

# Executa função principal
main "$@"
