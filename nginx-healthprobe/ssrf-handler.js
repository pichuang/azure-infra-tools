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

function reflectionResponse(r) {
  return {
    request_id: r.variables.correlation_id,
    http_status: 200,
    timestamp: r.variables.time_iso8601,
    request: {
      method: r.method,
      uri: r.variables.request_uri,
      url: `${r.variables.scheme}://${r.variables.http_host}`
        + r.variables.request_uri,
      http_version: r.variables.server_protocol,
      content_type: r.variables.content_type,
      content_length: r.variables.content_length,
    },
    headers: normalizedHeaders(r.rawHeadersIn),
    client: {
      ip: r.remoteAddress,
      port: r.variables.remote_port,
    },
  };
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

function consoleLog(r, response, body, bodyTruncated) {
  const lines = [
    `=== SSRF REQUEST ${'='.repeat(50)}`,
    `Time       : ${escapeConsole(response.timestamp, false)}`,
    `Request ID : ${escapeConsole(response.request_id, false)}`,
    `Client     : ${escapeConsole(response.client.ip, false)}:`
      + escapeConsole(response.client.port, false),
    `Request    : ${escapeConsole(response.request.method, false)} `
      + `${escapeConsole(response.request.url, false)} `
      + escapeConsole(response.request.http_version, false),
    'Headers:',
  ];

  if (r.rawHeadersIn.length === 0) {
    lines.push('  <none>');
  } else {
    for (let i = 0; i < r.rawHeadersIn.length; i++) {
      const name = escapeConsole(r.rawHeadersIn[i][0], false);
      const value = escapeConsole(r.rawHeadersIn[i][1], false);

      lines.push(`  ${name}: ${value}`);
    }
  }

  const truncation = bodyTruncated
    ? `, showing first ${BODY_LOG_LIMIT} bytes, truncated`
    : '';
  lines.push(`Body (${body.length} bytes${truncation}):`);

  if (body.length === 0) {
    lines.push('  <empty>');
  } else {
    const bodyText = escapeConsole(
      body.subarray(0, BODY_LOG_LIMIT).toString('utf8'),
      true,
    );
    lines.push(`  ${bodyText.split('\n').join('\n  ')}`);
  }

  lines.push(CONSOLE_SEPARATOR);
  return lines.join('\n');
}

function catchRequest(r) {
  const response = reflectionResponse(r);
  const body = r.requestBuffer || Buffer.from('');
  const loggedBody = body.subarray(0, BODY_LOG_LIMIT);
  const logEntry = reflectionResponse(r);

  logEntry.raw_headers = r.rawHeadersIn;
  logEntry.request_body = loggedBody.toString('utf8');
  logEntry.request_body_bytes = body.length;
  logEntry.request_body_truncated = body.length > BODY_LOG_LIMIT;

  r.variables.ssrf_log = JSON.stringify(logEntry);
  r.variables.ssrf_console_log = consoleLog(
    r,
    response,
    body,
    logEntry.request_body_truncated,
  );
  r.headersOut['Content-Type'] = 'application/json';
  r.return(200, JSON.stringify(response, null, 2));
}

export default { catchRequest };
