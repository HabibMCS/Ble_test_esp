import 'package:flutter_blue/flutter_blue.dart';

class BTService {
  final FlutterBlue _flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _services;
  BluetoothCharacteristic? _characteristic;

  // Discover devices
  Stream<List<BluetoothDevice>> get devices => _flutterBlue.scanResults.map(
        (results) => results.map(
            (result) => result.device
    ).toList(),
  );

  // Connect to a device
  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
    _connectedDevice = device;
    _services = await device.discoverServices();

    // ...
    BluetoothService targetService;

    if (_services != null && _services!.isNotEmpty) {
      targetService = _services!.firstWhere(
            (service) =>
        service.uuid == Guid("00001101-0000-1000-8000-00805F9B34FB"),
        orElse: () {
          throw Exception("Target service not found");
        },
      );
    } else {
      throw Exception("Services list is empty or null");
    }

    if (targetService.characteristics.isNotEmpty) {
      _characteristic = targetService.characteristics.first;
    } else {
      throw Exception("Characteristics list is empty for the target service");
    }
// ...

  }
    // Disconnect from a device
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _services = null;
    _characteristic = null;
  }

  // Write data to a device
  Future<void> writeData(List<int> bytes) async {
    if (_characteristic == null) throw Exception("Not connected or target characteristic not found!");
    await _characteristic!.write(bytes);
  }

  // Read data from a device

    Stream<List<int>> get readData {
      if (_characteristic != null) {
        return _characteristic!.value;
      } else {
        return const Stream.empty();
      }
    }

  }
