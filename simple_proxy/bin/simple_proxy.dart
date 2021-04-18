import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:simple_proxy/tunnel_handler.dart';

void main() async {
  // If server does not close cleanly, need to kill the process to free the port
  // netstat -a -o |find "8080"
  // taskkill /F /PID 6848

  var server = await shelf_io.serve(
    tunnelHandler(),
    'localhost',
    8080,
  );

  print(
      'Tunneling web traffic at http://${server.address.host}:${server.port}');
}
