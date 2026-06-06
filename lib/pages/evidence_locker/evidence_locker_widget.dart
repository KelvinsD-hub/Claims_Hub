import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'evidence_locker_model.dart';
export 'evidence_locker_model.dart';

const Color _kNavy = Color(0xFF002855);

class EvidenceLockerWidget extends StatefulWidget {
  const EvidenceLockerWidget({super.key});

  static String routeName = 'EvidenceLocker';
  static String routePath = '/evidenceLocker';

  @override
  State<EvidenceLockerWidget> createState() => _EvidenceLockerWidgetState();
}

class _EvidenceLockerWidgetState extends State<EvidenceLockerWidget> {
  late EvidenceLockerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EvidenceLockerModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  /// Number of stored files for a claim (excludes PII text fields).
  int _fileCount(ClaimsRecord c) {
    var n = 0;
    if (c.signature.isNotEmpty) n++;
    if (_loaUrl(c).isNotEmpty) n++;
    if (c.termsAndConditions.isNotEmpty) n++;
    n += c.attachedDocument.where((u) => u.trim().isNotEmpty).length;
    return n;
  }

  String _loaUrl(ClaimsRecord c) =>
      c.loaUrl.isNotEmpty ? c.loaUrl : c.letterOfAuthority;

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Title(
      title: 'Evidence Locker',
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
                  child: MennProWidget(selectedPage: 4),
                ),
                Expanded(
                  child: StreamBuilder<List<ClaimsRecord>>(
                    stream: queryClaimsRecord(
                      queryBuilder: (q) =>
                          q.orderBy('createdAt', descending: true),
                    ),
                    builder: (context, snapshot) {
                      final claims = snapshot.data ?? [];
                      final search =
                          _model.searchController?.text.toLowerCase() ?? '';
                      final filtered = search.isEmpty
                          ? claims
                          : claims.where((c) {
                              return c.fullName.toLowerCase().contains(search) ||
                                  c.airlineName
                                      .toLowerCase()
                                      .contains(search) ||
                                  c.clientEmail
                                      .toLowerCase()
                                      .contains(search) ||
                                  c.pnrNumber.toLowerCase().contains(search);
                            }).toList();

                      final totalFiles =
                          claims.fold<int>(0, (acc, c) => acc + _fileCount(c));
                      final withDocs =
                          claims.where((c) => _fileCount(c) > 0).length;
                      final missing = claims.length - withDocs;

                      return Column(
                        children: [
                          // -- Top bar ----------------------------------------
                          Container(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                const Icon(Icons.lock_person_outlined,
                                    color: _kNavy, size: 24),
                                const SizedBox(width: 12),
                                Text(
                                  'Evidence Locker',
                                  style: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .override(
                                        font: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold),
                                        color: _kNavy,
                                        letterSpacing: 0,
                                      ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 280,
                                  height: 40,
                                  child: TextField(
                                    controller: _model.searchController,
                                    focusNode: _model.searchFocusNode,
                                    onChanged: (_) => safeSetState(() {}),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search client, airline, email, PNR...',
                                      hintStyle: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                      prefixIcon: const Icon(Icons.search,
                                          size: 18, color: Colors.grey),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // -- Stats row --------------------------------------
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Row(
                              children: [
                                _StatCard(
                                  label: 'Claims',
                                  value: claims.length,
                                  color: _kNavy,
                                  icon: FontAwesomeIcons.folderOpen,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Documents on file',
                                  value: totalFiles,
                                  color: Colors.green.shade700,
                                  icon: FontAwesomeIcons.fileLines,
                                ),
                                const SizedBox(width: 16),
                                _StatCard(
                                  label: 'Awaiting documents',
                                  value: missing,
                                  color: Colors.orange.shade700,
                                  icon: FontAwesomeIcons.fileCircleExclamation,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // -- Claims / evidence list -------------------------
                          Expanded(
                            child: snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: _kNavy))
                                : filtered.isEmpty
                                    ? _EmptyState(hasSearch: search.isNotEmpty)
                                    : ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                            24, 0, 24, 24),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, i) =>
                                            _EvidenceCard(
                                          claim: filtered[i],
                                          initials:
                                              _initials(filtered[i].fullName),
                                          loaUrl: _loaUrl(filtered[i]),
                                          fileCount: _fileCount(filtered[i]),
                                        ),
                                      ),
                          ),
                        ],
                      );
                    },
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

// -- Stat card ----------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: FaIcon(icon, color: color, size: 18)),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -- Evidence card (one per claim) --------------------------------------------

class _EvidenceCard extends StatefulWidget {
  const _EvidenceCard({
    required this.claim,
    required this.initials,
    required this.loaUrl,
    required this.fileCount,
  });

  final ClaimsRecord claim;
  final String initials;
  final String loaUrl;
  final int fileCount;

  @override
  State<_EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<_EvidenceCard> {
  bool _revealPii = false;

  String _mask(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    if (v.length <= 4) return '*' * v.length;
    return '${'*' * (v.length - 4)}${v.substring(v.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.claim;
    final attachments =
        c.attachedDocument.where((u) => u.trim().isNotEmpty).toList();

    final fileDocs = <_DocItem>[
      _DocItem('Signature', c.signature, FontAwesomeIcons.signature),
      _DocItem('Letter of Authority', widget.loaUrl, FontAwesomeIcons.fileSignature),
      _DocItem('Terms & Conditions', c.termsAndConditions,
          FontAwesomeIcons.fileContract),
      for (var i = 0; i < attachments.length; i++)
        _DocItem(
            attachments.length == 1 ? 'Attachment' : 'Attachment ${i + 1}',
            attachments[i],
            FontAwesomeIcons.paperclip),
    ];
    final present = fileDocs.where((d) => d.url.trim().isNotEmpty).toList();
    final missing = fileDocs
        .where((d) => d.url.trim().isEmpty)
        .where((d) => d.label != 'Attachment')
        .toList();

    final hasPii = c.nin.isNotEmpty || c.passport.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kNavy.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(widget.initials,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, color: _kNavy)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.fullName.isNotEmpty ? c.fullName : 'Unnamed client',
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (c.airlineName.isNotEmpty) c.airlineName,
                        if (c.clientEmail.isNotEmpty) c.clientEmail,
                      ].join('  -  '),
                      style:
                          GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (c.claimStatus.isNotEmpty) _StatusChip(status: c.claimStatus),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.fileCount > 0
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.fileCount} file${widget.fileCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: widget.fileCount > 0
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),

          // Documents
          if (present.isEmpty && missing.isEmpty && !hasPii)
            Text('No documents submitted yet.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final d in present)
                  _DocChip(
                    label: d.label,
                    icon: d.icon,
                    onTap: () => launchURL(d.url),
                  ),
                for (final d in missing) _MissingChip(label: d.label),
              ],
            ),

          // Sensitive PII
          if (hasPii) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 16, color: Colors.redAccent),
                const SizedBox(width: 6),
                Text('Sensitive identity details',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _revealPii = !_revealPii),
                  icon: Icon(
                      _revealPii
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16),
                  label: Text(_revealPii ? 'Hide' : 'Reveal',
                      style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: _kNavy),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (c.nin.isNotEmpty)
                  _PiiField(
                      label: 'NIN',
                      value: _revealPii ? c.nin : _mask(c.nin),
                      canCopy: _revealPii,
                      rawValue: c.nin),
                if (c.passport.isNotEmpty)
                  _PiiField(
                      label: 'Passport',
                      value: _revealPii ? c.passport : _mask(c.passport),
                      canCopy: _revealPii,
                      rawValue: c.passport),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DocItem {
  const _DocItem(this.label, this.url, this.icon);
  final String label;
  final String url;
  final IconData icon;
}

// -- Document chip (viewable file) --------------------------------------------

class _DocChip extends StatelessWidget {
  const _DocChip(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kNavy.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kNavy.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 14, color: _kNavy),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kNavy)),
            const SizedBox(width: 6),
            const Icon(Icons.open_in_new, size: 13, color: _kNavy),
          ],
        ),
      ),
    );
  }
}

class _MissingChip extends StatelessWidget {
  const _MissingChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_circle_outline,
              size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _PiiField extends StatelessWidget {
  const _PiiField({
    required this.label,
    required this.value,
    required this.canCopy,
    required this.rawValue,
  });

  final String label;
  final String value;
  final bool canCopy;
  final String rawValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: GoogleFonts.robotoMono(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            if (canCopy) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: rawValue));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.copy, size: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color color = Colors.blueGrey;
    if (s.contains('won') || s.contains('paid') || s.contains('approv')) {
      color = Colors.green.shade700;
    } else if (s.contains('lost') || s.contains('reject') ||
        s.contains('declin')) {
      color = Colors.red.shade600;
    } else if (s.contains('review') || s.contains('pending') ||
        s.contains('submit')) {
      color = Colors.orange.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// -- Empty state --------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
              hasSearch
                  ? FontAwesomeIcons.magnifyingGlass
                  : FontAwesomeIcons.folderOpen,
              size: 48,
              color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No claims match your search' : 'No evidence yet',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch
                ? 'Try a different client, airline or email.'
                : 'Documents submitted with claims will appear here.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
