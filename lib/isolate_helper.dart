import 'dart:isolate';

class IsolateHelper {
  static Future<void> execute(SendPort sendPort) async {
    // Create a new ReceivePort to send results back to the main isolate
    final ReceivePort receivePort = ReceivePort();

    // // Notify the main isolate by sending the new ReceivePort's SendPort
    // sendPort.send(receivePort.sendPort);

    // Counting loop (simulate a long-running task)
    for (int i = 1; i <= 1000000000000000; i++) {
      // Simulate delay to prevent blocking (optional)
      await Future.delayed(const Duration(milliseconds: 1));

      // Send the count result back to the main isolate
      sendPort.send(i);
    }

    // Close the port once counting is complete
    receivePort.close();
  }
}
