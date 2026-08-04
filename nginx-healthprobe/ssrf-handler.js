const BODY_LOG_LIMIT = 64 * 1024;
const CONSOLE_SEPARATOR =
  '===================================================================';

function normalizedHeaders(rawHeaders) {
  const headers = Object.create(null);

  for (let i = 0; i < rawHeaders.length; i++) {
    const name = rawHeaders[i][0].toLowerCase();
    const value = rawHeaders[i][1];

    if (headers[name] === undefined) {
      headers[name] = value;
    } else if (Array.isArray(headers[name])) {
      headers[name].push(value);
    } else {
      headers[name] = [headers[name], value];
    }
  }

  return headers;
}

function headerValue(headers, name) {
  return headers[name] === undefined ? null : headers[name];
}

function reflectionEvent(r, body) {
  const startedAt = Date.now();
  const headers = normalizedHeaders(r.rawHeadersIn);
  const capturedBody = body.subarray(0, BODY_LOG_LIMIT);

  const event = {
      request_id: r.variables.correlation_id,
      http_status: 200,
      timestamp: r.variables.time_iso8601,
      request: {
        method: r.method,
        scheme: r.variables.scheme,
        host: r.variables.http_host,
        path: r.variables.uri,
        query: r.variables.args || '',
        uri: r.variables.request_uri,
        url: `${r.variables.scheme}://${r.variables.http_host}`
          + r.variables.request_uri,
        http_version: r.variables.server_protocol,
        content_type: r.variables.content_type || null,
        content_length: r.variables.content_length || null,
      },
      headers,
      raw_headers: r.rawHeadersIn,
      body: {
        text: capturedBody.toString('utf8'),
        encoding: 'utf-8',
        bytes: body.length,
        captured_bytes: capturedBody.length,
        truncated: body.length > BODY_LOG_LIMIT,
        limit_bytes: BODY_LOG_LIMIT,
      },
      client: {
        ip: r.remoteAddress,
        port: r.variables.remote_port,
        source: 'socket',
      },
      declared_forwarding: {
        trusted: false,
        forwarded: headerValue(headers, 'forwarded'),
        x_forwarded_for: headerValue(headers, 'x-forwarded-for'),
        x_real_ip: headerValue(headers, 'x-real-ip'),
      },
      server: {
        address: r.variables.server_addr,
        port: r.variables.server_port,
        hostname: r.variables.hostname,
      },
      timing: {
        handler_ms: 0,
      },
  };

  event.timing.handler_ms = Date.now() - startedAt;
  return event;
}

function escapeConsole(value, preserveNewlines) {
  const text = String(value);
  let escaped = '';

  for (let i = 0; i < text.length; i++) {
    const code = text.charCodeAt(i);
    const character = text[i];

    if (code === 10) {
      escaped += preserveNewlines ? '\n' : '\\n';
    } else if (code === 13) {
      escaped += '\\r';
    } else if (code === 9) {
      escaped += '\\t';
    } else if (code < 32 || code === 127) {
      escaped += `\\x${code.toString(16).padStart(2, '0')}`;
    } else {
      escaped += character;
    }
  }

  return escaped;
}

function consoleLog(event) {
  const lines = [
    `=== SSRF REQUEST ${'='.repeat(50)}`,
    `Time       : ${escapeConsole(event.timestamp, false)}`,
    `Request ID : ${escapeConsole(event.request_id, false)}`,
    `Client     : ${escapeConsole(event.client.ip, false)}:`
      + escapeConsole(event.client.port, false),
    `Server     : ${escapeConsole(event.server.address, false)}:`
      + `${escapeConsole(event.server.port, false)} `
      + `(${escapeConsole(event.server.hostname, false)})`,
    `Request    : ${escapeConsole(event.request.method, false)} `
      + `${escapeConsole(event.request.url, false)} `
      + escapeConsole(event.request.http_version, false),
    `Forwarded  : untrusted; Forwarded=${escapeConsole(
      event.declared_forwarding.forwarded,
      false,
    )}; X-Forwarded-For=${escapeConsole(
      event.declared_forwarding.x_forwarded_for,
      false,
    )}; X-Real-IP=${escapeConsole(
      event.declared_forwarding.x_real_ip,
      false,
    )}`,
    'Headers:',
  ];

  if (event.raw_headers.length === 0) {
    lines.push('  <none>');
  } else {
    for (let i = 0; i < event.raw_headers.length; i++) {
      const name = escapeConsole(event.raw_headers[i][0], false);
      const value = escapeConsole(event.raw_headers[i][1], false);

      lines.push(`  ${name}: ${value}`);
    }
  }

  const truncation = event.body.truncated
    ? `, showing first ${BODY_LOG_LIMIT} bytes, truncated`
    : '';
  lines.push(`Body (${event.body.bytes} bytes${truncation}):`);

  if (event.body.bytes === 0) {
    lines.push('  <empty>');
  } else {
    const bodyText = escapeConsole(event.body.text, true);
    lines.push(`  ${bodyText.split('\n').join('\n  ')}`);
  }

  lines.push(CONSOLE_SEPARATOR);
  return lines.join('\n');
}

function catchRequest(r) {
  const body = r.requestBuffer || Buffer.from('');
  const event = reflectionEvent(r, body);

  r.variables.ssrf_log = JSON.stringify(event);
  r.variables.ssrf_console_log = consoleLog(event);
  r.headersOut['Content-Type'] = 'application/json';
  r.return(200, JSON.stringify(event, null, 2));
}

export default { catchRequest };
