export async function handler(event) {
  return {
    statusCode: 200,
    headers: {
      'content-type': 'application/json'
    },
    body: JSON.stringify({
      status: 'ok',
      service: 'health',
      time: new Date().toISOString()
    })
  };
}
