import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/travel_converter_service.dart';

class TravelConverterScreen extends StatefulWidget {
  const TravelConverterScreen({super.key});

  @override
  State<TravelConverterScreen> createState() => _TravelConverterScreenState();
}

class _TravelConverterScreenState extends State<TravelConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Currency State
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  final TextEditingController _amountController =
      TextEditingController(text: '10');
  double _inputAmount = 10.0;

  // Timezone State
  TimeOfDay _selectedBandungTime = const TimeOfDay(hour: 10, minute: 0);
  TimezoneInfo _selectedTargetTz =
      TravelConverterService.supportedTimezones[3]; // SGT (Singapura/KL)
  Timer? _liveClockTimer;
  DateTime _currentUtcTime = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Live clock update every second
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentUtcTime = DateTime.now().toUtc();
        });
      }
    });
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  void _setPresetAmount(double amount) {
    setState(() {
      _fromCurrency = 'IDR';
      _toCurrency = 'USD';
      _inputAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  Future<void> _pickBandungTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedBandungTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedBandungTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konverter Wisatawan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Kalkulator Kurs & Zona Waktu Bandung',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.currency_exchange_rounded),
              text: 'Kurs Mata Uang',
            ),
            Tab(
              icon: Icon(Icons.schedule_rounded),
              text: 'Zona Waktu',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(),
          _buildTimezoneTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: CURRENCY CONVERTER
  // ---------------------------------------------------------------------------
  Widget _buildCurrencyTab() {
    final convertedAmount = TravelConverterService.convertCurrency(
      amount: _inputAmount,
      fromCode: _fromCurrency,
      toCode: _toCurrency,
    );

    final fromCur = TravelConverterService.getCurrency(_fromCurrency);
    final toCur = TravelConverterService.getCurrency(_toCurrency);

    // 1 unit exchange rate reference
    final singleUnitRate = TravelConverterService.convertCurrency(
      amount: 1.0,
      fromCode: _fromCurrency,
      toCode: _toCurrency,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Converted Result Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${fromCur.flag} ${_amountController.text.isEmpty ? "0" : _amountController.text} ${fromCur.code}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '1 ${fromCur.code} = ${TravelConverterService.formatCurrency(singleUnitRate, toCur.code)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  TravelConverterService.formatCurrency(
                    convertedAmount,
                    toCur.code,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Setara dalam ${toCur.name} (${toCur.flag} ${toCur.code})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Converter Input Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // From Currency Selector & Input
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildCurrencyDropdown(
                        selectedCode: _fromCurrency,
                        onChanged: (code) {
                          if (code != null) setState(() => _fromCurrency = code);
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Nominal',
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val) ?? 0.0;
                            setState(() => _inputAmount = parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Swap Button
                  Center(
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.swap_vert_rounded),
                      tooltip: 'Tukar Mata Uang',
                      onPressed: _swapCurrencies,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // To Currency Selector
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildCurrencyDropdown(
                        selectedCode: _toCurrency,
                        onChanged: (code) {
                          if (code != null) setState(() => _toCurrency = code);
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceColor(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.getBorderColor(context),
                            ),
                          ),
                          child: Text(
                            TravelConverterService.formatCurrency(
                              convertedAmount,
                              toCur.code,
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quick Presets: Bandung Tourist Ticket & Budget
          const Text(
            'Estimasi Cepat Tiket & Budget Wisata Bandung',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Rp 10.000', 10000, 'Tiket Museum'),
              _buildPresetChip('Rp 30.000', 30000, 'Tangkuban / Kawah'),
              _buildPresetChip('Rp 50.000', 50000, 'Wahana Keluarga'),
              _buildPresetChip('Rp 100.000', 100000, 'Kulineran Braga'),
              _buildPresetChip('Rp 250.000', 250000, 'Budget 1 Hari'),
              _buildPresetChip('Rp 500.000', 500000, 'Paket Liburan'),
            ],
          ),
          const SizedBox(height: 24),

          // Benchmark Table Card
          const Text(
            'Tabel Kurs Acuan Valas Wisatawan (ke IDR)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: TravelConverterService.supportedCurrencies
                  .where((c) => c.code != 'IDR')
                  .length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final list = TravelConverterService.supportedCurrencies
                    .where((c) => c.code != 'IDR')
                    .toList();
                final cur = list[index];
                final idrValue = TravelConverterService.convertCurrency(
                  amount: 1.0,
                  fromCode: cur.code,
                  toCode: 'IDR',
                );

                return ListTile(
                  dense: true,
                  leading: Text(
                    cur.flag,
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Text(
                    '1 ${cur.code} (${cur.name})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    TravelConverterService.formatCurrency(idrValue, 'IDR'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _fromCurrency = cur.code;
                      _toCurrency = 'IDR';
                      _inputAmount = 10.0;
                      _amountController.text = '10';
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyDropdown({
    required String selectedCode,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorderColor(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCode,
          items: TravelConverterService.supportedCurrencies.map((cur) {
            return DropdownMenuItem<String>(
              value: cur.code,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cur.flag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    cur.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, double amount, String subtitle) {
    return ActionChip(
      avatar: const Icon(Icons.sell_outlined, size: 14, color: AppColors.primary),
      label: Text('$label ($subtitle)'),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      onPressed: () => _setPresetAmount(amount),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: TIMEZONE CONVERTER
  // ---------------------------------------------------------------------------
  Widget _buildTimezoneTab() {
    // Current live Bandung time
    final bandungLive = _currentUtcTime.add(const Duration(hours: 7));
    final bandungLiveDateStr =
        TravelConverterService.formatIndonesianDate(bandungLive);
    final bandungLiveTimeStr = DateFormat('HH:mm:ss').format(bandungLive);

    // Converted selected Bandung time to target timezone
    final convertedTargetTimeStr =
        TravelConverterService.convertBandungTimeToTarget(
      bandungHour: _selectedBandungTime.hour,
      bandungMinute: _selectedBandungTime.minute,
      targetTz: _selectedTargetTz,
    );

    final operationalHoursStr =
        TravelConverterService.getOperationalHoursInTimezone(
      targetTz: _selectedTargetTz,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Bandung Master Clock Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🇮🇩', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Waktu Resmi Bandung (WIB / UTC+7)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bandungLiveTimeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bandungLiveDateStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Time Comparison Tool
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kalkulator Selisih Jam Kunjungan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih jam rencana jalan-jalan di Bandung untuk mengetahui jam setara di zona asal Anda:',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected Bandung Time Button
                  InkWell(
                    onTap: _pickBandungTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Jam Bandung (WIB):',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_selectedBandungTime.hour.toString().padLeft(2, '0')}:${_selectedBandungTime.minute.toString().padLeft(2, '0')} WIB',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Target Timezone Dropdown
                  const Text(
                    'Pilih Zona Asal Wisatawan:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<TimezoneInfo>(
                    initialValue: _selectedTargetTz,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: TravelConverterService.supportedTimezones
                        .map((tz) {
                      return DropdownMenuItem<TimezoneInfo>(
                        value: tz,
                        child: Text(
                          '${tz.flag} ${tz.cityName} (${tz.code})',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (tz) {
                      if (tz != null) {
                        setState(() => _selectedTargetTz = tz);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Comparison Summary Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getBorderColor(context),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedTargetTz.flag,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Di ${_selectedTargetTz.cityName}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              '$convertedTargetTimeStr ${_selectedTargetTz.code}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedTargetTz.diffDescription,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Operational Hours Guide Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.amber.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.store_mall_directory_rounded,
                    color: Colors.amber,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam Buka Wisata Bandung (08:00 - 17:00 WIB)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Setara dengan $operationalHoursStr di ${_selectedTargetTz.cityName}.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Global World Clock List
          const Text(
            'Daftar Jam Live Dunia & Kota Wisatawan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: TravelConverterService.supportedTimezones.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tz = TravelConverterService.supportedTimezones[index];
                final localTime = _currentUtcTime.add(
                  Duration(hours: tz.offsetFromUtcHours),
                );
                final timeStr = DateFormat('HH:mm:ss').format(localTime);
                final hour = localTime.hour;
                final isDay = hour >= 6 && hour < 18;

                return ListTile(
                  dense: true,
                  leading: Text(
                    tz.flag,
                    style: const TextStyle(fontSize: 22),
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          tz.cityName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tz.code == 'WIB') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BANDUNG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${tz.code} (UTC${tz.offsetFromUtcHours >= 0 ? "+${tz.offsetFromUtcHours}" : tz.offsetFromUtcHours}) • ${tz.diffDescription}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 16,
                        color: isDay ? Colors.orangeAccent : Colors.indigo,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: tz.code == 'WIB'
                              ? AppColors.primary
                              : AppColors.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
