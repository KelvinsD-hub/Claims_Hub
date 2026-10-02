import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Everything the event log holds about one client's matter, newest first.
///
/// Entries about a lead carry `leadRef` only; entries about its claim carry
/// both. So following [leadRef] gives the whole story, lead and claim. A claim
/// with no lead falls back to [claimRef].
class RecordTimeline extends StatelessWidget {
  const RecordTimeline({super.key, this.leadRef, this.claimRef})
      : assert(leadRef != null || claimRef != null);

  final DocumentReference? leadRef;
  final DocumentReference? claimRef;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final logs = FirebaseFirestore.instance.collection('activity_logs');
    final query = leadRef != null
        ? logs.where('leadRef', isEqualTo: leadRef)
        : logs.where('claims', isEqualTo: claimRef);

    Widget message(String text) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 13.0, color: theme.secondaryText)),
        );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return message('The history could not be loaded.');
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        DateTime when(Map<String, dynamic> e) {
          final t = e['createdAt'] ?? e['timestamp'];
          return t is Timestamp ? t.toDate() : DateTime.now();
        }

        final entries = snapshot.data!.docs.map((d) => d.data()).toList()
          ..sort((a, b) => when(b).compareTo(when(a)));
        if (entries.isEmpty) return message('Nothing recorded yet.');

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 20.0),
          itemCount: entries.length,
          separatorBuilder: (_, __) =>
              Divider(height: 20.0, color: theme.alternate),
          itemBuilder: (context, i) {
            final e = entries[i];
            final note = e['note'] as String? ?? '';
            final description = e['description'] as String? ?? '';
            // A note's description is only its own first line.
            final isNote = e['note_type'] != null;
            final body =
                GoogleFonts.inter(fontSize: 13.0, color: theme.primaryText);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e['action'] as String? ?? 'Event',
                  style: body.copyWith(fontWeight: FontWeight.w700),
                ),
                if (!isNote && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(description, style: body),
                  ),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(note, style: body),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${e['performedByName'] ?? 'System'}  ·  '
                    '${dateTimeFormat('d MMM y, HH:mm', when(e))}',
                    style: GoogleFonts.inter(
                        fontSize: 11.5, color: theme.secondaryText),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
