import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletProvider with ChangeNotifier {
  double _balance = 0.0;

  double get balance => _balance;

  WalletProvider() {
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _balance = prefs.getDouble('wallet_balance') ?? 0.0;
    notifyListeners();
  }

  Future<void> _saveBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('wallet_balance', _balance);
  }

  void addPoints(double points) {
    _balance += points;
    _saveBalance();
    notifyListeners();
  }

  void deductPoints(double points) {
    if (_balance >= points) {
      _balance -= points;
      _saveBalance();
      notifyListeners();
    }
  }
}
