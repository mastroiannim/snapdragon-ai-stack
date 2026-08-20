import http from 'node:http';

const PROXY_PORT = 18182;
// Default to GenieX NPU 18181, or llama-server if specified
let UPSTREAM_URL = process.env.UPSTREAM_URL || 'http://127.0.0.1:18181';

const SLIM_SYSTEM_PROMPT = `Sei un assistente AI avanzato. Rispondi sempre in italiano, in modo chiaro, utile, diretto e accurato. /no_think`;

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Dynamic upstream routing based on model or header
  const url = new URL(req.url, `http://${req.headers.host}`);
  
  if (req.method === 'GET' && (url.pathname === '/v1/models' || url.pathname === '/models')) {
    const endpoints = [
      { name: 'NPU', url: 'http://127.0.0.1:18181' },
      { name: 'GPU-27B', url: 'http://127.0.0.1:18184' },
      { name: 'GPU-8B', url: 'http://127.0.0.1:18185' },
      { name: 'Vision', url: 'http://127.0.0.1:18183' }
    ];

    Promise.allSettled(
      endpoints.map(ep => 
        fetch(`${ep.url}${url.pathname}${url.search}`, { signal: AbortSignal.timeout(1500) })
          .then(res => res.ok ? res.json() : null)
          .catch(() => null)
      )
    ).then(results => {
      const combinedModels = [];
      for (const res of results) {
        if (res.status === 'fulfilled' && res.value && Array.isArray(res.value.data)) {
          for (const m of res.value.data) {
            combinedModels.push({
              ...m,
              id: m.id + '-caveman',
              name: (m.name || m.id) + ' (Caveman Fast)'
            });
          }
        }
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ object: 'list', data: combinedModels }));
    }).catch(err => {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: err.message }));
    });
    return;
  }

  if (req.method === 'POST' && url.pathname.includes('/chat/completions')) {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', async () => {
      try {
        const payload = JSON.parse(body);
        const requestedModel = payload.model || '';

        // Strip -caveman suffix if WebUI sent it
        if (payload.model && payload.model.endsWith('-caveman')) {
          payload.model = payload.model.replace('-caveman', '');
        }

        // Determine target server based on model requested
        let currentTarget = UPSTREAM_URL; // Defaults to GenieX NPU (18181)
        if (payload.model && payload.model.includes('8B') && payload.model.includes('GPU')) {
          currentTarget = 'http://127.0.0.1:18185';
        } else if (payload.model && payload.model.includes('GPU')) {
          currentTarget = 'http://127.0.0.1:18184';
        } else if (payload.model && payload.model.includes('Muse')) {
          currentTarget = 'http://127.0.0.1:18183';
        }

        // ULTRA PROMPT COMPRESSION: Strip the 3,000-token system prompt and replace with slim prompt
        if (Array.isArray(payload.messages)) {
          const sysIdx = payload.messages.findIndex(m => m.role === 'system');
          if (sysIdx >= 0) {
            payload.messages[sysIdx].content = SLIM_SYSTEM_PROMPT;
          } else {
            payload.messages.unshift({ role: 'system', content: SLIM_SYSTEM_PROMPT });
          }
        }

        // Strip heavy tool schemas from prompt
        delete payload.tools;
        delete payload.tool_choice;

        const fallbackEndpoints = [
          currentTarget,
          'http://127.0.0.1:18184',
          'http://127.0.0.1:18185',
          'http://127.0.0.1:18181',
          'http://127.0.0.1:18183'
        ];
        // Deduplicate
        const uniqueEndpoints = [...new Set(fallbackEndpoints)];

        let upstreamRes = null;
        let activeTargetUrl = '';
        const startTime = Date.now();

        for (const ep of uniqueEndpoints) {
          try {
            const targetUrl = `${ep}${url.pathname}${url.search}`;
            console.log(`[Compressor Proxy] Ingesting request -> Forwarding compressed prompt (${payload.messages.length} msgs) to ${targetUrl}...`);
            upstreamRes = await fetch(targetUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(payload)
            });
            activeTargetUrl = targetUrl;
            break;
          } catch (err) {
            console.warn(`[Compressor Proxy] Endpoint ${ep} not reachable (${err.message}). Trying fallback...`);
          }
        }

        if (!upstreamRes) {
          throw new Error('Nessun server AI locale e attualmente in esecuzione (18181, 18184, 18185, 18183 sono tutti spenti).');
        }

        if (!upstreamRes.ok) {
          const errText = await upstreamRes.text();
          res.writeHead(upstreamRes.status, { 'Content-Type': 'application/json' });
          res.end(errText);
          return;
        }

        const fallbackId = 'chatcmpl-' + Math.random().toString(36).substring(2, 15);
        const fallbackCreated = Math.floor(Date.now() / 1000);

        if (payload.stream) {
          res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive'
          });

          const decoder = new TextDecoder();
          const reader = upstreamRes.body.getReader();
          let totalBytes = 0;
          let buffer = '';

          while (true) {
            const { done, value } = await reader.read();
            if (done) break;
            totalBytes += value.length;
            buffer += decoder.decode(value, { stream: true });

            const lines = buffer.split('\n');
            buffer = lines.pop(); // Keep incomplete line

            for (const line of lines) {
              const trimmed = line.trim();
              if (trimmed.startsWith('data:')) {
                const dataPayload = trimmed.slice(5).trim();
                if (dataPayload === '[DONE]') {
                  res.write(`data: [DONE]\n\n`);
                } else if (dataPayload) {
                  try {
                    const parsed = JSON.parse(dataPayload);
                    if (!parsed.model || parsed.model === '') {
                      parsed.model = requestedModel;
                    }
                    if (!parsed.id || parsed.id === '') {
                      parsed.id = fallbackId;
                    }
                    if (!parsed.created || parsed.created === 0) {
                      parsed.created = fallbackCreated;
                    }
                    res.write(`data: ${JSON.stringify(parsed)}\n\n`);
                  } catch {
                    res.write(`${line}\n`);
                  }
                } else {
                  res.write(`\n`);
                }
              } else if (line.length > 0) {
                res.write(`${line}\n`);
              } else {
                res.write(`\n`);
              }
            }
          }

          if (buffer.trim()) {
            const trimmed = buffer.trim();
            if (trimmed.startsWith('data:')) {
              const dataPayload = trimmed.slice(5).trim();
              if (dataPayload === '[DONE]') {
                res.write(`data: [DONE]\n\n`);
              } else if (dataPayload) {
                try {
                  const parsed = JSON.parse(dataPayload);
                  if (!parsed.model || parsed.model === '') {
                    parsed.model = requestedModel;
                  }
                  if (!parsed.id || parsed.id === '') {
                    parsed.id = fallbackId;
                  }
                  if (!parsed.created || parsed.created === 0) {
                    parsed.created = fallbackCreated;
                  }
                  res.write(`data: ${JSON.stringify(parsed)}\n\n`);
                } catch {
                  res.write(`${buffer}\n`);
                }
              }
            } else {
              res.write(`${buffer}\n`);
            }
          }

          res.end();
          const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
          console.log(`[Compressor Proxy] <- Stream complete in ${elapsed}s (${totalBytes} bytes).`);
        } else {
          const json = await upstreamRes.json();
          if (!json.model || json.model === '') {
            json.model = requestedModel;
          }
          if (!json.id || json.id === '') {
            json.id = fallbackId;
          }
          if (!json.created || json.created === 0) {
            json.created = fallbackCreated;
          }
          const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
          console.log(`[Compressor Proxy] <- Response complete in ${elapsed}s.`);
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify(json));
        }
      } catch (err) {
        console.error('[Compressor Proxy Error]:', err);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Proxy internal error', message: err.message }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end('Not Found');
});

server.listen(PROXY_PORT, '127.0.0.1', () => {
  console.log(`================================================================`);
  console.log(`⚡ Prompt Compressor Proxy running on http://127.0.0.1:${PROXY_PORT}`);
  console.log(`   - Compresses 3,000+ token OpenClaw prompts down to ~40 tokens`);
  console.log(`   - Routes to GenieX NPU (18181) e GPU (18184/18185/18183)`);
  console.log(`================================================================`);
});
