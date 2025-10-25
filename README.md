# 🎵 ArtFy

Script de som para QBCore inspirado no Spotify, permitindo reproduzir músicas do YouTube em seu servidor FiveM/QBCore.

## 📋 Descrição

ArtFy é um sistema de reprodução de música que traz uma experiência similar ao Spotify para seu servidor QBCore. Os jogadores podem reproduzir músicas do YouTube, controlar volume, criar playlists e compartilhar música com outros jogadores.

## 🎯 Features

- 🎶 Reprodução de músicas do YouTube
- 🔊 Controle de volume individual
- 📱 Interface moderna inspirada no Spotify
- 🎧 Sistema de playlists
- 👥 Compartilhamento de música com outros jogadores
- ⏯️ Controles completos (play, pause, stop)

## 📦 Dependências

Este script requer as seguintes dependências para funcionar corretamente:

### Dependências

- **[QBCore Framework](https://github.com/qbcore-framework/qb-core)** (Serve a QBOX também)
- **[Xsound](https://github.com/Xogy/xsound)** - Sistema de áudio

## 🔧 Instalação

1. **Baixe** o script e extraia na pasta `resources` do seu servidor

2. **Instale as dependências** mencionadas acima

3. **Configure a API Key do YouTube**:
   - Acesse o [Google Cloud Console](https://console.cloud.google.com/)
   - Crie um novo projeto ou selecione um existente
   - Ative a **YouTube Data API v3**
   - Crie uma credencial (API Key)
   - Copie a API Key gerada

4. **Edite o script** e localize a linha:
   ```javascript
   const YOUTUBE_API_KEY = 
   ```
   Substitua `'Colocar sua Api key do google aqui (deve ter a permissão da API do youtube)'` pela sua API Key do YouTube

5. **Adicione ao server.cfg**:
   ```cfg
   ensure xsound
   ensure ArtFy
   ```

6. **Reinicie o servidor**

## ⚙️ Configuração

### Obtendo a YouTube API Key

1. Acesse: https://console.cloud.google.com/
2. Crie um novo projeto
3. Vá em "APIs e Serviços" > "Biblioteca"
4. Procure por "YouTube Data API v3" e ative
5. Vá em "Credenciais" > "Criar Credenciais" > "Chave de API"
6. Copie a chave gerada e cole no script

### Arquivo de Configuração

Edite o arquivo de configuração do script para ajustar:
- Volume padrão
- Distância máxima de áudio
- Permissões de uso
- Comandos personalizados

## 🎮 Uso

### Comando

- `/som` - Abre o menu principal

### Interface

A interface pode ser acessada através do comando `/artfy` e oferece:
- Busca de músicas
- Controles de reprodução
- Gerenciamento de playlists
- Configurações de volume

## 🛠️ FAQ

Se encontrar problemas:
1. Verifique se todas as dependências estão instaladas
2. Confirme se a API Key do YouTube está configurada corretamente
3. Verifique o console do servidor para erros
4. Revise os logs do cliente (F8)

## 📝 Notas

- A API Key do YouTube tem limites de uso diário (10.000 requisições/dia na quota gratuita) (Planejo migrar de API depois ou adicionar uma segunda opção! Se quiser contribuir aceito PR!)
- Certifique-se de que o Xsound está funcionando corretamente antes de instalar o ArtFy
- Recomenda-se fazer backup antes de qualquer instalação

## 🤝 Créditos

- Desenvolvido Por Art
- Inspirado no design do Spotify
- Utiliza Xsound para reprodução de áudio
- YouTube API para busca de músicas

---

**⚠️ IMPORTANTE**: Cuidado ao mandar pra alguém com a sua API key! Pode dar um xabu danado!
