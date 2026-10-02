import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/services/casework.dart';
import '/backend/services/pipeline.dart';
import '/components/brand_colors.dart';
import '/components/lead_file_widget.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/leads/leads_options/leads_options_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every lead, in one list. The chips along the top are the stages a lead
/// moves through; "Mine" narrows any of them to the leads the signed-in person
/// is handling. A row opens the lead's file.
class LeadsWidget extends StatefulWidget {
  const LeadsWidget({super.key});

  static String routeName = 'Leads';
  static String routePath = '/leads';

  @override
  State<LeadsWidget> createState() => _LeadsWidgetState();
}

class _LeadsWidgetState extends State<LeadsWidget> {
  /// The stage shown; null for every lead.
  String? _stage = LeadStage.newLead;
  bool _mineOnly = false;
  String _search = '';
  final _searchController = TextEditingController();

  late final Stream<List<LeadsRecord>> _leads = queryLeadsRecord(
    queryBuilder: (q) => q.orderBy('created_at', descending: true),
  );

  static const _stages = [
    LeadStage.newLead,
    LeadStage.contacted,
    LeadStage.qualified,
    LeadStage.rejected,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static String _stageOf(LeadsRecord lead) =>
      canonicalStage(RecordKind.lead, lead.status);

  bool _matches(LeadsRecord lead) {
    if (_mineOnly &&
        Casework.of(lead.snapshotData).handlerUid != currentUserUid) {
      return false;
    }
    if (_search.isEmpty) return true;
    return '${lead.fullName} ${lead.email} ${lead.phone} ${lead.airlineName}'
        .toLowerCase()
        .contains(_search);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return WorkScaffold(
      page: WorkPage.leads,
      title: 'Leads',
      subtitle: 'People who have asked about a claim, from first contact to '
          'qualified or rejected',
      icon: Icons.person_search_outlined,
      actions: [
        WorkSearchBox(
          controller: _searchController,
          hint: 'Search name, email, phone, airline…',
          onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
        ),
        WorkButton(
          icon: Icons.link,
          label: 'Copy form link',
          onTap: () async {
            await Clipboard.setData(
                const ClipboardData(text: 'https://claimshub.online/leadForm'));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('The lead form link is copied.'),
              duration: Duration(seconds: 3),
            ));
          },
        ),
        WorkButton(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Add a lead',
          filled: true,
          onTap: () => context.pushNamed(LeadFormWidget.routeName),
        ),
      ],
      child: StreamBuilder<List<LeadsRecord>>(
        stream: _leads,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const WorkEmpty('The leads could not be loaded.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final matching = snapshot.data!.where(_matches).toList();
          final shown = _stage == null
              ? matching
              : matching.where((l) => _stageOf(l) == _stage).toList();
          if (_mineOnly) {
            // Most urgent first; anything with no date last.
            shown.sort((a, b) =>
                (Casework.of(a.snapshotData).nextActionDue ?? DateTime(2100))
                    .compareTo(Casework.of(b.snapshotData).nextActionDue ??
                        DateTime(2100)));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final stage in _stages)
                      WorkChip(
                        label: stage == LeadStage.newLead ? 'New' : stage,
                        count:
                            matching.where((l) => _stageOf(l) == stage).length,
                        selected: _stage == stage,
                        onTap: () => setState(() => _stage = stage),
                      ),
                    WorkChip(
                      label: 'All',
                      count: matching.length,
                      selected: _stage == null,
                      onTap: () => setState(() => _stage = null),
                    ),
                    Container(width: 1.0, height: 22.0, color: theme.alternate),
                    WorkChip(
                      label: 'Mine',
                      selected: _mineOnly,
                      onTap: () => setState(() => _mineOnly = !_mineOnly),
                    ),
                  ],
                ),
              ),
              Container(
                color: theme.secondaryBackground,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 11.0),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: WorkColumnHead('Client')),
                    Expanded(flex: 3, child: WorkColumnHead('Problem')),
                    Expanded(flex: 2, child: WorkColumnHead('Website says')),
                    Expanded(flex: 3, child: WorkColumnHead('Owner and due')),
                    Expanded(flex: 2, child: WorkColumnHead('Stage')),
                    Expanded(flex: 2, child: WorkColumnHead('Received')),
                    SizedBox(width: 40.0),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? WorkEmpty(_search.isNotEmpty || _mineOnly
                        ? 'No leads match.'
                        : 'No leads here.')
                    : ListView.separated(
                        itemCount: shown.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1.0, color: theme.alternate),
                        itemBuilder: (context, i) => _LeadRow(lead: shown[i]),
                      ),
              ),
              Container(
                color: theme.secondaryBackground,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 10.0),
                child: Text(
                  '${shown.length} lead${shown.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                      fontSize: 12.0, color: theme.secondaryText),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead});

  final LeadsRecord lead;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final work = Casework.of(lead.snapshotData);
    final what =
        lead.complaintType.isNotEmpty ? lead.complaintType : lead.claimType;
    final contact =
        [lead.email, lead.phone].where((s) => s.isNotEmpty).join('  ·  ');
    final (String routing, Color routingColor) = switch (lead.handler) {
      'claims_assist' => ('In house', theme.primaryText),
      'register_interest' => ('Interest only', overdueRed(context)),
      'decline' => ('Declined', overdueRed(context)),
      'reclaims4u' => ('Partner (closed)', overdueRed(context)),
      _ => ('—', theme.secondaryText),
    };
    final small = GoogleFonts.inter(fontSize: 12.0, color: theme.secondaryText);
    final main = GoogleFonts.inter(fontSize: 13.0, color: theme.primaryText);

    return InkWell(
      onTap: () => showLeadFile(context, lead.reference),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.fullName.isNotEmpty ? lead.fullName : 'Unnamed lead',
                    overflow: TextOverflow.ellipsis,
                    style: main.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (contact.isNotEmpty)
                    Text(contact,
                        overflow: TextOverflow.ellipsis, style: small),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(what.isEmpty ? '—' : what,
                      overflow: TextOverflow.ellipsis, style: main),
                  if (lead.airlineName.isNotEmpty)
                    Text(lead.airlineName,
                        overflow: TextOverflow.ellipsis, style: small),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(routing,
                  overflow: TextOverflow.ellipsis,
                  style: main.copyWith(fontSize: 12.5, color: routingColor)),
            ),
            Expanded(flex: 3, child: OwnerAndDue(work)),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StagePill(canonicalStage(RecordKind.lead, lead.status)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                lead.createdAt == null
                    ? '—'
                    : dateTimeFormat('d MMM y', lead.createdAt),
                style: small,
              ),
            ),
            SizedBox(
              width: 40.0,
              child: IconButton(
                tooltip: 'Change stage',
                icon: Icon(Icons.more_vert,
                    size: 19.0, color: theme.secondaryText),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0.0,
                    child: LeadsOptionsWidget(leadRef: lead),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
