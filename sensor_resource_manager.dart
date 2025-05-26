import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// A resource manager for sensor usage in the step counter
class SensorResourceManager {
  static final SensorResourceManager _instance = SensorResourceManager._internal();
  factory SensorResourceManager() => _instance;
  
  SensorResourceManager._internal();
  
  // Resource allocation tracking
  final Map<String, _SensorResource> _resources = {};
  
  // Sensor subscriptions
  final Map<String, StreamSubscription?> _subscriptions = {
    'accelerometer': null,
    'gyroscope': null,
    'userAccelerometer': null,
    'magnetometer': null,
  };
  
  // Sensor data streams
  final Map<String, StreamController<dynamic>> _streamControllers = {
    'accelerometer': StreamController<AccelerometerEvent>.broadcast(),
    'gyroscope': StreamController<GyroscopeEvent>.broadcast(),
    'userAccelerometer': StreamController<UserAccelerometerEvent>.broadcast(),
    'magnetometer': StreamController<MagnetometerEvent>.broadcast(),
  };
  
  // Sensor data
  final Map<String, dynamic> _latestData = {};
  
  // Sensor sampling rates (in milliseconds)
  final Map<String, int> _samplingRates = {
    'accelerometer': 50,      // 20Hz
    'gyroscope': 100,         // 10Hz
    'userAccelerometer': 50,  // 20Hz
    'magnetometer': 200,      // 5Hz
  };
  
  // Battery optimization flags
  bool _batteryOptimizationEnabled = true;
  bool _lowPowerMode = false;
  
  /// Initialize the sensor resource manager
  void initialize() {
    debugPrint('Initializing sensor resource manager');
  }
  
  /// Request access to a sensor resource
  /// Returns a stream of sensor data
  Stream<T> requestResource<T>(
    String resourceName,
    String clientId,
    {
      ResourcePriority priority = ResourcePriority.normal,
      bool exclusive = false,
    }
  ) {
    // Check if the resource exists
    if (!_streamControllers.containsKey(resourceName)) {
      throw Exception('Resource not found: $resourceName');
    }
    
    // Create or update the resource allocation
    final resource = _resources[resourceName] ?? _SensorResource(resourceName);
    resource.addClient(clientId, priority, exclusive);
    _resources[resourceName] = resource;
    
    // Start the sensor if it's not already running
    _startSensorIfNeeded(resourceName);
    
    // Adjust sampling rate based on priorities
    _adjustSamplingRate(resourceName);
    
    // Return the stream
    return _streamControllers[resourceName]!.stream as Stream<T>;
  }
  
  /// Release a sensor resource
  void releaseResource(String resourceName, String clientId) {
    // Check if the resource exists
    if (!_resources.containsKey(resourceName)) {
      return;
    }
    
    // Remove the client from the resource
    final resource = _resources[resourceName]!;
    resource.removeClient(clientId);
    
    // If there are no more clients, stop the sensor
    if (resource.clients.isEmpty) {
      _stopSensor(resourceName);
      _resources.remove(resourceName);
    } else {
      // Adjust sampling rate based on remaining clients
      _adjustSamplingRate(resourceName);
    }
  }
  
  /// Start a sensor if it's not already running
  void _startSensorIfNeeded(String resourceName) {
    if (_subscriptions[resourceName] != null) {
      return; // Already running
    }
    
    switch (resourceName) {
      case 'accelerometer':
        _subscriptions[resourceName] = accelerometerEvents.listen((event) {
          _latestData[resourceName] = event;
          _streamControllers[resourceName]!.add(event);
        });
        break;
      case 'gyroscope':
        _subscriptions[resourceName] = gyroscopeEvents.listen((event) {
          _latestData[resourceName] = event;
          _streamControllers[resourceName]!.add(event);
        });
        break;
      case 'userAccelerometer':
        _subscriptions[resourceName] = userAccelerometerEvents.listen((event) {
          _latestData[resourceName] = event;
          _streamControllers[resourceName]!.add(event);
        });
        break;
      case 'magnetometer':
        _subscriptions[resourceName] = magnetometerEvents.listen((event) {
          _latestData[resourceName] = event;
          _streamControllers[resourceName]!.add(event);
        });
        break;
    }
    
    debugPrint('Started sensor: $resourceName');
  }
  
  /// Stop a sensor
  void _stopSensor(String resourceName) {
    _subscriptions[resourceName]?.cancel();
    _subscriptions[resourceName] = null;
    debugPrint('Stopped sensor: $resourceName');
  }
  
  /// Adjust the sampling rate based on client priorities
  void _adjustSamplingRate(String resourceName) {
    if (!_resources.containsKey(resourceName)) {
      return;
    }
    
    final resource = _resources[resourceName]!;
    
    // Get the highest priority client
    ResourcePriority highestPriority = ResourcePriority.low;
    for (final client in resource.clients.values) {
      if (client.priority.index > highestPriority.index) {
        highestPriority = client.priority;
      }
    }
    
    // Adjust sampling rate based on priority
    int baseSamplingRate = _samplingRates[resourceName] ?? 100;
    int adjustedRate;
    
    switch (highestPriority) {
      case ResourcePriority.critical:
        adjustedRate = (baseSamplingRate * 0.5).round(); // 2x faster
        break;
      case ResourcePriority.high:
        adjustedRate = (baseSamplingRate * 0.75).round(); // 1.33x faster
        break;
      case ResourcePriority.normal:
        adjustedRate = baseSamplingRate; // Normal rate
        break;
      case ResourcePriority.low:
        adjustedRate = baseSamplingRate * 2; // Half the rate
        break;
      case ResourcePriority.background:
        adjustedRate = baseSamplingRate * 4; // Quarter the rate
        break;
    }
    
    // Apply battery optimization if enabled
    if (_batteryOptimizationEnabled) {
      if (_lowPowerMode) {
        adjustedRate = adjustedRate * 2; // Half the rate in low power mode
      }
    }
    
    // Update the sampling rate
    // Note: In a real implementation, you would use platform-specific code to adjust the sensor rate
    debugPrint('Adjusted sampling rate for $resourceName: $adjustedRate ms');
  }
  
  /// Set battery optimization mode
  void setBatteryOptimization(bool enabled) {
    _batteryOptimizationEnabled = enabled;
    
    // Adjust all sampling rates
    for (final resourceName in _resources.keys) {
      _adjustSamplingRate(resourceName);
    }
  }
  
  /// Set low power mode
  void setLowPowerMode(bool enabled) {
    _lowPowerMode = enabled;
    
    if (_batteryOptimizationEnabled) {
      // Adjust all sampling rates
      for (final resourceName in _resources.keys) {
        _adjustSamplingRate(resourceName);
      }
    }
  }
  
  /// Get the latest sensor data
  dynamic getLatestData(String resourceName) {
    return _latestData[resourceName];
  }
  
  /// Check if a sensor is currently in use
  bool isResourceInUse(String resourceName) {
    return _resources.containsKey(resourceName) && 
           _resources[resourceName]!.clients.isNotEmpty;
  }
  
  /// Get the number of clients using a sensor
  int getClientCount(String resourceName) {
    if (!_resources.containsKey(resourceName)) {
      return 0;
    }
    return _resources[resourceName]!.clients.length;
  }
  
  /// Dispose of all resources
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription?.cancel();
    }
    _subscriptions.clear();
    
    // Close all stream controllers
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    
    // Clear all resources
    _resources.clear();
    _latestData.clear();
  }
}

/// Resource priority levels
enum ResourcePriority {
  background,  // Lowest priority, for background tasks
  low,         // Low priority, for non-critical tasks
  normal,      // Normal priority, for standard tasks
  high,        // High priority, for important tasks
  critical,    // Highest priority, for critical tasks
}

/// Client information
class _ClientInfo {
  final String id;
  final ResourcePriority priority;
  final bool exclusive;
  
  _ClientInfo({
    required this.id,
    required this.priority,
    required this.exclusive,
  });
}

/// Sensor resource allocation
class _SensorResource {
  final String name;
  final Map<String, _ClientInfo> clients = {};
  
  _SensorResource(this.name);
  
  /// Add a client to this resource
  void addClient(String clientId, ResourcePriority priority, bool exclusive) {
    // Check if this is an exclusive request
    if (exclusive) {
      // If there are existing clients, check if they can be preempted
      if (clients.isNotEmpty) {
        bool canPreempt = true;
        for (final client in clients.values) {
          if (client.priority.index >= priority.index) {
            canPreempt = false;
            break;
          }
        }
        
        if (canPreempt) {
          // Remove all existing clients
          clients.clear();
        } else {
          throw Exception('Cannot get exclusive access to $name: resource in use by higher priority client');
        }
      }
    } else {
      // Check if there's an exclusive client
      for (final client in clients.values) {
        if (client.exclusive) {
          throw Exception('Cannot access $name: resource is exclusively allocated');
        }
      }
    }
    
    // Add the client
    clients[clientId] = _ClientInfo(
      id: clientId,
      priority: priority,
      exclusive: exclusive,
    );
  }
  
  /// Remove a client from this resource
  void removeClient(String clientId) {
    clients.remove(clientId);
  }
} 