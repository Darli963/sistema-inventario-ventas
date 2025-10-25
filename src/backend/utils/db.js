import { SecretsManagerClient, GetSecretValueCommand } from "@aws-sdk/client-secrets-manager";
import mysql from "mysql2/promise";

let poolPromise;

async function getDbConfig() {
  const secretArn = process.env.DB_SECRET_ARN;
  const host = process.env.DB_HOST;
  const port = parseInt(process.env.DB_PORT || "3306", 10);
  const dbNameEnv = process.env.DB_NAME || "inventario";

  if (!secretArn || !host || !port) {
    throw new Error("Missing DB environment variables: DB_SECRET_ARN, DB_HOST, DB_PORT");
  }

  const client = new SecretsManagerClient({ region: process.env.AWS_REGION || "us-east-1" });
  const res = await client.send(new GetSecretValueCommand({ SecretId: secretArn }));
  const secret = JSON.parse(res.SecretString || "{}");

  return {
    host,
    port,
    user: secret.username || "admin",
    password: secret.password,
    database: secret.dbname || dbNameEnv,
    waitForConnections: true,
    connectionLimit: 5,
    queueLimit: 0,
  };
}

async function ensureSchema(pool) {
  // Productos
  await pool.execute(`CREATE TABLE IF NOT EXISTS productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    sku VARCHAR(64) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;`);

  // Inventario
  await pool.execute(`CREATE TABLE IF NOT EXISTS inventario (
    producto_id INT NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (producto_id)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;`);

  // Movimientos de Inventario
  await pool.execute(`CREATE TABLE IF NOT EXISTS inventario_movimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    tipo ENUM('entrada','salida') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;`);

  // Ventas
  await pool.execute(`CREATE TABLE IF NOT EXISTS ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;`);
}

export async function getPool() {
  if (!poolPromise) {
    poolPromise = (async () => {
      const config = await getDbConfig();
      const pool = mysql.createPool(config);
      await ensureSchema(pool);
      return pool;
    })();
  }
  return poolPromise;
}