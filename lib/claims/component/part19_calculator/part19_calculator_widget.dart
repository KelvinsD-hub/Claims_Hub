import '/backend/backend.dart';
import '/backend/services/compensation_calculator.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Works out the amount to claim under NCAR 2023 Part 19 and writes it to the
/// claim, where the demand letter picks it up.
///
/// Part 19 compensation is a share of the ticket price, so the calculation
/// starts from the fare — prefilled when the claim came from the website with
/// one, typed in by staff otherwise.
class Part19CalculatorWidget extends StatefulWidget {
  const Part19CalculatorWidget({super.key, required this.claim});

  final ClaimsRecord claim;

  @override
  State<Part19CalculatorWidget> createState() => _Part19CalculatorWidgetState();
}

class _Part19CalculatorWidgetState extends State<Part19CalculatorWidget> {
  static const Color _accent = Color(0xFF7C3AED);

  /// ISO code -> the symbol written into the claim amount.
  static const Map<String, String> _currencies = {
    'NGN': '₦',
    'USD': 'US\$',
    'GBP': '£',
    'EUR': '€',
  };

  late final TextEditingController _fareController;
  late FlightType _flightType;
  late String _currency;
  bool _downgrade = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final claim = widget.claim;
    _fareController = TextEditingController(
      text: claim.farePaid != null
          ? NumberFormat('#,##0.##').format(claim.farePaid)
          : '',
    );
    _currency =
        _currencies.containsKey(claim.fareCurrency) ? claim.fareCurrency : 'NGN';
    // Domestic unless the website recorded a leg outside Nigeria.
    final countries = [claim.routeFromCountry, claim.routeToCountry]
        .where((c) => c.isNotEmpty);
    _flightType = countries.any((c) => c != 'NG')
        ? FlightType.international
        : FlightType.domestic;
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  double? get _fare {
    final value =
        double.tryParse(_fareController.text.replaceAll(',', '').trim());
    return value != null && value > 0 ? value : null;
  }

  int get _pct =>
      CompensationCalculator.ratePercent(_flightType, downgrade: _downgrade);

  String _money(double value) {
    final rounded = (value * 100).round() / 100;
    return '${_currencies[_currency]}${NumberFormat('#,##0.##').format(rounded)}';
  }

  /// The amount as it is written to the claim and quoted in the demand letter.
  String? get _claimAmount {
    final fare = _fare;
    if (fare == null) return null;
    final sum = _money(fare * _pct / 100);
    return _downgrade ? '$sum plus the fare difference' : sum;
  }

  Future<void> _save() async {
    final amount = _claimAmount;
    if (amount == null) return;
    setState(() => _saving = true);
    try {
      await widget.claim.reference.update({
        'claims_amount': amount,
        'fare_paid': _fare,
        'fare_currency': _currency,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claim amount set to $amount'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save the claim amount. Please try again.'),
          backgroundColor: FlutterFlowTheme.of(context).error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final claim = widget.claim;
    final amount = _claimAmount;
    final scope = _flightType == FlightType.domestic
        ? 'a flight within Nigeria'
        : 'an international flight';

    TextStyle label() => theme.labelMedium.override(
          font: GoogleFonts.inter(fontWeight: FontWeight.w600),
          color: theme.secondaryText,
          letterSpacing: 0.0,
          fontWeight: FontWeight.w600,
        );

    Widget chip(String text, bool selected, VoidCallback onSelected) =>
        ChoiceChip(
          label: Text(text),
          selected: selected,
          onSelected: (_) => setState(onSelected),
          selectedColor: _accent,
          labelStyle: TextStyle(
            color: selected ? Colors.white : theme.primaryText,
            fontWeight: FontWeight.w500,
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
              child: Icon(Icons.calculate_outlined, color: _accent, size: 24.0),
            ),
            Text(
              'Compensation Calculator',
              style: theme.titleMedium.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                color: _accent,
                letterSpacing: 0.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (claim.claimsAmount.isNotEmpty)
          Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recorded Claim Amount', style: label()),
              Text(
                claim.claimsAmount,
                style: theme.bodyLarge.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ].divide(SizedBox(height: 4.0)),
          ),
        Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket Price', style: label()),
            TextField(
              controller: _fareController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                letterSpacing: 0.0,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'What the passenger paid, e.g. 85,000',
                prefixText: '${_currencies[_currency]} ',
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: theme.alternate),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: theme.alternate),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
            Wrap(
              spacing: 8.0,
              children: [
                for (final code in _currencies.keys)
                  chip(_currencies[code]!, _currency == code,
                      () => _currency = code),
              ],
            ),
          ].divide(SizedBox(height: 6.0)),
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flight Type', style: label()),
            Wrap(
              spacing: 8.0,
              children: [
                chip('Domestic', _flightType == FlightType.domestic,
                    () => _flightType = FlightType.domestic),
                chip('International', _flightType == FlightType.international,
                    () => _flightType = FlightType.international),
              ],
            ),
          ].divide(SizedBox(height: 6.0)),
        ),
        Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Claim Is For', style: label()),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                chip('Delay, cancellation or denied boarding', !_downgrade,
                    () => _downgrade = false),
                chip('Downgrade', _downgrade, () => _downgrade = true),
              ],
            ),
          ].divide(SizedBox(height: 6.0)),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: _accent.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.balance, color: _accent, size: 22.0),
              SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Part 19 Minimum',
                      style: theme.labelMedium.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        color: _accent,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      amount ?? '$_pct% of the ticket price',
                      style: theme.titleLarge.override(
                        font:
                            GoogleFonts.interTight(fontWeight: FontWeight.bold),
                        color: _accent,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _downgrade
                          ? 'Part 19.11: the fare difference plus $_pct% of '
                              'the ticket price on $scope.'
                          : 'Part 19.8.1.1: at least $_pct% of the ticket '
                              'price on $scope.',
                      style: theme.bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                        letterSpacing: 0.0,
                      ),
                    ),
                    if (!_downgrade && _flightType == FlightType.domestic)
                      Text(
                        'A domestic delay carries compensation only where '
                        'departure was more than six hours late.',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                    if (claim.passengerCount > 1)
                      Text(
                        '${claim.passengerCount} passengers on this booking — '
                        'enter the total paid for all of them.',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: theme.secondaryText,
                          letterSpacing: 0.0,
                        ),
                      ),
                  ].divide(SizedBox(height: 4.0)),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: amount == null || _saving ? null : _save,
            icon: Icon(Icons.gavel_rounded, size: 18.0),
            label: Text(amount == null
                ? 'Enter the ticket price'
                : 'Set Claim Amount'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              textStyle: GoogleFonts.interTight(
                  fontWeight: FontWeight.bold, fontSize: 15.0),
            ),
          ),
        ),
      ].divide(SizedBox(height: 16.0)),
    );
  }
}
