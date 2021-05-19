import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pedantic/pedantic.dart';
import 'package:shelf/shelf.dart';

var requestSeq = 0;

/// Submit serverRequest to the server
/// then send the recieved reply to the client.
Handler tunnelHandler(File log) {
  return (serverRequest) async {
    var correlationID = ++requestSeq;
    var url = serverRequest.url;
    await writelog(
      correlationID,
      log,
      'routing request ${url.toString()}\n query is ${url.queryParameters.toString()}',
      console: true,
    );
    var destination = url.queryParameters['destination'];
    if (destination == null) {
      return Response(404, body: 'malformed request');
    }

    final clientRequest = prepareRequest(destination, serverRequest);
    await writelog(correlationID, log,
        'sending headers to server: ${clientRequest.headers}');

    unawaited(
      serverRequest
          .read()
          .forEach(clientRequest.sink.add)
          .catchError(clientRequest.sink.addError)
          .whenComplete(clientRequest.sink.close),
    );
    final serverResponse = await http.Client().send(clientRequest);

    // Prepare the response.
    modifyResponseHeaders(serverResponse.headers);
    await writelog(correlationID, log,
        'sending headers to client: ${serverResponse.headers}');

    var content = await serverResponse.stream
        .transform(utf8.decoder)
        .reduce((value, element) => value + element);
    await writeTrace(
      correlationID,
      url.toString(),
      serverResponse.statusCode,
      serverResponse.headers,
      content,
    );

    await writelog(correlationID, log,
        'sending response to client http(${serverResponse.statusCode})\n',
        console: true);

    // Send the modified response to the client.
    return Response(
      serverResponse.statusCode,
      body: content,
      headers: serverResponse.headers,
    );
  };
}

Future<void> writeTrace(var correlationID, var request, var http_status,
    var headers, var body) async {
  var file = File('trace/${correlationID}_$http_status.trc');
  unawaited(
    file.writeAsString(
      'request: $request\n'
      'status: $http_status\n'
      'headers: $headers\n'
      'body: $body\n',
      flush: true,
    ),
  );
}

Future<void> writelog(var correlationID, File log, var text,
    {bool console = false}) async {
  if (console) print(text);
  await log.writeAsString(
    '\n${DateTime.now().toString()} $correlationID $text',
    mode: FileMode.writeOnlyAppend,
    flush: true,
  );
}

/// Add any headers requested by the client.
void modifyRequestHeaders(Map headers, Map parameters) {
  parameters.forEach((key, value) {
    if (key != 'destination') {
      headers[key] = value;
    }
  });
}

/// Add any headers required by the client.
void modifyResponseHeaders(Map headers) {
  headers['access-control-allow-origin'] = '*';
  headers.remove('transfer-encoding');

  /*headers.remove('connection');
  headers.remove('content-length');
  headers.remove('set-cookie');
  headers.remove('ad-unit');
  headers.remove('x-amz-cf-pop');
  headers.remove('vary');
  headers.remove('x-amz-cf-id');
  headers.remove('x-amz-rid');
  headers.remove('strict-transport-security');
  headers.remove('content-security-policy');
  headers.remove('Domain');
  headers.remove('server');
  headers.remove('via');*/

  // If the client response was unzipped
  // the streamed body size will not be known to this lambda.
  if (headers['content-encoding'] == 'gzip') {
    headers.remove('content-encoding');
    headers.remove('content-length');
  }
}

http.StreamedRequest prepareRequest(String destination, Request serverRequest) {
  /// Prepare the request.
  final parameters = serverRequest.url.queryParameters;
  final requestedUrl = Uri.parse(destination);
  final clientRequest = http.StreamedRequest(serverRequest.method, requestedUrl)
    ..followRedirects = true
    ..headers['Host'] = requestedUrl.authority;
  modifyRequestHeaders(clientRequest.headers, parameters);
  return clientRequest;
}
