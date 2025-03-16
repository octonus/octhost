#!/bin/bash

# Script de Instalação Rápida OCP
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

# Banner
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
echo -e "${BRANCO}Instalador Rápido OCP${SEM_COR}"
echo -e "${BRANCO}========================================${SEM_COR}"
echo -e "${BRANCO}Octonus Cloud Platform${SEM_COR}"
echo -e "${BRANCO}https://octhost.com.br${SEM_COR}"
echo -e "${BRANCO}========================================${SEM_COR}"

# Função para exibir progresso
mostrar_progresso() {
    local descricao=$1
    echo -ne "${CIANO}$descricao...${SEM_COR}"
}

# Função para confirmar conclusão
confirmar_conclusao() {
    echo -e "${VERDE} Concluído!${SEM_COR}"
}

# Função para exibir erro
mostrar_erro() {
    local mensagem=$1
    echo -e "${VERMELHO}Erro: $mensagem${SEM_COR}"
    exit 1
}

# Verifica conexão com a internet
mostrar_progresso "Verificando conexão com a internet"
if ! ping -c 1 google.com &> /dev/null; then
    mostrar_erro "Sem conexão com a internet"
fi
confirmar_conclusao

# Atualiza o sistema
mostrar_progresso "Atualizando sistema"
apt-get update && apt-get upgrade -y || mostrar_erro "Falha ao atualizar o sistema"
confirmar_conclusao

# Instala dependências básicas
mostrar_progresso "Instalando dependências"
apt-get install -y \
    curl \
    wget \
    git \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release || mostrar_erro "Falha ao instalar dependências"
confirmar_conclusao

# Instala Docker
mostrar_progresso "Instalando Docker"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh || mostrar_erro "Falha ao instalar Docker"
    systemctl enable docker
    systemctl start docker
fi
confirmar_conclusao

# Cria diretórios necessários
mostrar_progresso "Criando diretórios"
mkdir -p /etc/ocp
mkdir -p /var/log/ocp
mkdir -p /var/backups/ocp
confirmar_conclusao

# Função para download seguro
download_arquivo() {
    local url=$1
    local destino=$2
    wget -q "$url" -O "$destino" || mostrar_erro "Falha ao baixar $destino"
}

# Download dos arquivos necessários
mostrar_progresso "Baixando OCP"
mkdir -p /opt/ocp
mkdir -p /opt/ocp/modules
mkdir -p /opt/ocp/config

# Download dos arquivos principais
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/setup.sh" "/opt/ocp/setup.sh"
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/check.sh" "/opt/ocp/check.sh"
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/uninstall.sh" "/opt/ocp/uninstall.sh"

# Download dos módulos
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/modules/menu.sh" "/opt/ocp/modules/menu.sh"
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/modules/utils.sh" "/opt/ocp/modules/utils.sh"
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/modules/docker.sh" "/opt/ocp/modules/docker.sh"
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/modules/apps.sh" "/opt/ocp/modules/apps.sh"
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/modules/security.sh" "/opt/ocp/modules/security.sh"
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/modules/backup.sh" "/opt/ocp/modules/backup.sh"

# Download da configuração
download_arquivo "https://raw.githubusercontent.com/octonus/octhost/main/config/config.json" "/opt/ocp/config/config.json"

confirmar_conclusao

# Configura permissões
mostrar_progresso "Configurando permissões"
chmod +x /opt/ocp/setup.sh
chmod +x /opt/ocp/modules/*.sh
confirmar_conclusao

# Cria link simbólico
mostrar_progresso "Criando link simbólico"
ln -sf /opt/ocp/setup.sh /usr/local/bin/ocp
confirmar_conclusao

# Mensagem de conclusão
echo -e "\n${VERDE}Instalação concluída com sucesso!${SEM_COR}"
echo -e "\n${BRANCO}Para iniciar o OCP, execute:${SEM_COR}"
echo -e "${CIANO}ocp${SEM_COR}"

# Informações adicionais
echo -e "\n${BRANCO}Informações importantes:${SEM_COR}"
echo -e "- Documentação: ${CIANO}https://docs.octhost.com.br${SEM_COR}"
echo -e "- Suporte: ${CIANO}suporte@octhost.com.br${SEM_COR}"
echo -e "- Website: ${CIANO}https://octhost.com.br${SEM_COR}"

# Pergunta se deseja iniciar o OCP agora
echo -e "\n${AMARELO}Deseja iniciar o OCP agora? (s/N)${SEM_COR}"
read -r resposta

if [[ ${resposta,,} == "s" ]]; then
    /opt/ocp/setup.sh
fi
