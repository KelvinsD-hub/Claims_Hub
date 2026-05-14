import '/backend/services/compensation_calculator.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'eligibility_checker_model.dart';
export 'eligibility_checker_model.dart';

class EligibilityCheckerWidget extends StatefulWidget {
  const EligibilityCheckerWidget({super.key});

  static String routeName = 'EligibilityChecker';
  static String routePath = '/checkEligibility';

  @override
  State<EligibilityCheckerWidget> createState() =>
      _EligibilityCheckerWidgetState();
}

class _EligibilityCheckerWidgetState extends State<EligibilityCheckerWidget> {
  late EligibilityCheckerModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Form state ────────────────────────────────────────────────────────────
  int _step = 0; // 0 = form, 1 = results
  DateTime? _flightDate;
  String _delayLabel = CompensationCalculator.delayLabels.first;
  FlightType _flightType = FlightType.domestic;
  bool _isExtraordinary = false;
  EligibilityResult? _result;

  static const Color _navy = Color(0xFF002855);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EligibilityCheckerModel());
    _model.airlineController ??= TextEditingController();
    _model.airlineFocusNode ??= FocusNode();
    _model.departureController ??= TextEditingController();
    _model.departureFocusNode ??= FocusNode();
    _model.destinationController ??= TextEditingController();
    _model.destinationFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _checkEligibility() {
    if (!_model.formKey.currentState!.validate()) return;
    if (_flightDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the flight date.')),
      );
      return;
    }

    final delay = CompensationCalculator.delayCategoryFromLabel(_delayLabel);
    final result = CompensationCalculator.calculate(
      delay: delay,
      flightType: _flightType,
      isExtraordinaryCircumstance: _isExtraordinary,
    );

    setState(() {
      _result = result;
      _step = 1;
    });
  }

  void _reset() {
    setState(() {
      _step = 0;
      _result = null;
      _flightDate = null;
      _isExtraordinary = false;
      _delayLabel = CompensationCalculator.delayLabels.first;
      _flightType = FlightType.domestic;
      _model.airlineController?.clear();
      _model.departureController?.clear();
      _model.destinationController?.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _navy,
            onPrimary: Colors.white,
            surface: FlutterFlowTheme.of(context).primaryBackground,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _flightDate = picked);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Title(
      title: 'Check Your Eligibility | Claims Assist',
      color: _navy.withAlpha(0xFF),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _step == 0
                          ? _buildForm(context)
                          : _buildResults(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Claims ',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(
                  text: 'Assist',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE6B011),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 0: Form ──────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Form(
      key: _model.formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          Text(
            'Check Your Eligibility',
            style: GoogleFonts.inter(
              color: theme.primaryText,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Find out if you\'re owed compensation in under 60 seconds. '
            'No win, no fee.',
            style: GoogleFonts.inter(
              color: theme.secondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Airline
          _label('Airline Name'),
          _textField(
            controller: _model.airlineController!,
            focusNode: _model.airlineFocusNode!,
            hint: 'e.g. Air Peace, Dana Air',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Flight Date
          _label('Flight Date'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.alternate),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: theme.secondaryText),
                  const SizedBox(width: 10),
                  Text(
                    _flightDate != null
                        ? dateTimeFormat('d MMM yyyy', _flightDate)
                        : 'Select date',
                    style: GoogleFonts.inter(
                      color: _flightDate != null
                          ? theme.primaryText
                          : theme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Departure / Destination row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Departure'),
                    _textField(
                      controller: _model.departureController!,
                      focusNode: _model.departureFocusNode!,
                      hint: 'e.g. Lagos (LOS)',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Destination'),
                    _textField(
                      controller: _model.destinationController!,
                      focusNode: _model.destinationFocusNode!,
                      hint: 'e.g. Abuja (ABV)',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Delay / Outcome
          _label('Delay Duration or Outcome'),
          _dropdown(
            value: _delayLabel,
            items: CompensationCalculator.delayLabels,
            onChanged: (v) => setState(() => _delayLabel = v ?? _delayLabel),
          ),
          const SizedBox(height: 16),

          // Flight type toggle
          _label('Flight Type'),
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.alternate),
            ),
            child: Row(
              children: [
                _typeTab('Domestic (Nigeria)', FlightType.domestic, theme),
                _typeTab('International', FlightType.international, theme),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Extraordinary circumstances
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.alternate),
            ),
            child: SwitchListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              title: Text(
                'Was the delay caused by weather, ATC, or security?',
                style: GoogleFonts.inter(
                    color: theme.primaryText, fontSize: 13),
              ),
              subtitle: Text(
                'Extraordinary circumstances exempt the airline',
                style: GoogleFonts.inter(
                    color: theme.secondaryText, fontSize: 12),
              ),
              value: _isExtraordinary,
              activeColor: _navy,
              onChanged: (v) => setState(() => _isExtraordinary = v),
            ),
          ),
          const SizedBox(height: 28),

          // CTA
          FFButtonWidget(
            onPressed: _checkEligibility,
            text: 'Check My Eligibility',
            options: FFButtonOptions(
              width: double.infinity,
              height: 52,
              color: _navy,
              textStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),

          Center(
            child: Text(
              'No win, no fee · NCAR 2023 · Nigerian flights',
              style: GoogleFonts.inter(
                  color: theme.secondaryText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Results ───────────────────────────────────────────────────────

  Widget _buildResults(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final result = _result!;

    return Column(
      key: const ValueKey('results'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Result banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: result.eligible ? theme.success : theme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result.eligible
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.eligible
                        ? 'You May Be Eligible!'
                        : 'Not Eligible',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (result.eligible) ...[
                const SizedBox(height: 14),
                Text(
                  'Estimated Compensation',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.formattedAmount,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                result.reason,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Flight summary card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Flight Details',
                style: GoogleFonts.inter(
                  color: theme.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _summaryRow(theme, 'Airline',
                  _model.airlineController?.text ?? ''),
              _summaryRow(theme, 'Date',
                  _flightDate != null
                      ? dateTimeFormat('d MMM yyyy', _flightDate)
                      : 'N/A'),
              _summaryRow(theme, 'Route',
                  '${_model.departureController?.text ?? ''} → '
                  '${_model.destinationController?.text ?? ''}'),
              _summaryRow(theme, 'Delay', result.delayLabel),
              _summaryRow(theme, 'Flight Type',
                  result.flightType == FlightType.domestic
                      ? 'Domestic'
                      : 'International'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: theme.secondaryText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This is an estimate based on NCAR 2023 Part 19. '
                  'Actual compensation depends on case specifics. '
                  'Claims Assist operates on a no-win, no-fee basis.',
                  style: GoogleFonts.inter(
                    color: theme.secondaryText,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Primary CTA
        if (result.eligible)
          FFButtonWidget(
            onPressed: () => context.pushNamed(LeadFormWidget.routeName),
            text: 'Start My Claim — No Win, No Fee',
            options: FFButtonOptions(
              width: double.infinity,
              height: 52,
              color: _navy,
              textStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

        if (!result.eligible) ...[
          Text(
            'Still unsure? Contact us — some cases are more complex '
            'than a simple eligibility check.',
            style: GoogleFonts.inter(
              color: theme.secondaryText,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          FFButtonWidget(
            onPressed: () => context.pushNamed(LeadFormWidget.routeName),
            text: 'Talk to Our Team',
            options: FFButtonOptions(
              width: double.infinity,
              height: 48,
              color: Colors.transparent,
              textStyle: GoogleFonts.inter(
                color: _navy,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _navy, width: 1.5),
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Reset
        Center(
          child: TextButton(
            onPressed: _reset,
            child: Text(
              'Check Another Flight',
              style: GoogleFonts.inter(
                color: theme.secondaryText,
                fontSize: 13,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: FlutterFlowTheme.of(context).primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    String? Function(String?)? validator,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      style: GoogleFonts.inter(color: theme.primaryText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(color: theme.secondaryText, fontSize: 14),
        filled: true,
        fillColor: theme.secondaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.alternate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.alternate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _navy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.error),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((i) => DropdownMenuItem(
                value: i,
                child: Text(i,
                    style: GoogleFonts.inter(
                        color: theme.primaryText, fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.secondaryBackground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.alternate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.alternate),
        ),
      ),
      dropdownColor: theme.primaryBackground,
    );
  }

  Widget _typeTab(String label, FlightType type, FlutterFlowTheme theme) {
    final selected = _flightType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _flightType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _navy : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : theme.secondaryText,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(FlutterFlowTheme theme, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: GoogleFonts.inter(
                      color: theme.secondaryText, fontSize: 13)),
            ),
            Expanded(
              child: Text(
                value.isEmpty ? 'N/A' : value,
                style: GoogleFonts.inter(
                  color: theme.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
}
