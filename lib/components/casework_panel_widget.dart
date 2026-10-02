import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export '/components/brand_colors.dart';

void showCaseActionResult(
    BuildContext context, CaseActionResult result, String done) {
  final theme = FlutterFlowTheme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result.succeeded ? done : result.error!,
          style: TextStyle(color: theme.info)),
      duration: Duration(milliseconds: result.succeeded ? 3000 : 7000),
      backgroundColor: result.succeeded ? const Color(0xFF3BA55D) : theme.error,
    ),
  );
}

/// Who owns a lead or claim and what happens to it next, with the buttons to
/// change either.
///
/// [data] is the record's document data. Shows the lawyer as well for a claim
/// that is, or has been, with the legal team.
class CaseworkPanelWidget extends StatefulWidget {
  const CaseworkPanelWidget({
    super.key,
    required this.kind,
    required this.recordId,
    required this.data,
    required this.stage,
  });

  final RecordKind kind;
  final String recordId;
  final Map<String, dynamic> data;
  final String stage;

  @override
  State<CaseworkPanelWidget> createState() => _CaseworkPanelWidgetState();
}

class _CaseworkPanelWidgetState extends State<CaseworkPanelWidget> {
  bool _busy = false;

  Future<void> _run(Future<CaseActionResult> Function() action, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    showCaseActionResult(context, result, done);
  }

  Future<void> _assign({required bool lawyer}) async {
    final picked = await showDialog<UsersRecord>(
      context: context,
      builder: (_) => _StaffPickerDialog(lawyersOnly: lawyer),
    );
    if (picked == null || !mounted) return;
    await _run(
      () => assignRecord(
          kind: widget.kind,
          id: widget.recordId,
          toUid: picked.reference.id,
          lawyer: lawyer),
      'Assigned to ${picked.displayName.isNotEmpty ? picked.displayName : picked.email}.',
    );
  }

  Future<void> _editNextAction(Casework work) async {
    final edited = await showDialog<_NextActionEdit>(
      context: context,
      builder: (_) => _NextActionDialog(
          text: work.nextAction, due: work.nextActionDue),
    );
    if (edited == null || !mounted) return;
    await _run(
      () => setNextAction(
          kind: widget.kind,
          id: widget.recordId,
          text: edited.text,
          due: edited.due),
      edited.text.isEmpty ? 'Next action cleared.' : 'Next action saved.',
    );
  }

  Widget _ownerRow(
    BuildContext context, {
    required String label,
    required String ownerUid,
    required String ownerName,
    required bool lawyer,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final role = valueOrDefault(currentUserDocument?.role, '');
    final mine = ownerUid == currentUserUid;
    final free = ownerUid.isEmpty;
    final canTake = free && (!lawyer || isLegalRole(role));
    final manager = isManagerRole(role);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(lawyer ? Icons.gavel_rounded : Icons.person_outline,
              size: 16.0, color: theme.secondaryText),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              free
                  ? '$label: unassigned'
                  : '$label: ${mine ? 'you' : ownerName}',
              style: theme.bodySmall.override(
                font: GoogleFonts.inter(),
                color: free ? overdueRed(context) : theme.primaryText,
                letterSpacing: 0.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canTake)
            _LinkButton(
              label: 'Take',
              onTap: _busy
                  ? null
                  : () => _run(
                        () => assignRecord(
                            kind: widget.kind,
                            id: widget.recordId,
                            toUid: currentUserUid,
                            lawyer: lawyer),
                        'It is yours.',
                      ),
            ),
          if (mine)
            _LinkButton(
              label: 'Hand back',
              onTap: _busy
                  ? null
                  : () => _run(
                        () => assignRecord(
                            kind: widget.kind,
                            id: widget.recordId,
                            toUid: '',
                            lawyer: lawyer),
                        'Returned to the queue.',
                      ),
            ),
          if (manager)
            _LinkButton(
              label: free ? 'Assign' : 'Reassign',
              onTap: _busy ? null : () => _assign(lawyer: lawyer),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final work = Casework.of(widget.data);
    final showLawyer = widget.kind == RecordKind.claim &&
        (canonicalStage(RecordKind.claim, widget.stage) ==
                ClaimStage.withSolicitor ||
            work.hasLawyer);

    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 8.0, 8.0),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ownerRow(context,
              label: 'Handler',
              ownerUid: work.handlerUid,
              ownerName: work.handlerName,
              lawyer: false),
          if (showLawyer)
            _ownerRow(context,
                label: 'Lawyer',
                ownerUid: work.lawyerUid,
                ownerName: work.lawyerName,
                lawyer: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1.0),
                  child: Icon(Icons.event_outlined,
                      size: 16.0,
                      color: work.isOverdue
                          ? overdueRed(context)
                          : theme.secondaryText),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    work.hasNextAction
                        ? '${work.nextAction}\n${work.dueLabel}'
                        : 'No next action',
                    style: theme.bodySmall.override(
                      font: GoogleFonts.inter(),
                      color: work.isOverdue
                          ? overdueRed(context)
                          : theme.primaryText,
                      letterSpacing: 0.0,
                    ),
                  ),
                ),
                _LinkButton(
                  label: work.hasNextAction ? 'Change' : 'Set',
                  onTap: _busy ? null : () => _editNextAction(work),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6.0),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: onTap == null
                ? FlutterFlowTheme.of(context).secondaryText
                : brandBlue(context),
          ),
        ),
      ),
    );
  }
}

/// Pick an approved member of staff. [lawyersOnly] limits the list to people
/// who can be the lawyer on a claim.
class _StaffPickerDialog extends StatelessWidget {
  const _StaffPickerDialog({required this.lawyersOnly});

  final bool lawyersOnly;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return AlertDialog(
      title: Text(lawyersOnly ? 'Assign a lawyer' : 'Assign to'),
      content: SizedBox(
        width: 360.0,
        height: 360.0,
        child: FutureBuilder<List<UsersRecord>>(
          future: queryUsersRecordOnce(
            queryBuilder: (q) => q.where('approved', isEqualTo: true),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final staff = snapshot.data!
                .where((u) => !lawyersOnly || isLegalRole(u.role))
                .toList()
              ..sort((a, b) => a.displayName
                  .toLowerCase()
                  .compareTo(b.displayName.toLowerCase()));
            if (staff.isEmpty) {
              return Center(
                child: Text(
                  lawyersOnly
                      ? 'No approved Solicitor accounts yet. Give a member of '
                          'staff the Solicitor role on the Staffs page.'
                      : 'No approved staff found.',
                  textAlign: TextAlign.center,
                  style: theme.bodyMedium,
                ),
              );
            }
            return ListView.builder(
              itemCount: staff.length,
              itemBuilder: (context, i) {
                final person = staff[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person_outline),
                  title: Text(person.displayName.isNotEmpty
                      ? person.displayName
                      : person.email),
                  subtitle: Text(person.role.isEmpty ? 'No role' : person.role),
                  onTap: () => Navigator.pop(context, person),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _NextActionEdit {
  const _NextActionEdit(this.text, this.due);
  final String text;
  final DateTime? due;
}

class _NextActionDialog extends StatefulWidget {
  const _NextActionDialog({required this.text, required this.due});

  final String text;
  final DateTime? due;

  @override
  State<_NextActionDialog> createState() => _NextActionDialogState();
}

class _NextActionDialogState extends State<_NextActionDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.text);
  late DateTime? _due = widget.due;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due != null && _due!.isAfter(now) ? _due! : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _due = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Next action'),
      content: SizedBox(
        width: 360.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'What has to happen next',
                hintText: 'Call the client about the boarding pass',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8.0),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined, size: 18.0),
              label: Text(_due == null
                  ? 'Choose the due date'
                  : 'Due ${dateTimeFormat('d MMM y', _due)}'),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.text.isNotEmpty)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _NextActionEdit('', null)),
            child: const Text('Clear'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) {
              setState(() => _error = 'Say what has to happen.');
              return;
            }
            if (_due == null) {
              setState(() => _error = 'Choose the date it is due.');
              return;
            }
            Navigator.pop(context, _NextActionEdit(text, _due));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
