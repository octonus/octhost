#!/bin/bash

# Módulo de Utilitários para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

# Funções de registro (logging)
configurar_logs() {
    local dir_log="/var/log/ocp"
    mkdir -p "$dir_log"
    ARQUIVO_LOG="$dir_log/setup-$(date +%Y%m%d).log"
    touch "$ARQUIVO_LOG"
    chmod 640 "$ARQUIVO_LOG"
}

registrar_mensagem() {
    local nivel=$1
    local mensagem=$2
    local data_hora=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$data_hora] [$nivel] $mensagem" >> "$ARQUIVO_LOG"
    
    # Exibe no console se não estiver em modo silencioso
    if [[ "${MODO_SILENCIOSO:-false}" != "true" ]]; then
        case $nivel in
            "ERRO") echo -e "${VERMELHO}[$nivel] $mensagem${SEM_COR}" ;;
            "AVISO") echo -e "${AMARELO}[$nivel] $mensagem${SEM_COR}" ;;
            "SUCESSO") echo -e "${VERDE}[$nivel] $mensagem${SEM_COR}" ;;
            *) echo -e "[$nivel] $mensagem" ;;
        esac
    fi
}

# Funções de validação
validar_dominio() {
    local dominio=$1
    if [[ ! $dominio =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        registrar_mensagem "ERRO" "Formato de domínio inválido: $dominio"
        return 1
    fi
    return 0
}

validar_email() {
    local email=$1
    if [[ ! $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        registrar_mensagem "ERRO" "Formato de e-mail inválido: $email"
        return 1
    fi
    return 0
}

validar_ip() {
    local ip=$1
    if [[ ! $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        registrar_mensagem "ERRO" "Formato de IP inválido: $ip"
        return 1
    fi
    
    # Valida cada octeto
    local IFS='.'
    read -ra ADDR <<< "$ip"
    for i in "${ADDR[@]}"; do
        if [ $i -lt 0 ] || [ $i -gt 255 ]; then
            registrar_mensagem "ERRO" "Octeto de IP fora do intervalo: $i"
            return 1
        fi
    done
    return 0
}

# Funções de verificação do sistema
verificar_requisitos_sistema() {
    local min_ram=2048  # 2GB
    local min_cpu=2
    local min_disco=10240  # 10GB
    
    # Verifica RAM
    local ram_total=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$ram_total" -lt "$min_ram" ]; then
        registrar_mensagem "AVISO" "Sistema possui menos que ${min_ram}MB de RAM (Atual: ${ram_total}MB)"
        return 1
    fi
    
    # Verifica CPU
    local nucleos_cpu=$(nproc)
    if [ "$nucleos_cpu" -lt "$min_cpu" ]; then
        registrar_mensagem "AVISO" "Sistema possui menos que ${min_cpu} núcleos de CPU (Atual: ${nucleos_cpu})"
        return 1
    fi
    
    # Verifica Espaço em Disco
    local espaco_livre=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$espaco_livre" -lt "$min_disco" ]; then
        registrar_mensagem "AVISO" "Sistema possui menos que ${min_disco}MB de espaço livre (Atual: ${espaco_livre}MB)"
        return 1
    fi
    
    return 0
}

verificar_dependencias() {
    local deps=("curl" "wget" "jq" "openssl" "git")
    local faltando=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            faltando+=("$dep")
        fi
    done
    
    if [ ${#faltando[@]} -ne 0 ]; then
        registrar_mensagem "AVISO" "Dependências faltando: ${faltando[*]}"
        return 1
    fi
    
    return 0
}

# Funções de segurança
gerar_senha_segura() {
    local tamanho=${1:-32}
    local senha=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9@#$%^&*()_+' | head -c "$tamanho")
    echo "$senha"
}

criptografar_string() {
    local string=$1
    local chave=$2
    echo "$string" | openssl enc -aes-256-cbc -a -salt -pass pass:"$chave"
}

descriptografar_string() {
    local criptografado=$1
    local chave=$2
    echo "$criptografado" | openssl enc -aes-256-cbc -a -d -salt -pass pass:"$chave"
}

# Funções de rede
verificar_porta_disponivel() {
    local porta=$1
    if ! lsof -i :"$porta" > /dev/null 2>&1; then
        return 0
    fi
    registrar_mensagem "AVISO" "Porta $porta já está em uso"
    return 1
}

aguardar_porta() {
    local porta=$1
    local timeout=${2:-30}
    local contador=0
    
    while ! nc -z localhost "$porta"; do
        sleep 1
        contador=$((contador + 1))
        if [ $contador -ge $timeout ]; then
            registrar_mensagem "ERRO" "Timeout aguardando porta $porta"
            return 1
        fi
    done
    return 0
}

verificar_conexao_internet() {
    local host_teste="google.com"
    if ! ping -c 1 "$host_teste" &> /dev/null; then
        registrar_mensagem "ERRO" "Sem conexão com a internet"
        return 1
    fi
    return 0
}

# Funções de arquivo
fazer_backup() {
    local arquivo=$1
    local dir_backup="/var/backups/ocp"
    
    if [ ! -f "$arquivo" ]; then
        registrar_mensagem "ERRO" "Arquivo não encontrado: $arquivo"
        return 1
    fi
    
    mkdir -p "$dir_backup"
    local arquivo_backup="$dir_backup/$(basename "$arquivo").$(date +%Y%m%d_%H%M%S).bak"
    
    if cp "$arquivo" "$arquivo_backup"; then
        registrar_mensagem "INFO" "Backup criado: $arquivo_backup"
        return 0
    else
        registrar_mensagem "ERRO" "Falha ao criar backup de $arquivo"
        return 1
    fi
}

criar_diretorio_seguro() {
    local dir=$1
    local dono=${2:-root}
    local grupo=${3:-root}
    local perms=${4:-700}
    
    mkdir -p "$dir"
    chmod "$perms" "$dir"
    chown "$dono:$grupo" "$dir"
    
    registrar_mensagem "INFO" "Diretório seguro criado: $dir"
    return 0
}

# Tratamento de erros
tratar_erro() {
    local codigo_saida=$1
    local num_linha=$2
    local comando=$3
    
    registrar_mensagem "ERRO" "Comando falhou com código $codigo_saida"
    registrar_mensagem "ERRO" "Número da linha: $num_linha"
    registrar_mensagem "ERRO" "Comando: $comando"
    
    # Limpeza se necessário
    limpeza_apos_erro
    
    return $codigo_saida
}

limpeza_apos_erro() {
    # Adicione tarefas de limpeza aqui
    registrar_mensagem "INFO" "Realizando limpeza após erro"
}

# Inicialização do módulo
inicializar_utils() {
    configurar_logs
    verificar_dependencias
    verificar_requisitos_sistema
    
    # Configura tratamento de erros
    set -o errexit
    set -o pipefail
    trap 'tratar_erro $? ${LINENO} "$BASH_COMMAND"' ERR
}
