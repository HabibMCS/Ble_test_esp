import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:eskom_ble/BTService.dart'; // Adjust the import path accordingly.

class BluetoothPage extends StatefulWidget {
  BluetoothPage({Key? key}) : super(key: key);  // Add this line

  @override
  _BluetoothPageState createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final BTService _bluetoothService = BTService();
  Future<void>? _connectFuture;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Devices")),
      body: StreamBuilder<List<BluetoothDevice>>(
        stream: _bluetoothService.devices,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text("Error: ${snapshot.error}");
          if (!snapshot.hasData) return const CircularProgressIndicator();

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final device = snapshot.data![index];
              return ListTile(
                title: Text(device.name),
                subtitle: Text(device.id.toString()),
                onTap: () {
                  _connectFuture = _bluetoothService.connect(device);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return FutureBuilder<void>(
                        future: _connectFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (snapshot.hasError) {
                              return AlertDialog(
                                title: Text("Error"),
                                content: Text("${snapshot.error}"),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text("Close"),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            } else {
                              return AlertDialog(
                                title: const Text("Connected"),
                                content: const Text("Device connected successfully."),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("Close"),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            }
                          } else {
                            return const AlertDialog(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 16),
                                  Text("Connecting..."),
                                ],
                              ),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
