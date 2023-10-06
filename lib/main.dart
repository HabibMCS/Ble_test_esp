import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:eskom_ble/BluetoothPage.dart';
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Flutter BLE',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);  // Add this line

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue _flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _foundDevices = [];
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _messageController = TextEditingController();
  final _tokenController = TextEditingController();
  final _durationController = TextEditingController();
  String? _selectedCity;
  String? _selectedToken;
  List<String> _recentTokens = [];
  final List<String> _citiesOfSouthAfrica = [
    'Johannesburg',
    'Cape Town',
    'Durban',
    'Pretoria',
    'Port Elizabeth',
  ];

  int _selectedMode = 1; // 1 for Mode Token, 2 for Mode Custom

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ESP32 Flutter BLE')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(labelText: 'WiFi SSID'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'WiFi Password'),
              obscureText: true,
            ),
            SizedBox(height: 10),
            Text('Mode'),
            Row(
              children: <Widget>[
                Expanded(
                  child: ListTile(
                    title: const Text('Loadshedding'),
                    leading: Radio<int>(
                      value: 1,
                      groupValue: _selectedMode,
                      onChanged: (int? value) {
                        setState(() {
                          _selectedMode = value!;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Custom'),
                    leading: Radio<int>(
                      value: 2,
                      groupValue: _selectedMode,
                      onChanged: (int? value) {
                        setState(() {
                          _selectedMode = value!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedMode == 1) ...[
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(labelText: 'Token'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(labelText: 'Custom Message'),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedCity,
                hint: Text('Select a city'),
                items: _citiesOfSouthAfrica.map((city) {
                  return DropdownMenuItem(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value!;
                  });
                },
              ),
            ] else
              if (_selectedMode == 2) ...[
                // TextField(
                //   controller: _tokenController,
                //   decoration: InputDecoration(labelText: 'API Key'),
                // ),
                SizedBox(height: 10),
                TextField(
                  controller: _messageController,
                  decoration: InputDecoration(labelText: 'Custom Message'),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _durationController,
                  decoration: InputDecoration(labelText: 'Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Send Data to ESP32'),
              onPressed: _sendData,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Search for Devices'),
              onPressed: _scanForDevices,
            ),
            ..._foundDevices.map(
                  (device) =>
                  ListTile(
                    title: Text(device.name),
                    subtitle: Text(device.id.toString()),
                    onTap: () => _connectToDevice(device),
                  ),
            ),
            ElevatedButton(
              child: Text('Go to Bluetooth Page'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BluetoothPage()),
                );
              },
            ),

          ],
        ),
      ),
    );
  }
  _scanForDevices() async {
    _flutterBlue.startScan(timeout: Duration(seconds: 4));

    _flutterBlue.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!_foundDevices.contains(result.device)) {
          setState(() {
            _foundDevices.add(result.device);
          });
        }
      }
    });

    _flutterBlue.stopScan();
  }

  _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    setState(() {
      _connectedDevice = device;
    });
  }

  _sendData() async {
    if (_connectedDevice == null) return;
    List<BluetoothService> services = await _connectedDevice!.discoverServices();
    BluetoothCharacteristic? targetCharacteristic;

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        if (characteristic.properties.write &&
            characteristic.properties.notify) {
          targetCharacteristic = characteristic;
        }
      }
    }

    if (targetCharacteristic == null) return;

    String data = "SSID: ${_ssidController.text}, Password: ${_passwordController.text}, City: $_selectedCity";

    if (_selectedMode == 1) {
      data += ", Token: ${_tokenController.text}, Message: ${_messageController.text}";
      if (!_recentTokens.contains(_tokenController.text)) {
        setState(() {
          _recentTokens.add(_tokenController.text);
        });
      }
    } else if (_selectedMode == 2) {
      data += ", API Key: ${_tokenController.text}, Message: ${_messageController.text}, Duration: ${_durationController.text} minutes";
    }

    var dataToSend = utf8.encode(data);
    await targetCharacteristic.write(dataToSend);
  }


}

