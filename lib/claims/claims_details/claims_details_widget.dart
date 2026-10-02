import '/backend/backend.dart';
import '/components/case_file_widget.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';

/// One claim's file as a page of its own, for a link or a bookmark. The lists
/// open the same file over the page they are on (see `showCaseFile`).
class ClaimsDetailsWidget extends StatelessWidget {
  const ClaimsDetailsWidget({super.key, required this.claimsRef});

  final DocumentReference? claimsRef;

  static String routeName = 'ClaimsDetails';
  static String routePath = '/claimsDetails';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    void close() => context.canPop()
        ? context.pop()
        : context.goNamed(ClaimsDashboardWidget.routeName);
    return Title(
      title: 'Claim',
      color: theme.primary.withAlpha(0xFF),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: claimsRef == null
              ? const WorkEmpty('That claim could not be found.')
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CaseFileWidget(claimRef: claimsRef!, onClose: close),
                ),
        ),
      ),
    );
  }
}
