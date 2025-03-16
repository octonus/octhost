#!/bin/bash

# Módulo de Gerenciamento Docker para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

# Funções de instalação e configuração do Docker

# Instalação do Docker
instalar_docker() {
    registrar_mensagem "INFO" "Iniciando instalação do Docker"
    
    # Verifica se o Docker já está instalado
    if command -v docker &> /dev/null; then
        registrar_mensagem "AVISO" "Docker já está instalado"
        return 0
    fi
    
    # Backup de configurações existentes do Docker
    if [ -f "/etc/docker/daemon.json" ]; then
        fazer_backup "/etc/docker/daemon.json"
    fi
    
    # Instala dependências
    registrar_mensagem "INFO" "Instalando dependências do Docker"
    apt-get update
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Adiciona chave GPG oficial do Docker
    registrar_mensagem "INFO" "Adicionando chave GPG do Docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Adiciona repositório do Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instala Docker Engine
    registrar_mensagem "INFO" "Instalando Docker Engine"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Configura daemon do Docker
    configurar_daemon_docker
    
    # Inicia serviço do Docker
    registrar_mensagem "INFO" "Iniciando serviço do Docker"
    systemctl start docker
    systemctl enable docker
    
    # Verifica instalação
    if ! docker --version > /dev/null 2>&1; then
        registrar_mensagem "ERRO" "Falha na instalação do Docker"
        return 1
    fi
    
    # Configurações pós-instalação
    configurar_pos_instalacao_docker
    
    registrar_mensagem "SUCESSO" "Instalação do Docker concluída com sucesso"
    return 0
}

# Configuração do daemon do Docker
configurar_daemon_docker() {
    local config_daemon="/etc/docker/daemon.json"
    local dir_docker="/etc/docker"
    
    # Cria diretório de configuração do Docker se não existir
    mkdir -p "$dir_docker"
    
    # Cria configuração otimizada do daemon
    cat > "$config_daemon" << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 64000,
            "Soft": 64000
        }
    },
    "live-restore": true,
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 10,
    "storage-driver": "overlay2",
    "metrics-addr": "127.0.0.1:9323",
    "experimental": false,
    "registry-mirrors": [
        "https://mirror.gcr.io",
        "https://registry-1.docker.io"
    ]
}
EOF

    # Reinicia o Docker para aplicar configurações
    if systemctl is-active --quiet docker; then
        systemctl restart docker
    fi
}

# Configurações pós-instalação do Docker
configurar_pos_instalacao_docker() {
    # Cria grupo docker se não existir
    if ! getent group docker > /dev/null; then
        groupadd docker
    fi
    
    # Adiciona usuário atual ao grupo docker
    local usuario_atual=$(whoami)
    usermod -aG docker "$usuario_atual"
    
    # Cria diretórios para volumes
    local dir_volumes="/var/lib/docker-volumes"
    criar_diretorio_seguro "$dir_volumes" "root" "root" "755"
    
    registrar_mensagem "INFO" "Configurações pós-instalação concluídas"
}

# Gerenciamento de contêineres
gerenciar_conteineres() {
    while true; do
        clear
        echo -e "${BRANCO}Gerenciamento de Contêineres${SEM_COR}"
        echo "1) Listar Contêineres"
        echo "2) Iniciar Contêiner"
        echo "3) Parar Contêiner"
        echo "4) Remover Contêiner"
        echo "5) Ver Logs"
        echo "6) Voltar"
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1) listar_conteineres ;;
            2) iniciar_conteiner ;;
            3) parar_conteiner ;;
            4) remover_conteiner ;;
            5) ver_logs_conteiner ;;
            6) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

# Funções auxiliares para gerenciamento de contêineres
listar_conteineres() {
    echo -e "${CIANO}Contêineres em Execução:${SEM_COR}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo -e "\n${CIANO}Todos os Contêineres:${SEM_COR}"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
    read -p "Pressione Enter para continuar..."
}

iniciar_conteiner() {
    echo -e "${CIANO}Contêineres Parados:${SEM_COR}"
    docker ps -f "status=exited" --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    read -p "Digite o ID ou nome do contêiner para iniciar: " conteiner
    
    if [ -n "$conteiner" ]; then
        if docker start "$conteiner"; then
            registrar_mensagem "SUCESSO" "Contêiner $conteiner iniciado"
        else
            registrar_mensagem "ERRO" "Falha ao iniciar contêiner $conteiner"
        fi
    fi
}

parar_conteiner() {
    echo -e "${CIANO}Contêineres em Execução:${SEM_COR}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    read -p "Digite o ID ou nome do contêiner para parar: " conteiner
    
    if [ -n "$conteiner" ]; then
        if docker stop "$conteiner"; then
            registrar_mensagem "SUCESSO" "Contêiner $conteiner parado"
        else
            registrar_mensagem "ERRO" "Falha ao parar contêiner $conteiner"
        fi
    fi
}

remover_conteiner() {
    echo -e "${CIANO}Todos os Contêineres:${SEM_COR}"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    read -p "Digite o ID ou nome do contêiner para remover: " conteiner
    
    if [ -n "$conteiner" ]; then
        if confirmar_acao "Tem certeza que deseja remover o contêiner $conteiner?"; then
            if docker rm -f "$conteiner"; then
                registrar_mensagem "SUCESSO" "Contêiner $conteiner removido"
            else
                registrar_mensagem "ERRO" "Falha ao remover contêiner $conteiner"
            fi
        fi
    fi
}

ver_logs_conteiner() {
    echo -e "${CIANO}Contêineres Disponíveis:${SEM_COR}"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    read -p "Digite o ID ou nome do contêiner para ver logs: " conteiner
    
    if [ -n "$conteiner" ]; then
        docker logs --tail 100 -f "$conteiner"
    fi
}

# Gerenciamento de redes Docker
gerenciar_redes_docker() {
    while true; do
        clear
        echo -e "${BRANCO}Gerenciamento de Redes Docker${SEM_COR}"
        echo "1) Listar Redes"
        echo "2) Criar Rede"
        echo "3) Remover Rede"
        echo "4) Inspecionar Rede"
        echo "5) Voltar"
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1) listar_redes ;;
            2) criar_rede ;;
            3) remover_rede ;;
            4) inspecionar_rede ;;
            5) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

# Funções auxiliares para gerenciamento de redes
listar_redes() {
    echo -e "${CIANO}Redes Docker Disponíveis:${SEM_COR}"
    docker network ls
    read -p "Pressione Enter para continuar..."
}

criar_rede() {
    read -p "Digite o nome da nova rede: " nome_rede
    read -p "Digite o driver da rede (bridge/overlay/host): " driver_rede
    
    if [ -n "$nome_rede" ]; then
        if docker network create --driver "${driver_rede:-bridge}" "$nome_rede"; then
            registrar_mensagem "SUCESSO" "Rede $nome_rede criada"
        else
            registrar_mensagem "ERRO" "Falha ao criar rede $nome_rede"
        fi
    fi
}

remover_rede() {
    echo -e "${CIANO}Redes Docker Disponíveis:${SEM_COR}"
    docker network ls
    read -p "Digite o nome da rede para remover: " nome_rede
    
    if [ -n "$nome_rede" ]; then
        if confirmar_acao "Tem certeza que deseja remover a rede $nome_rede?"; then
            if docker network rm "$nome_rede"; then
                registrar_mensagem "SUCESSO" "Rede $nome_rede removida"
            else
                registrar_mensagem "ERRO" "Falha ao remover rede $nome_rede"
            fi
        fi
    fi
}

inspecionar_rede() {
    echo -e "${CIANO}Redes Docker Disponíveis:${SEM_COR}"
    docker network ls
    read -p "Digite o nome da rede para inspecionar: " nome_rede
    
    if [ -n "$nome_rede" ]; then
        docker network inspect "$nome_rede"
        read -p "Pressione Enter para continuar..."
    fi
}

# Gerenciamento de volumes Docker
gerenciar_volumes_docker() {
    while true; do
        clear
        echo -e "${BRANCO}Gerenciamento de Volumes Docker${SEM_COR}"
        echo "1) Listar Volumes"
        echo "2) Criar Volume"
        echo "3) Remover Volume"
        echo "4) Inspecionar Volume"
        echo "5) Limpar Volumes Não Utilizados"
        echo "6) Voltar"
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1) listar_volumes ;;
            2) criar_volume ;;
            3) remover_volume ;;
            4) inspecionar_volume ;;
            5) limpar_volumes ;;
            6) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

# Funções auxiliares para gerenciamento de volumes
listar_volumes() {
    echo -e "${CIANO}Volumes Docker Disponíveis:${SEM_COR}"
    docker volume ls
    read -p "Pressione Enter para continuar..."
}

criar_volume() {
    read -p "Digite o nome do novo volume: " nome_volume
    
    if [ -n "$nome_volume" ]; then
        if docker volume create "$nome_volume"; then
            registrar_mensagem "SUCESSO" "Volume $nome_volume criado"
        else
            registrar_mensagem "ERRO" "Falha ao criar volume $nome_volume"
        fi
    fi
}

remover_volume() {
    echo -e "${CIANO}Volumes Docker Disponíveis:${SEM_COR}"
    docker volume ls
    read -p "Digite o nome do volume para remover: " nome_volume
    
    if [ -n "$nome_volume" ]; then
        if confirmar_acao "Tem certeza que deseja remover o volume $nome_volume?"; then
            if docker volume rm "$nome_volume"; then
                registrar_mensagem "SUCESSO" "Volume $nome_volume removido"
            else
                registrar_mensagem "ERRO" "Falha ao remover volume $nome_volume"
            fi
        fi
    fi
}

inspecionar_volume() {
    echo -e "${CIANO}Volumes Docker Disponíveis:${SEM_COR}"
    docker volume ls
    read -p "Digite o nome do volume para inspecionar: " nome_volume
    
    if [ -n "$nome_volume" ]; then
        docker volume inspect "$nome_volume"
        read -p "Pressione Enter para continuar..."
    fi
}

limpar_volumes() {
    if confirmar_acao "Tem certeza que deseja remover todos os volumes não utilizados?"; then
        if docker volume prune -f; then
            registrar_mensagem "SUCESSO" "Volumes não utilizados foram removidos"
        else
            registrar_mensagem "ERRO" "Falha ao remover volumes não utilizados"
        fi
    fi
}
