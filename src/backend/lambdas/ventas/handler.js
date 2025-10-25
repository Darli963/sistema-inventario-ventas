import { getPool } from "../../utils/db.js";

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,POST,OPTIONS",
      "access-control-allow-headers": "content-type,authorization"
    },
    body: JSON.stringify(body),
  };
}

export const handler = async (event) => {
  const method = event?.requestContext?.http?.method || "GET";
  const pool = await getPool();

  try {
    if (method === "GET") {
      const [rows] = await pool.query("SELECT id, producto_id, cantidad, total, created_at FROM ventas ORDER BY created_at DESC LIMIT 100");
      return response(200, { items: rows });
    }

    const body = event?.body ? JSON.parse(event.body) : {};

    if (method === "POST") {
      const { producto_id, cantidad, precio_unitario } = body;
      // Actualizar inventario (salida)
      await pool.execute(
        "UPDATE inventario SET stock = stock - ? WHERE producto_id = ?",
        [cantidad, producto_id]
      );
      const total = cantidad * precio_unitario;
      const [result] = await pool.execute(
        "INSERT INTO ventas (producto_id, cantidad, total) VALUES (?, ?, ?)",
        [producto_id, cantidad, total]
      );
      return response(201, { id: result.insertId, producto_id, cantidad, total });
    }

    return response(405, { message: "Method Not Allowed" });
  } catch (err) {
    console.error("ventas error", err);
    return response(500, { error: err.message || "Internal Server Error" });
  }
};