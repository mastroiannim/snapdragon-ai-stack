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
      { name: 'GPU-Gemma4E2B', url: 'http://127.0.0.1:18189' },
      { name: 'GPU-Phi4', url: 'http://127.0.0.1:18187' },
      { name: 'GPU-4B', url: 'http://127.0.0.1:18188' },
      { name: 'GPU-Gemma31B', url: 'http://127.0.0.1:18186' },
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

        // Case-insensitive strip of -caveman suffix and any wrapper tags
        let cleanModel = (payload.model || '').replace(/-caveman/gi, '').replace(/\(caveman\s*fast\)/gi, '').trim();

        // Determine target server based on model requested
        let currentTarget = UPSTREAM_URL; // Defaults to GenieX NPU (18181)
        const lowerModel = cleanModel.toLowerCase();

        if (lowerModel.includes('e2b') || lowerModel.includes('gemma4e2b') || lowerModel.includes('gemma-4-e2b') || (lowerModel.includes('gemma') && lowerModel.includes('2b'))) {
          // Gemma 4 uses the new peg-gemma4 chat template (<|turn>...<turn|>) supported natively by llama-server on GPU (port 18189).
          // GenieX NPU (18181) currently applies legacy Gemma 2 <start_of_turn> template, which causes <unusedXX> token loops.
          currentTarget = 'http://127.0.0.1:18189';
          cleanModel = 'Gemma-4-E2B-Adreno-GPU';
        } else if (lowerModel.includes('gpu-phi4') || (lowerModel.includes('phi') && lowerModel.includes('gpu'))) {
          currentTarget = 'http://127.0.0.1:18187';
          cleanModel = 'Phi-4-mini-instruct-Adreno-GPU';
        } else if (lowerModel.includes('phi-4') || lowerModel.includes('phi4')) {
          currentTarget = 'http://127.0.0.1:18181';
          if (!cleanModel.includes('/') && !cleanModel.includes(':')) {
            cleanModel = 'unsloth/Phi-4-mini-instruct-GGUF:Q4_K_M';
          }
        } else if (lowerModel.includes('gpu-4b') || (lowerModel.includes('4b') && lowerModel.includes('gpu')) || lowerModel.includes('qwen3-4b-adreno-gpu')) {
          currentTarget = 'http://127.0.0.1:18188';
          cleanModel = 'Qwen3-4B-Adreno-GPU';
        } else if (lowerModel.includes('4b') || lowerModel.includes('qwen3-4b')) {
          currentTarget = 'http://127.0.0.1:18181';
          if (!cleanModel.includes('/') && !cleanModel.includes(':')) {
            cleanModel = 'unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M';
          }
        } else if (lowerModel.includes('gemma') || lowerModel.includes('31b')) {
          currentTarget = 'http://127.0.0.1:18186';
          cleanModel = 'Gemma-4-31B-Adreno-GPU';
        } else if (lowerModel.includes('8b') && lowerModel.includes('gpu')) {
          currentTarget = 'http://127.0.0.1:18185';
          cleanModel = 'Qwen3-8B-Adreno-GPU';
        } else if (lowerModel.includes('27b') && lowerModel.includes('gpu')) {
          currentTarget = 'http://127.0.0.1:18184';
          cleanModel = 'Qwen3.8-27B-Adreno-GPU';
        } else if (lowerModel.includes('muse') || lowerModel.includes('vision')) {
          currentTarget = 'http://127.0.0.1:18183';
          cleanModel = 'Muse-Glimmer-30B-Vision-GPU';
        } else if (lowerModel.includes('8b') || lowerModel.includes('qwen3-8b')) {
          currentTarget = 'http://127.0.0.1:18181';
          if (!cleanModel.includes('/') && !cleanModel.includes(':')) {
            cleanModel = 'unsloth/Qwen3-8B-128K-GGUF:Q4_0';
          }
        } else if (lowerModel.includes('27b') || lowerModel.includes('qwen3.8-27b')) {
          currentTarget = 'http://127.0.0.1:18181';
          if (!cleanModel.includes('/') && !cleanModel.includes(':')) {
            cleanModel = 'IvanKrastevAdventics/Qwen3.8-27B-AWQ-INT4-Q4_0-GGUF:Q4_0';
          }
        }

        payload.model = cleanModel;

        // ULTRA PROMPT COMPRESSION: Strip heavy system prompt and format per-model
        if (Array.isArray(payload.messages)) {
          const isGemma = lowerModel.includes('gemma');
          const promptText = isGemma
            ? 'Sei un assistente AI avanzato. Rispondi sempre in italiano, in modo chiaro, utile, diretto e accurato.'
            : SLIM_SYSTEM_PROMPT;

          if (isGemma) {
            // Gemma does not support a separate 'system' role in its chat template.
            // Merge system instructions directly into the first user turn to avoid <unusedXX> multimodal token loops.
            payload.messages = payload.messages.filter(m => m.role !== 'system');
            const firstUserIdx = payload.messages.findIndex(m => m.role === 'user');
            if (firstUserIdx >= 0) {
              payload.messages[firstUserIdx].content = `${promptText}\n\n${payload.messages[firstUserIdx].content}`;
            } else {
              payload.messages.unshift({ role: 'user', content: promptText });
            }
          } else {
            const sysIdx = payload.messages.findIndex(m => m.role === 'system');
            if (sysIdx >= 0) {
              payload.messages[sysIdx].content = promptText;
            } else {
              payload.messages.unshift({ role: 'system', content: promptText });
            }
          }
        }

        // Strip heavy tool schemas from prompt
        delete payload.tools;
        delete payload.tool_choice;

        // Map endpoints to their native model alias for fallback adaptation
        const endpointModelMap = {
          'http://127.0.0.1:18189': 'Gemma-4-E2B-Adreno-GPU',
          'http://127.0.0.1:18187': 'Phi-4-mini-instruct-Adreno-GPU',
          'http://127.0.0.1:18188': 'Qwen3-4B-Adreno-GPU',
          'http://127.0.0.1:18186': 'Gemma-4-31B-Adreno-GPU',
          'http://127.0.0.1:18184': 'Qwen3.8-27B-Adreno-GPU',
          'http://127.0.0.1:18185': 'Qwen3-8B-Adreno-GPU',
          'http://127.0.0.1:18181': 'unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M',
          'http://127.0.0.1:18183': 'Muse-Glimmer-30B-Vision-GPU'
        };

        const fallbackEndpoints = [
          currentTarget,
          'http://127.0.0.1:18189',
          'http://127.0.0.1:18187',
          'http://127.0.0.1:18188',
          'http://127.0.0.1:18186',
          'http://127.0.0.1:18184',
          'http://127.0.0.1:18185',
          'http://127.0.0.1:18181',
          'http://127.0.0.1:18183'
        ];
        // Deduplicate with primary target first
        const uniqueEndpoints = [...new Set(fallbackEndpoints)];

        let upstreamRes = null;
        let activeTargetUrl = '';
        const startTime = Date.now();
        const attemptedErrors = [];

        const PRIMARY_TIMEOUT_MS = parseInt(process.env.PRIMARY_TIMEOUT_MS || '900000', 10); // 15 min for 64K token prompts

        for (let i = 0; i < uniqueEndpoints.length; i++) {
          const ep = uniqueEndpoints[i];
          const isPrimary = (i === 0);
          const maxRetries = isPrimary ? 3 : 1;
          const initialDelayMs = 300;

          // Adapt model payload if falling back to an alternative server
          const epPayload = { ...payload };
          if (!isPrimary && endpointModelMap[ep]) {
            epPayload.model = endpointModelMap[ep];
          }

          const targetUrl = `${ep}${url.pathname}${url.search}`;

          for (let attempt = 1; attempt <= maxRetries; attempt++) {
            try {
              if (attempt === 1) {
                console.log(`[Compressor Proxy] Ingesting request -> Forwarding compressed prompt (${epPayload.messages?.length || 0} msgs) to ${targetUrl}...`);
              }
              upstreamRes = await fetch(targetUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(epPayload),
                signal: AbortSignal.timeout(isPrimary ? PRIMARY_TIMEOUT_MS : 2500)
              });
              activeTargetUrl = targetUrl;
              if (attempt > 1) {
                console.log(`[Compressor Proxy] ⚡ Connection restored to ${targetUrl} on attempt ${attempt}!`);
              }
              break;
            } catch (err) {
              const errCode = err.cause?.code || err.code || err.message;
              if (attempt < maxRetries) {
                const delay = initialDelayMs * Math.pow(2, attempt - 1);
                console.warn(`[Compressor Proxy] Target ${ep} busy or transient error (${errCode}). Retrying in ${delay}ms (tentativo ${attempt}/${maxRetries})...`);
                await new Promise(r => setTimeout(r, delay));
              } else {
                attemptedErrors.push(`${ep} (${errCode})`);
                if (isPrimary) {
                  console.warn(`[Compressor Proxy] Primary target ${ep} failed after ${maxRetries} attempts (${errCode}). Trying fallbacks...`);
                } else {
                  console.warn(`[Compressor Proxy] Fallback endpoint ${ep} not reachable (${errCode}).`);
                }
              }
            }
          }

          if (upstreamRes) {
            break;
          }
        }

        if (!upstreamRes) {
          throw new Error(`Nessun server AI locale raggiungibile. Endpoint testati: ${attemptedErrors.join(', ')}.`);
        }

        if (!upstreamRes.ok) {
          const errText = await upstreamRes.text();
          if (!res.headersSent) {
            res.writeHead(upstreamRes.status, { 'Content-Type': 'application/json' });
            res.end(errText);
          }
          return;
        }

        const fallbackId = 'chatcmpl-' + Math.random().toString(36).substring(2, 15);
        const fallbackCreated = Math.floor(Date.now() / 1000);

        if (payload.stream) {
          if (!res.headersSent) {
            res.writeHead(200, {
              'Content-Type': 'text/event-stream',
              'Cache-Control': 'no-cache',
              'Connection': 'keep-alive'
            });
          }

          const decoder = new TextDecoder();
          const reader = upstreamRes.body.getReader();
          let totalBytes = 0;
          let buffer = '';

          try {
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
          } finally {
            res.end();
            const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
            console.log(`[Compressor Proxy] <- Stream complete in ${elapsed}s (${totalBytes} bytes).`);
          }
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
          if (!res.headersSent) {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(json));
          }
        }
      } catch (err) {
        console.error('[Compressor Proxy Error]:', err.message || err);
        if (!res.headersSent) {
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Proxy internal error', message: err.message }));
        } else {
          res.end();
        }
      }
    });
    return;
  }

  res.writeHead(404);
  res.end('Not Found');
});

process.on('uncaughtException', (err) => {
  console.error('[Compressor Proxy Uncaught Exception]:', err.message || err);
});

process.on('unhandledRejection', (reason) => {
  console.error('[Compressor Proxy Unhandled Rejection]:', reason?.message || reason);
});

server.listen(PROXY_PORT, '127.0.0.1', () => {
  console.log(`================================================================`);
  console.log(`⚡ Prompt Compressor Proxy running on http://127.0.0.1:${PROXY_PORT}`);
  console.log(`   - Compresses 3,000+ token OpenClaw prompts down to ~40 tokens`);
  console.log(`   - Routes to GenieX NPU (18181) e GPU (18189/18187/18188/18186/18184/18185/18183)`);
  console.log(`   - Context window support: up to 65,536 tokens (Timeout: 15 min)`);
  console.log(`================================================================`);
});
