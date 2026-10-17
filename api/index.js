const url = require('node:url');
const { handleApiRequest } = require('../server/router');

module.exports = async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  const query = parsedUrl.query;

  // Collect request body if not already parsed by Vercel
  let bodyData = req.body;
  if (!bodyData && req.method !== 'GET' && req.method !== 'HEAD') {
    bodyData = await new Promise((resolve) => {
      let data = '';
      req.on('data', chunk => { data += chunk; });
      req.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { resolve({}); }
      });
    });
  } else if (typeof bodyData === 'string') {
    try { bodyData = JSON.parse(bodyData); } catch (e) { bodyData = {}; }
  }

  await handleApiRequest(req, res, pathname, query, bodyData || {});
};
