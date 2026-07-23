const BODY_LOG_LIMIT = 64 * 1024;

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
  r.headersOut['Content-Type'] = 'application/json';
  r.return(200, JSON.stringify(response, null, 2));
}

export default { catchRequest };
