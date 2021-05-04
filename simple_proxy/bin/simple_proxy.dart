import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:simple_proxy/tunnel_handler.dart';

void main() async {
  // If server does not close cleanly, need to kill the process to free the port
  // netstat -a -o |find "8080"
  // taskkill /F /PID 6848
  // Sample requrests:
  // http://localhost:8080/?origin=https://www.imdb.com&referer=https://www.imdb.com/&destination=https%3A%2F%2Fwww.imdb.com%2Ffind%3Fs%3Dtt%26ref_%3Dfn_al_tt_mr%26q%3Dcriteria
  // http://localhost:8080/?origin=https://www.google.com&referer=https://www.google.com/&destination=https%3A%2F%2Fwww.google.com%3Fq%3Dcriteria
  // http://localhost:8080/?origin=https://httpbin.org&referer=https://httpbin.org/&destination=https%3A%2F%2Fhttpbin.org%2Fanything%2Fcriteria

  var server = await shelf_io.serve(
    tunnelHandler(),
    'localhost',
    8080,
  );

  print('Tunneling web traffic at '
      'http://${server.address.host}:${server.port}\n'
      'If having trouble closing cleanly, kill with the command: '
      'taskkill /F /PID $pid');
}
