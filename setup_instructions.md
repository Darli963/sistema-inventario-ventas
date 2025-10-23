# Instrucciones de Configuración

Este documento detalla los requisitos y pasos de instalación necesarios para configurar el entorno de desarrollo del sistema de inventario y ventas.

## Requisitos de Acceso

### AWS
- **Cuenta AWS** con permisos de administrador
  - Opción 1: Usuario IAM con permisos administrativos
  - Opción 2: Rol IAM con permisos administrativos
- **Credenciales de acceso**: ID de clave de acceso y clave de acceso secreta

### GitHub
- **Cuenta GitHub** con acceso al repositorio del proyecto
- **Permisos**: Capacidad para clonar, realizar push y pull al repositorio

## Entorno Local

### Terraform
- **Versión recomendada**: >= 1.5.0
- **Instalación**:

#### macOS
```bash
# Usando Homebrew
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verificar instalación
terraform --version
```

#### Windows
```bash
# Usando Chocolatey
choco install terraform

# Verificar instalación
terraform --version
```

#### Linux
```bash
# Descargar e instalar
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verificar instalación
terraform --version
```

### Node.js
- **Versión recomendada**: LTS (20.x)
- **Instalación**:

#### macOS
```bash
# Usando Homebrew
brew install node@20

# Usando NVM (recomendado para gestionar múltiples versiones)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
nvm install 20
nvm use 20

# Verificar instalación
node --version
npm --version
```

#### Windows
```bash
# Descargar e instalar desde https://nodejs.org/

# Usando Chocolatey
choco install nodejs-lts

# Verificar instalación
node --version
npm --version
```

#### Linux
```bash
# Usando NVM (recomendado)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
nvm install 20
nvm use 20

# Usando apt (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verificar instalación
node --version
npm --version
```

### AWS CLI
- **Versión recomendada**: 2.x
- **Instalación**:

#### macOS
```bash
# Usando Homebrew
brew install awscli

# Verificar instalación
aws --version
```

#### Windows
```bash
# Descargar e instalar desde https://aws.amazon.com/cli/

# Usando Chocolatey
choco install awscli

# Verificar instalación
aws --version
```

#### Linux
```bash
# Descargar e instalar
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verificar instalación
aws --version
```

- **Configuración**:
```bash
aws configure
```
Se solicitará:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (ej. us-east-1)
- Default output format (ej. json)

### Git (Opcional)
- **Versión recomendada**: >= 2.30.0
- **Instalación**:

#### macOS
```bash
# Usando Homebrew
brew install git

# Verificar instalación
git --version
```

#### Windows
```bash
# Descargar e instalar desde https://git-scm.com/download/win

# Usando Chocolatey
choco install git

# Verificar instalación
git --version
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git

# Verificar instalación
git --version
```

- **Configuración básica**:
```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu.email@ejemplo.com"
```

## Verificación del Entorno

Para verificar que todo está correctamente instalado y configurado, ejecuta:

```bash
# Verificar Terraform
terraform --version

# Verificar Node.js
node --version
npm --version

# Verificar AWS CLI
aws --version
aws sts get-caller-identity

# Verificar Git (opcional)
git --version
```

## Clonación del Repositorio

```bash
# Clonar el repositorio
git clone [URL_DEL_REPOSITORIO]
cd sistema-inventario-ventas

# Instalar dependencias del proyecto
npm install
```

## Solución de Problemas Comunes

### Terraform
- **Error de permisos**: Asegúrate de tener los permisos adecuados en AWS
- **Error de versión**: Actualiza Terraform a la versión recomendada

### AWS CLI
- **Error de credenciales**: Verifica tus credenciales con `aws sts get-caller-identity`
- **Error de región**: Configura la región correcta con `aws configure`

### Node.js
- **Error de dependencias**: Ejecuta `npm ci` para una instalación limpia
- **Error de versión**: Usa NVM para cambiar a la versión recomendada