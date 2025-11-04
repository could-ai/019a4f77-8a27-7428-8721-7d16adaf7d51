import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MosiTradeApp());
}

class MosiTradeApp extends StatelessWidget {
  const MosiTradeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mositrade',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const EntryListPage(),
      routes: {
        '/': (context) => const EntryListPage(),
      },
    );
  }
}

class JournalEntry {
  final DateTime date;
  final String symbol;
  final double amount;
  final double price;
  final String notes;

  JournalEntry({
    required this.date,
    required this.symbol,
    required this.amount,
    required this.price,
    required this.notes,
  });
}

class EntryListPage extends StatefulWidget {
  const EntryListPage({Key? key}) : super(key: key);

  @override
  _EntryListPageState createState() => _EntryListPageState();
}

class _EntryListPageState extends State<EntryListPage> {
  final List<JournalEntry> _entries = [];

  void _addEntry(JournalEntry entry) {
    setState(() {
      _entries.add(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mositrade - ژورنال معاملات کریپتو'),
        centerTitle: true,
      ),
      body: _entries.isEmpty
          ? const Center(
              child: Text('هیچ ورودی‌ای وجود ندارد. برای افزودن، دکمه + را فشار دهید.'),
            )
          : ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ListTile(
                  title: Text('${entry.symbol} - ${entry.amount}'),
                  subtitle: Text(
                      'تاریخ: ${entry.date.toLocal().toString().split(' ')[0]} | قیمت: ${entry.price}'),
                  onTap: () => _showEntryDetails(entry),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<JournalEntry>(
            context,
            MaterialPageRoute(builder: (context) => const AddEntryPage()),
          );
          if (result != null) {
            _addEntry(result);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEntryDetails(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${entry.symbol} - جزئیات'),
        content: Text(
          'تاریخ: ${entry.date.toLocal().toString().split(' ')[0]}
مقدار: ${entry.amount}
قیمت: ${entry.price}
یادداشت: ${entry.notes}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }
}

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({Key? key}) : super(key: key);

  @override
  _AddEntryPageState createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  final _symbolController = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2009),
      lastDate: DateTime.now(),
      locale: const Locale('fa'),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('افزودن ورودی جدید'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: _pickDate,
                  child: Text('تاریخ: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                ),
                TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(labelText: 'نماد (مثلاً BTC)'),
                  validator: (value) => value == null || value.isEmpty ? 'لطفاً نماد را وارد کنید' : null,
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'مقدار'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'لطفاً مقدار را وارد کنید';
                    if (double.tryParse(value) == null) return 'عدد معتبر وارد کنید';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'قیمت'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'لطفاً قیمت را وارد کنید';
                    if (double.tryParse(value) == null) return 'عدد معتبر وارد کنید';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'یادداشت'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final entry = JournalEntry(
                        date: _selectedDate,
                        symbol: _symbolController.text.trim(),
                        amount: double.parse(_amountController.text.trim()),
                        price: double.parse(_priceController.text.trim()),
                        notes: _notesController.text.trim(),
                      );
                      Navigator.pop(context, entry);
                    }
                  },
                  child: const Text('ذخیره'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
