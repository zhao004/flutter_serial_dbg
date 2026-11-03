import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_serial_dbg/app/models/connection_config.dart';
import 'package:flutter_serial_dbg/app/models/transport_event.dart';
import 'package:flutter_serial_dbg/app/services/transport/tcp_transport.dart';
import 'package:flutter_serial_dbg/app/services/transport/udp_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TCP client exchanges bytes with a loopback server', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final serverReceived = Completer<Uint8List>();
    late final StreamSubscription<Socket> serverSubscription;
    serverSubscription = server.listen((socket) {
      socket.listen((data) {
        if (!serverReceived.isCompleted) {
          serverReceived.complete(Uint8List.fromList(data));
        }
        socket.add(const <int>[0xAA, 0x10]);
      }, onDone: socket.destroy);
    });
    final transport = TcpClientTransport();
    final events = _TransportEventQueue(transport.events);
    addTearDown(() async {
      await events.dispose();
      await transport.dispose();
      await serverSubscription.cancel();
      await server.close();
    });

    await transport.connect(
      TcpClientConfig(host: '127.0.0.1', port: server.port),
    );
    expect(await events.next(), isA<TransportConnected>());

    await transport.send(Uint8List.fromList(<int>[0x01, 0x02]));
    expect(await serverReceived.future.timeout(_timeout), <int>[0x01, 0x02]);

    final received = await events.next();
    expect(received, isA<TransportDataReceived>());
    expect((received as TransportDataReceived).bytes, <int>[0xAA, 0x10]);
  });

  test('TCP server accepts one client and exchanges bytes', () async {
    final port = await _freeTcpPort();
    final transport = TcpServerTransport();
    final events = _TransportEventQueue(transport.events);
    Socket? client;
    addTearDown(() async {
      client?.destroy();
      await events.dispose();
      await transport.dispose();
    });

    await transport.connect(
      TcpServerConfig(bindAddress: '127.0.0.1', port: port),
    );
    expect(await events.next(), isA<TransportConnected>());

    final connectedClient = await Socket.connect(
      InternetAddress.loopbackIPv4,
      port,
    );
    client = connectedClient;
    expect(await events.next(), isA<TransportConnected>());
    final clientReceived = Completer<Uint8List>();
    connectedClient.listen((data) {
      if (!clientReceived.isCompleted) {
        clientReceived.complete(Uint8List.fromList(data));
      }
    });

    await transport.send(Uint8List.fromList(<int>[0x20]));
    expect(await clientReceived.future.timeout(_timeout), <int>[0x20]);

    connectedClient.add(Uint8List.fromList(<int>[0x30, 0x31]));
    await connectedClient.flush();
    final received = await events.next();
    expect(received, isA<TransportDataReceived>());
    expect((received as TransportDataReceived).bytes, <int>[0x30, 0x31]);
  });

  test('TCP server disconnects cleanly before a peer connects', () async {
    final port = await _freeTcpPort();
    final transport = TcpServerTransport();
    final events = _TransportEventQueue(transport.events);
    addTearDown(() async {
      await events.dispose();
      await transport.dispose();
    });

    await transport.connect(
      TcpServerConfig(bindAddress: '127.0.0.1', port: port),
    );
    expect(await events.next(), isA<TransportConnected>());

    await transport.disconnect();

    expect(await events.next(), isA<TransportDisconnected>());
    expect(transport.isConnected, isFalse);
  });

  test('UDP client and server exchange datagrams', () async {
    final port = await _freeUdpPort();
    final server = UdpServerTransport();
    final client = UdpClientTransport();
    final serverEvents = _TransportEventQueue(server.events);
    final clientEvents = _TransportEventQueue(client.events);
    addTearDown(() async {
      await clientEvents.dispose();
      await serverEvents.dispose();
      await client.dispose();
      await server.dispose();
    });

    await server.connect(UdpServerConfig(bindAddress: '127.0.0.1', port: port));
    await client.connect(UdpClientConfig(host: '127.0.0.1', port: port));
    expect(await serverEvents.next(), isA<TransportConnected>());
    expect(await clientEvents.next(), isA<TransportConnected>());

    await client.send(Uint8List.fromList(<int>[0x10, 0x11]));
    final serverData = await serverEvents.next();
    expect(serverData, isA<TransportDataReceived>());
    expect((serverData as TransportDataReceived).bytes, <int>[0x10, 0x11]);

    await server.send(Uint8List.fromList(<int>[0x20, 0x21]));
    final clientData = await clientEvents.next();
    expect(clientData, isA<TransportDataReceived>());
    expect((clientData as TransportDataReceived).bytes, <int>[0x20, 0x21]);
  });
}

const Duration _timeout = Duration(seconds: 5);

final class _TransportEventQueue {
  _TransportEventQueue(Stream<TransportEvent> stream) {
    _subscription = stream.listen(
      (event) {
        if (_waiters.isNotEmpty) {
          _waiters.removeFirst().complete(event);
        } else {
          _events.add(event);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        while (_waiters.isNotEmpty) {
          _waiters.removeFirst().completeError(error, stackTrace);
        }
      },
    );
  }

  final Queue<TransportEvent> _events = Queue<TransportEvent>();
  final Queue<Completer<TransportEvent>> _waiters =
      Queue<Completer<TransportEvent>>();
  late final StreamSubscription<TransportEvent> _subscription;

  Future<TransportEvent> next() {
    if (_events.isNotEmpty) {
      return Future<TransportEvent>.value(_events.removeFirst());
    }
    final completer = Completer<TransportEvent>();
    _waiters.add(completer);
    return completer.future.timeout(_timeout);
  }

  Future<void> dispose() => _subscription.cancel();
}

Future<int> _freeTcpPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<int> _freeUdpPort() async {
  final socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  socket.close();
  return port;
}
