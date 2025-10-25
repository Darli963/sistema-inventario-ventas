import { getPool } from "../../utils/db.js";

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      "content-type": "application/json",
      "access-control-allow-origin": "*",
      "access-control-allow-methods": "GET,OPTIONS",
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
      // Reporte simple: ventas totales por producto
      const [rows] = await pool.query(
        "SELECT p.id as producto_id, p.nombre, SUM(v.cantidad) as cantidad_total, SUM(v.total) as total_vendido FROM ventas v JOIN productos p ON p.id = v.producto_id GROUP BY p.id, p.nombre ORDER BY total_vendido DESC LIMIT 50"
      );
      return response(200, { items: rows });
    }

    return response(405, { message: "Method Not Allowed" });
  } catch (err) {
    console.error("reportes error", err);
    return response(500, { error: err.message || "Internal Server Error" });
  }
};