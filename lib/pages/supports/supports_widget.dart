import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'supports_model.dart';
export 'supports_model.dart';

const Color _kNavy = Color(0xFF002855);

// ---------------------------------------------------------------------------
// Support contact details. Update these to the real support channels.
// ---------------------------------------------------------------------------
const String _supportEmail = 'info@claimshub.online';
const String _supportPhone = '+233000000000'; // TODO: real support line
const String _supportWhatsApp = '233000000000'; // wa.me number, digits only

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

  static const List<_Faq> _faqs = [
    _Faq(
      question: 'How do I create a new lead?',
      answer:
          'Open In-Box / Leads from the sidebar and tap "Add Lead". Fill in the client\'s name, contact details and a short summary, then tap Create Lead. New leads land in the "New lead" stage.',
    ),
    _Faq(
      question: 'How does a lead become a claim?',
      answer:
          'Qualify the lead, then send the engagement form (Terms of Engagement + Letter of Authority). Once the client signs and submits their flight details, a claim record is created automatically.',
    ),
    _Faq(
      question: 'Where do I find a client\'s documents?',
      answer:
          'Open the Evidence Locker from the sidebar. Every claim\'s signature, Letter of Authority, Terms & Conditions and uploaded attachments are listed there. Sensitive identity details (NIN/Passport) are masked and can be revealed when needed.',
    ),
    _Faq(
      question: 'How do I send a legal letter to an airline?',
      answer:
          'In the Solicitors Workspace, open an escalated claim and tap "Send Legal Letter". Make sure the airline email is set first (via the Email Airlines page). A 7-day deadline is applied before court proceedings.',
    ),
    _Faq(
      question: 'How do I mark a claim as Won or Lost?',
      answer:
          'From the Solicitors Workspace, use the Won / Lost actions on a claim card. The client is notified and the outcome is recorded in the activity log shown under Notifications.',
    ),
    _Faq(
      question: 'What shows up in Notifications?',
      answer:
          'Notifications is a live activity feed: leads created, claims submitted, legal letters sent and claim outcomes. Use the filter chips to narrow by Lead or Claim.',
    ),
    _Faq(
      question: 'How do I add or manage staff?',
      answer:
          'Open Staffs from the sidebar to view team members and their roles. New sign-ups may need approval before they can access the dashboard.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportsModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _open(String url) => launchURL(url);

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final query = _model.searchController?.text.toLowerCase() ?? '';
    final faqs = query.isEmpty
        ? _faqs
        : _faqs
            .where((f) =>
                f.question.toLowerCase().contains(query) ||
                f.answer.toLowerCase().contains(query))
            .toList();

    return Title(
      title: 'Support',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                wrapWithModel(
                  model: _model.mennProModel,
                  updateCallback: () => safeSetState(() {}),
                  child: MennProWidget(selectedPage: 8),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // -- Header -----------------------------------
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _kNavy.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.support_agent_rounded,
                                          color: _kNavy, size: 26),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Support',
                                          style: GoogleFonts.interTight(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: _kNavy)),
                                      Text("We're here to help",
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // -- Contact card -----------------------------
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kNavy, Color(0xFF013a78)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Get in touch',
                                        style: GoogleFonts.interTight(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Reach the Claims Assist team — we usually reply within a few hours.',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white70),
                                    ),
                                    const SizedBox(height: 18),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _ContactButton(
                                          icon: Icons.email_outlined,
                                          label: 'Email us',
                                          onTap: () => _open(
                                              'mailto:$_supportEmail?subject=Claims%20Hub%20Support'),
                                        ),
                                        _ContactButton(
                                          icon: FontAwesomeIcons.whatsapp,
                                          label: 'WhatsApp',
                                          onTap: () => _open(
                                              'https://wa.me/$_supportWhatsApp'),
                                          faIcon: true,
                                        ),
                                        _ContactButton(
                                          icon: Icons.call_outlined,
                                          label: 'Call',
                                          onTap: () =>
                                              _open('tel:$_supportPhone'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        const Icon(Icons.email_outlined,
                                            size: 15, color: Colors.white70),
                                        const SizedBox(width: 6),
                                        SelectableText(_supportEmail,
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: Colors.white)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              // -- FAQ header + search ----------------------
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Frequently asked questions',
                                      style: GoogleFonts.interTight(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _kNavy)),
                                  SizedBox(
                                    width: 240,
                                    height: 40,
                                    child: TextField(
                                      controller: _model.searchController,
                                      focusNode: _model.searchFocusNode,
                                      onChanged: (_) => safeSetState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Search help...',
                                        hintStyle: const TextStyle(
                                            fontSize: 13, color: Colors.grey),
                                        prefixIcon: const Icon(Icons.search,
                                            size: 18, color: Colors.grey),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // -- FAQ list ---------------------------------
                              if (faqs.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 32),
                                  child: Center(
                                    child: Text(
                                      'No help articles match "$query".',
                                      style: GoogleFonts.inter(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                        dividerColor: Colors.grey.shade200),
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < faqs.length; i++)
                                          _FaqTile(
                                            faq: faqs[i],
                                            isLast: i == faqs.length - 1,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 28),
                              Center(
                                child: Text(
                                  'Claims Assist  -  v1.0.0',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey.shade400),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}

// -- FAQ model ----------------------------------------------------------------

class _Faq {
  const _Faq({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq, required this.isLast});
  final _Faq faq;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        iconColor: _kNavy,
        collapsedIconColor: Colors.grey,
        title: Text(
          faq.question,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              faq.answer,
              style: GoogleFonts.inter(
                  fontSize: 13, height: 1.5, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Contact button -----------------------------------------------------------

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.faIcon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool faIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            faIcon
                ? FaIcon(icon, size: 16, color: _kNavy)
                : Icon(icon, size: 18, color: _kNavy),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kNavy)),
          ],
        ),
      ),
    );
  }
}
