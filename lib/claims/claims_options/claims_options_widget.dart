import '/backend/backend.dart';
import '/backend/services/pipeline.dart';
import '/components/stage_menu_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'claims_options_model.dart';
export 'claims_options_model.dart';

/// The "Update Claim Status" menu on the claim lists.
///
/// Shows the moves allowed from the claim's current stage. The change itself
/// is made by the server (see StageMenuWidget and pipeline.dart).
class ClaimsOptionsWidget extends StatefulWidget {
  const ClaimsOptionsWidget({
    super.key,
    required this.claimRef,
  });

  final ClaimsRecord? claimRef;

  @override
  State<ClaimsOptionsWidget> createState() => _ClaimsOptionsWidgetState();
}

class _ClaimsOptionsWidgetState extends State<ClaimsOptionsWidget> {
  late ClaimsOptionsModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ClaimsOptionsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read live: the list this menu opens from may be showing a stage that
    // has since changed.
    return StreamBuilder<ClaimsRecord>(
      stream: ClaimsRecord.getDocument(widget.claimRef!.reference),
      builder: (context, snapshot) {
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
        final claim = snapshot.data!;
        return StageMenuWidget(
          kind: RecordKind.claim,
          recordId: claim.reference.id,
          currentStage: claim.claimStatus,
          subject:
              claim.fullName.isNotEmpty ? claim.fullName : 'This claim',
          data: claim.snapshotData,
        );
      },
    );
  }
}
