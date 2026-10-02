import '/backend/backend.dart';
import '/backend/services/pipeline.dart';
import '/components/stage_menu_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'leads_options_model.dart';
export 'leads_options_model.dart';

/// The "Update Lead Status" menu on the lead lists.
///
/// Shows the moves allowed from the lead's current stage. Qualifying a lead
/// opens its claim; both happen on the server in one step (see
/// StageMenuWidget and pipeline.dart).
class LeadsOptionsWidget extends StatefulWidget {
  const LeadsOptionsWidget({
    super.key,
    required this.leadRef,
  });

  final LeadsRecord? leadRef;

  @override
  State<LeadsOptionsWidget> createState() => _LeadsOptionsWidgetState();
}

class _LeadsOptionsWidgetState extends State<LeadsOptionsWidget> {
  late LeadsOptionsModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LeadsOptionsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  /// The website marks leads it did not route to us: a flight that does not
  /// touch Nigeria, or one with no scheme we pursue. Qualifying one opens a
  /// claim and emails the client an evidence form, so make that a deliberate
  /// choice rather than a slip.
  Future<bool> _confirmQualify(
      BuildContext context, LeadsRecord lead, String to) async {
    if (to != LeadStage.qualified || lead.isInHouse) return true;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Not a claim we are taking on'),
        content: Text(
          'The website recorded this lead as outside what we act on'
          '${lead.handlerReason.isEmpty ? '' : ':\n\n${lead.handlerReason}'}'
          '\n\nQualifying it opens a claim and emails the client asking for '
          'evidence. Continue only if you have checked the flight and it is '
          'covered by Nigerian rules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Qualify anyway'),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  @override
  Widget build(BuildContext context) {
    // Read live: the list this menu opens from may be showing a stage that
    // has since changed.
    return StreamBuilder<LeadsRecord>(
      stream: LeadsRecord.getDocument(widget.leadRef!.reference),
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
        final lead = snapshot.data!;
        return StageMenuWidget(
          kind: RecordKind.lead,
          recordId: lead.reference.id,
          currentStage: lead.status,
          subject: lead.fullName.isNotEmpty ? lead.fullName : 'This lead',
          data: lead.snapshotData,
          confirmBefore: (context, to) => _confirmQualify(context, lead, to),
        );
      },
    );
  }
}
