import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto', // Or a Persian font if available
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const EntryListPage(),
      routes: {
        '/': (context) => const EntryListPage(),
        '/add': (context) => const AddEntryPage(),
        '/stats': (context) => const StatsPage(),
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
  final bool isBuy; // New field for buy/sell

  JournalEntry({
    required this.date,
    required this.symbol,
    required this.amount,
    required this.price,
    required this.notes,
    this.isBuy = true,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'symbol': symbol,
    'amount': amount,
    'price': price,
    'notes': notes,
    'isBuy': isBuy,
  };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    date: DateTime.parse(json['date']),
    symbol: json['symbol'],
    amount: json['amount'],
    price: json['price'],
    notes: json['notes'],
    isBuy: json['isBuy'] ?? true,
  );
}

class EntryListPage extends StatefulWidget {
  const EntryListPage({Key? key}) : super(key: key);

  @override
  _EntryListPageState createState() => _EntryListPageState();
}

class _EntryListPageState extends State<EntryListPage> {
  List<JournalEntry> _entries = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList('entries') ?? [];
    setState(() {
      _entries = entriesJson.map((e) => JournalEntry.fromJson(jsonDecode(e))).toList();
      _isLoading = false;
    });
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = _entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('entries', entriesJson);
  }

  void _addEntry(JournalEntry entry) {
    setState(() {
      _entries.add(entry);
      _saveEntries();
    });
  }

  void _editEntry(int index, JournalEntry entry) {
    setState(() {
      _entries[index] = entry;
      _saveEntries();
    });
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _saveEntries();
    });
  }

  List<JournalEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    return _entries.where((entry) =>
      entry.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      entry.notes.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mositrade - ژورنال معاملات کریپتو'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.pushNamed(context, '/stats'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'جستجو بر اساس نماد یا یادداشت',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Expanded(
                  child: _filteredEntries.isEmpty
                      ? const Center(
                          child: Text('هیچ ورودی‌ای وجود ندارد. برای افزودن، دکمه + را فشار دهید.'),
                        )
                      : ListView.builder(
                          itemCount: _filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredEntries[index];
                            final originalIndex = _entries.indexOf(entry);
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: entry.isBuy ? Colors.green : Colors.red,
                                  child: Icon(entry.isBuy ? Icons.trending_up : Icons.trending_down, color: Colors.white),
                                ),
                                title: Text('${entry.symbol} - ${entry.amount} واحد'),
                                subtitle: Text(
                                  'تاریخ: ${entry.date.toLocal().toString().split(' ')[0]} | قیمت: ${entry.price} تومان | ${entry.isBuy ? 'خرید' : 'فروش'}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEntryPage(entry: entry, index: originalIndex),
                                        ),
                                      ).then((result) {
                                        if (result != null) {
                                          _editEntry(originalIndex, result as JournalEntry);
                                        }
                                      });
                                    } else if (value == 'delete') {
                                      _deleteEntry(originalIndex);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                                    const PopupMenuItem(value: 'delete', child: Text('حذف')),
                                  ],
                                ),
                                onTap: () => _showEntryDetails(entry),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add');
          if (result != null) {
            _addEntry(result as JournalEntry);
          }
        },
        label: const Text('افزودن معامله'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showEntryDetails(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${entry.symbol} - جزئیات'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تاریخ: ${entry.date.toLocal().toString().split(' ')[0]}'),
              Text('مقدار: ${entry.amount}'),
              Text('قیمت: ${entry.price}'),
              Text('یادداشت: ${entry.notes}'),
              Text('نوع: ${entry.isBuy ? 'خرید' : 'فروش'}'),
            ],
          ),
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
  final JournalEntry? entry;
  final int? index;

  const AddEntryPage({Key? key, this.entry, this.index}) : super(key: key);

  @override
  _AddEntryPageState createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late final _symbolController;
  late final _amountController;
  late final _priceController;
  late final _notesController;
  late bool _isBuy;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.entry?.date ?? DateTime.now();
    _symbolController = TextEditingController(text: widget.entry?.symbol ?? '');
    _amountController = TextEditingController(text: widget.entry?.amount.toString() ?? '');
    _priceController = TextEditingController(text: widget.entry?.price.toString() ?? '');
    _notesController = TextEditingController(text: widget.entry?.notes ?? '');
    _isBuy = widget.entry?.isBuy ?? true;
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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
        title: Text(widget.entry == null ? 'افزودن ورودی جدید' : 'ویرایش ورودی'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text('تاریخ: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(
                    labelText: 'نماد (مثلاً BTC)',
                    prefixIcon: Icon(Icons.currency_bitcoin),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'لطفاً نماد را وارد کنید' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'مقدار',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'لطفاً مقدار را وارد کنید';
                    if (double.tryParse(value) == null) return 'عدد معتبر وارد کنید';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'قیمت',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'لطفاً قیمت را وارد کنید';
                    if (double.tryParse(value) == null) return 'عدد معتبر وارد کنید';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<bool>(
                  value: _isBuy,
                  decoration: const InputDecoration(
                    labelText: 'نوع معامله',
                    prefixIcon: Icon(Icons.swap_horiz),
                  ),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('خرید')),
                    DropdownMenuItem(value: false, child: Text('فروش')),
                  ],
                  onChanged: (value) => setState(() => _isBuy = value ?? true),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'یادداشت',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final entry = JournalEntry(
                        date: _selectedDate,
                        symbol: _symbolController.text.trim(),
                        amount: double.parse(_amountController.text.trim()),
                        price: double.parse(_priceController.text.trim()),
                        notes: _notesController.text.trim(),
                        isBuy: _isBuy,
                      );
                      Navigator.pop(context, entry);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('ذخیره'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For simplicity, using mock data; in a real app, calculate from entries
    final totalTrades = 10;
    final totalProfit = 1500000.0;
    final chartData = [1.0, 2.0, 3.0, 4.0, 5.0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('آمار و نمودارها'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('کل معاملات: $totalTrades', style: Theme.of(context).textTheme.headlineSmall),
                    Text('سود/زیان کل: $totalProfit تومان', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}