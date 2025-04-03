import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkInfo {
  /// Получить и вывести информацию о сетевых интерфейсах
  static Future<void> printNetworkInterfaces() async {
    try {
      debugPrint('========== NETWORK INTERFACES ==========');

      // Получаем список всех сетевых интерфейсов
      final interfaces = await NetworkInterface.list(
          includeLoopback: true,
          includeLinkLocal: true,
          type: InternetAddressType.any
      );

      // Выводим информацию о каждом интерфейсе
      for (var interface in interfaces) {
        debugPrint('Interface: ${interface.name}');
        debugPrint('Index: ${interface.index}');

        // Выводим все адреса для этого интерфейса
        for (var address in interface.addresses) {
          debugPrint('  Address: ${address.address}');
          debugPrint('  Type: ${address.type.name}');
          debugPrint('  IsLoopback: ${address.isLoopback}');
          debugPrint('  IsLinkLocal: ${address.isLinkLocal}');
          debugPrint('  IsMulticast: ${address.isMulticast}');
        }

        debugPrint('--------------------------------------');
      }

      // Пытаемся определить, какие адреса могут быть доступны извне
      List<String> potentialReachableAddresses = [];

      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          // Исключаем петлевые (loopback) адреса
          if (!address.isLoopback) {
            // Предпочитаем IPv4 адреса
            if (address.type == InternetAddressType.IPv4) {
              potentialReachableAddresses.add(address.address);
            }
          }
        }
      }

      if (potentialReachableAddresses.isNotEmpty) {
        debugPrint('==== POTENTIALLY REACHABLE ADDRESSES ====');
        for (var address in potentialReachableAddresses) {
          debugPrint('  $address');
        }
      }

      debugPrint('========================================');
    } catch (e) {
      debugPrint('Error getting network interfaces: $e');
    }
  }
}