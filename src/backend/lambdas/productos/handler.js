import { getPool } from "../../utils/db.js";

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,POST,PUT,DELETE,OPTIONS",
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
      const [rows] = await pool.query("SELECT id, nombre, precio, sku FROM productos LIMIT 100");
      return response(200, { items: rows });
    }

    const body = event?.body ? JSON.parse(event.body) : {};

    if (method === "POST") {
      const { nombre, precio, sku } = body;
      const [result] = await pool.execute(
        "INSERT INTO productos (nombre, precio, sku) VALUES (?, ?, ?)",
        [nombre, precio, sku]
      );
      return response(201, { id: result.insertId, nombre, precio, sku });
    }

    if (method === "PUT") {
      const { id, nombre, precio, sku } = body;
      await pool.execute(
        "UPDATE productos SET nombre = ?, precio = ?, sku = ? WHERE id = ?",
        [nombre, precio, sku, id]
      );
      return response(200, { id, nombre, precio, sku });
    }

    if (method === "DELETE") {
      const { id } = body;
      await pool.execute("DELETE FROM productos WHERE id = ?", [id]);
      return response(200, { deleted: id });
    }

    return response(405, { message: "Method Not Allowed" });
  } catch (err) {
    console.error("productos error", err);
    return response(500, { error: err.message || "Internal Server Error" });
  }
};
