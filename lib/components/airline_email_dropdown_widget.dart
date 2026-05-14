import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'airline_email_dropdown_model.dart';
export 'airline_email_dropdown_model.dart';

class AirlineEmailDropdownWidget extends StatefulWidget {
  const AirlineEmailDropdownWidget({super.key});

  @override
  State<AirlineEmailDropdownWidget> createState() =>
      _AirlineEmailDropdownWidgetState();
}

class _AirlineEmailDropdownWidgetState
    extends State<AirlineEmailDropdownWidget> {
  late AirlineEmailDropdownModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AirlineEmailDropdownModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AirlinesDirectoryRecord>>(
      stream: queryAirlinesDirectoryRecord(),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50.0,
              height: 50.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }
        List<AirlinesDirectoryRecord> dropDownAirlinesDirectoryRecordList =
            snapshot.data!;

        return FlutterFlowDropDown<String>(
          controller: _model.dropDownValueController ??=
              FormFieldController<String>(null),
          options: dropDownAirlinesDirectoryRecordList
              .map((e) => e.legalEmail)
              .toList(),
          onChanged: (val) async {
            safeSetState(() => _model.dropDownValue = val);
            FFAppState().selectedAirlineEmail =
                dropDownAirlinesDirectoryRecordList
                    .elementAtOrNull(0)!
                    .legalEmail;
            safeSetState(() {});
          },
          height: 38.0,
          textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                fontSize: 12.0,
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF1A2E4A),
            size: 16.0,
          ),
          fillColor: FlutterFlowTheme.of(context).primaryBackground,
          elevation: 2.0,
          borderColor: Color(0xFFE0E0E0),
          borderWidth: 1.0,
          borderRadius: 8.0,
          margin: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
          hidesUnderline: true,
          isSearchable: false,
          isMultiSelect: false,
        );
      },
    );
  }
}
