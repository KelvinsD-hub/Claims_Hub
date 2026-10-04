import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where the old public claim form was (/leadForm). Links to it were shared
/// before the website's claim form replaced it, so anyone who opens one is
/// sent there, with the link's source kept.
class FormMovedWidget extends StatefulWidget {
  const FormMovedWidget({super.key, this.source});

  final String? source;

  static String routeName = 'leadForm';
  static String routePath = '/leadForm';

  @override
  State<FormMovedWidget> createState() => _FormMovedWidgetState();
}

class _FormMovedWidgetState extends State<FormMovedWidget> {
  late final Uri _form = Uri.https('claimsassistltd.com', '/check', {
    'source': (widget.source ?? '').trim().isEmpty
        ? 'old-form-link'
        : widget.source!.trim(),
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => launchUrl(_form, webOnlyWindowName: '_self'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Our claim form has moved',
                  style: GoogleFonts.interTight(
                      fontSize: 22.0, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8.0),
              Text('Taking you to claimsassistltd.com…',
                  style: GoogleFonts.inter(fontSize: 14.0)),
              const SizedBox(height: 16.0),
              FilledButton(
                onPressed: () => launchUrl(_form, webOnlyWindowName: '_self'),
                child: const Text('Go to the claim form'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
