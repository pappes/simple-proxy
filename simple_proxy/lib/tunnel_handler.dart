import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pedantic/pedantic.dart';
import 'package:shelf/shelf.dart';

/// Submit serverRequest to the server
/// then send the recieved reply to the client.
Handler tunnelHandler() {
  return (serverRequest) async {
    print('routing request ${serverRequest.url.toString()}');
    print('query is ${serverRequest.url.queryParameters.toString()}');
    final clientRequest = prepareRequest(serverRequest);
    print('sending headers to server: ${clientRequest.headers}');

    unawaited(serverRequest
        .read()
        .forEach(clientRequest.sink.add)
        .catchError(clientRequest.sink.addError)
        .whenComplete(clientRequest.sink.close));
    final serverResponse = await http.Client().send(clientRequest);

    /// Prepare the response.
    modifyResponseHeaders(serverResponse.headers);
    print('sending headers to client: ${serverResponse.headers}');

    var content = await serverResponse.stream
        .transform(utf8.decoder)
        .reduce((value, element) => value + element);
    print('body is $content');

    /// Send the modified response to the client.
    return Response(
      serverResponse.statusCode,
      body: content, //serverResponse.stream,
      headers: serverResponse.headers,
    );
  };
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
  headers.remove('transfer-encoding');

  // If the client response was unzipped
  // the streamed body size will not be known to this lambda.
  if (headers['content-encoding'] == 'gzip') {
    headers.remove('content-encoding');
    headers.remove('content-length');
  }
}

http.StreamedRequest prepareRequest(Request serverRequest) {
  /// Prepare the request.
  final parameters = serverRequest.url.queryParameters;
  final requestedUrl = Uri.parse(parameters['destination']!);
  final clientRequest = http.StreamedRequest(serverRequest.method, requestedUrl)
    ..followRedirects = true
    ..headers['Host'] = requestedUrl.authority;
  modifyRequestHeaders(clientRequest.headers, parameters);
  return clientRequest;
}
