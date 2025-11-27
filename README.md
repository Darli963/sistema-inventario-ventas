# 🏪 Sistema de Inventario y Ventas - Market Carmensita

El **Sistema de Inventario y Ventas - Market Carmensita** es una aplicación web moderna desarrollada sobre la nube de **Amazon Web Services (AWS)** y gestionada mediante **Terraform**.  
Su objetivo es ofrecer una solución integral, moderna y automatizada para la gestión completa del inventario, control de ventas y generación de reportes comerciales, todo dentro de un entorno seguro, escalable y de alta disponibilidad en la nube.

El sistema está diseñado para optimizar los procesos operativos de un negocio minorista, permitiendo registrar productos, actualizar existencias en tiempo real, procesar transacciones, generar informes detallados de desempeño y mantener la información centralizada en una infraestructura confiable.

Además, gracias a su diseño basado en servicios administrados de AWS y despliegue mediante Terraform, el sistema garantiza bajo mantenimiento, reducción de costos, resiliencia ante fallos y una rápida capacidad de crecimiento, adaptándose fácilmente a las necesidades del negocio a medida que evoluciona.

## 🎯 Objetivo del Proyecto

El propósito de este sistema es **digitalizar y optimizar la gestión de inventario y ventas** de un negocio minorista, reemplazando los procesos manuales por una solución web basada en la nube.

Con este sistema, los usuarios pueden:
- Registrar y gestionar productos, clientes y ventas.  
- Consultar el stock en tiempo real.  
- Generar reportes automáticos de desempeño.  
- Realizar copias de seguridad automáticas.  
- Controlar el acceso mediante autenticación segura.


## ☁️ Descripción General de la Arquitectura

La infraestructura se basa en una arquitectura **serverless y desacoplada**, desplegada sobre **AWS** y completamente gestionada con **Terraform** bajo el enfoque *Infraestructura como Código (IaC)*.

El sistema se divide en tres capas principales:

### 1. Capa de Presentación (Frontend)
- Sitio web estático alojado en **Amazon S3**.  
- Distribución global mediante **Amazon CloudFront** (CDN).  
- Certificados SSL/TLS gestionados con **AWS Certificate Manager (ACM)**.  
- Dominio administrado por **Route 53**.

### 2. Capa Lógica (Backend)
- **AWS API Gateway** gestiona las peticiones REST.  
- **AWS Lambda** ejecuta la lógica de negocio (ventas, inventario, autenticación).  
- **AWS Cognito** maneja el registro, inicio de sesión y roles de usuario.

### 3. Capa de Datos (Persistencia)
- **Amazon RDS (MySQL)** almacena información de ventas, productos y usuarios.  
- **DynamoDB** guarda configuraciones y sesiones.  
- **Amazon S3** almacena archivos estáticos y copias de seguridad automáticas.

### Seguridad, Monitoreo y Respaldo
- **AWS IAM** gestiona roles y políticas de acceso.  
- **AWS WAF** y **Shield** protegen contra ataques y tráfico malicioso.  
- **CloudWatch** registra logs y métricas del sistema.  
- **SNS** envía notificaciones ante eventos críticos.  
- **AWS Backup** realiza respaldos automáticos de la base de datos.


## 🧠 Funcionamiento del Sistema

1. El usuario accede a la aplicación web mediante la URL pública (CloudFront).  
2. **Cognito** autentica la sesión y valida permisos.  
3. Las peticiones se envían a través de **API Gateway**, que invoca funciones **Lambda**.  
4. Las funciones Lambda procesan la información y actualizan los datos en **RDS** o **DynamoDB**.  
5. Los registros y métricas del sistema se almacenan en **CloudWatch**.  
6. Se ejecutan respaldos automáticos en **AWS Backup** para garantizar la disponibilidad de los datos.

Este flujo garantiza **alta disponibilidad, seguridad multicapa y escalabilidad automática** sin necesidad de servidores dedicados.


## ⚙️ Tecnologías y Servicios Utilizados

### Lenguajes y herramientas
- **Terraform:** Infraestructura como Código (IaC).  
- **Python:** Lógica de negocio en funciones Lambda.  
- **HTML, CSS y JavaScript:** Interfaz web (frontend).  
- **Git y GitHub Actions:** Control de versiones y automatización del despliegue.

### Servicios AWS
- Amazon S3  
- Amazon CloudFront  
- AWS Lambda  
- Amazon API Gateway  
- AWS Cognito  
- Amazon RDS (MySQL)  
- Amazon DynamoDB  
- AWS IAM  
- AWS WAF / Shield  
- Amazon CloudWatch  
- AWS Backup  
- Amazon SNS  
- AWS Route 53  
- AWS Certificate Manager (ACM)


## 🚀 Instrucciones de Despliegue

### Prerrequisitos

Antes de desplegar el proyecto, asegúrate de contar con:
- Una **cuenta AWS** activa.  
- **Terraform** versión 1.5 o superior.  
- **AWS CLI** configurado con tus credenciales.  
- **Git** instalado en tu máquina local.  

### Pasos de despliegue

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/Darli963/sistema-inventario-ventas.git
Entrar en el directorio del proyecto

bash
Copiar código
cd sistema-inventario-ventas/infra
Inicializar Terraform

bash
Copiar código
terraform init
Revisar los recursos que se crearán

bash
Copiar código
terraform plan
Aplicar la infraestructura

bash
Copiar código
terraform apply
Al finalizar, Terraform mostrará la URL pública del sistema (entregada por CloudFront o API Gateway).

Para eliminar los recursos creados:

bash
Copiar código
terraform destroy

🧩 Uso del Sistema
Accede al sitio web con la URL generada por CloudFront.

Inicia sesión mediante AWS Cognito.

Registra, edita o elimina productos del inventario.

Registra ventas y genera reportes automáticos.

Supervisa logs y métricas en CloudWatch.

Los respaldos y notificaciones se gestionan de forma automática.

📈 Beneficios Clave
Escalabilidad automática gracias a Lambda y RDS.

Alta disponibilidad mediante servicios distribuidos de AWS.

Seguridad multicapa con IAM, WAF y Shield.

Despliegue reproducible mediante Terraform.

Bajo costo operativo al utilizar servicios serverless.

Monitoreo proactivo con CloudWatch y SNS.

Respaldo automático mediante AWS Backup.


👩‍💻 Autors
-Barrios Capa Brad Janer
-Medina Sixse Darli Manuel
-Rodriguez Ruiz Alessandro Paul
