import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/menus_file/suppots_menu/suppots_menu_widget.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'supports_model.dart';
export 'supports_model.dart';

class SupportsWidget extends StatefulWidget {
  const SupportsWidget({super.key});

  static String routeName = 'Supports';
  static String routePath = '/supports';

  @override
  State<SupportsWidget> createState() => _SupportsWidgetState();
}

class _SupportsWidgetState extends State<SupportsWidget> {
  late SupportsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
        title: 'Supports',
        color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            body: SafeArea(
              top: true,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  wrapWithModel(
                    model: _model.suppotsMenuModel,
                    updateCallback: () => safeSetState(() {}),
                    child: SuppotsMenuWidget(),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
