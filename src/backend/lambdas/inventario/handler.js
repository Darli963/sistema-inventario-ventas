import { getPool } from "../../utils/db.js";

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,POST,PUT,OPTIONS",
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
      const [rows] = await pool.query("SELECT id, producto_id, cantidad, tipo, created_at FROM inventario_movimientos ORDER BY created_at DESC LIMIT 100");
      return response(200, { items: rows });
    }

    const body = event?.body ? JSON.parse(event.body) : {};

    if (method === "POST") {
      const { producto_id, cantidad, tipo } = body; // tipo: 'entrada'|'salida'
      const delta = tipo === "salida" ? -Math.abs(cantidad) : Math.abs(cantidad);
      await pool.execute(
        "INSERT INTO inventario_movimientos (producto_id, cantidad, tipo) VALUES (?, ?, ?)",
        [producto_id, cantidad, tipo]
      );
      await pool.execute(
        "UPDATE inventario SET stock = stock + ? WHERE producto_id = ?",
        [delta, producto_id]
      );
      return response(201, { producto_id, cantidad, tipo });
    }

    if (method === "PUT") {
      const { producto_id, stock } = body;
      await pool.execute("UPDATE inventario SET stock = ? WHERE producto_id = ?", [stock, producto_id]);
      return response(200, { producto_id, stock });
    }

    return response(405, { message: "Method Not Allowed" });
  } catch (err) {
    console.error("inventario error", err);
    return response(500, { error: err.message || "Internal Server Error" });
  }
};
