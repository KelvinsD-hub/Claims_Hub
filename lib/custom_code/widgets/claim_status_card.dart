// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cached_network_image/cached_network_image.dart';

class ClaimStatusCard extends StatefulWidget {
  const ClaimStatusCard({
    super.key,
    this.width,
    this.height,
    required this.clientName,
    required this.airlineName,
    required this.pnrNumber,
    required this.claimStage,
    this.airlineLogoUrl,
    this.onTap,
  });

  final double? width;
  final double? height;

  final String clientName;
  final String airlineName;
  final String pnrNumber;

  /// 0 = Leads, 1 = Evidence, 2 = Airline, 3 = Settlement
  final int claimStage;

  final String? airlineLogoUrl;
  final Future<dynamic> Function()? onTap;

  @override
  State<ClaimStatusCard> createState() => _ClaimStatusCardState();
}

class _ClaimStatusCardState extends State<ClaimStatusCard> {
  static const _navy = Color(0xFF002855);

  int get _stage => widget.claimStage.clamp(0, 3);

  String get _initials {
    final parts = widget.clientName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.clientName.isNotEmpty
        ? widget.clientName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap?.call(),
      child: Container(
        width: widget.width,
        constraints: BoxConstraints(
          minHeight: widget.height ?? 0,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => widget.onTap?.call(),
            splashColor: _navy.withOpacity(0.04),
            highlightColor: _navy.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    initials: _initials,
                    clientName: widget.clientName,
                    airlineName: widget.airlineName,
                    pnrNumber: widget.pnrNumber,
                    airlineLogoUrl: widget.airlineLogoUrl,
                  ),
                  const SizedBox(height: 16),
                  _Pipeline(stage: _stage),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header row ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.initials,
    required this.clientName,
    required this.airlineName,
    required this.pnrNumber,
    this.airlineLogoUrl,
  });

  final String initials;
  final String clientName;
  final String airlineName;
  final String pnrNumber;
  final String? airlineLogoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Initials avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF002855),
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Name + airline info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: const Color(0xFF1A1A1A),
                    ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.flight_takeoff_rounded,
                      size: 11, color: Color(0xFF7C9CB4)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$airlineName  •  PNR: $pnrNumber',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Airline logo or placeholder
        _AirlineLogo(url: airlineLogoUrl),
      ],
    );
  }
}

class _AirlineLogo extends StatelessWidget {
  const _AirlineLogo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.flight, size: 18, color: Color(0xFF7C9CB4)),
      );
}

// ─── Pipeline indicator ───────────────────────────────────────────────────────

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.stage});
  final int stage;

  static const _stages = ['Leads', 'Evidence', 'Airline', 'Settlement'];
  static const _navy = Color(0xFF002855);
  static const _gold = Color(0xFFE6B011);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stage label + counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stage: ${_stages[stage]}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _navy,
                letterSpacing: 0.2,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${stage + 1} of 4',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Step dots connected by lines
        Row(
          children: List.generate(_stages.length * 2 - 1, (i) {
            if (i.isOdd) {
              final stageIdx = i ~/ 2;
              return Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: stageIdx < stage
                        ? const LinearGradient(
                            colors: [_navy, _navy],
                          )
                        : null,
                    color: stageIdx < stage ? null : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }
            final stageIdx = i ~/ 2;
            return _StepDot(
              index: stageIdx,
              isCompleted: stageIdx < stage,
              isCurrent: stageIdx == stage,
            );
          }),
        ),
        const SizedBox(height: 7),

        // Labels below each dot
        Row(
          children: List.generate(_stages.length, (i) {
            final isPast = i < stage;
            final isCurrent = i == stage;
            return Expanded(
              child: Text(
                _stages[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : i == _stages.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? _gold
                      : isPast
                          ? _navy
                          : const Color(0xFFBBBBBB),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
  });

  final int index;
  final bool isCompleted;
  final bool isCurrent;

  static const _navy = Color(0xFF002855);
  static const _gold = Color(0xFFE6B011);

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 22,
        height: 22,
        decoration:
            const BoxDecoration(color: _navy, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded,
            color: Colors.white, size: 13),
      );
    }
    if (isCurrent) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: _gold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.45),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      );
    }
    // Future stage
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border:
            Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
      ),
    );
  }
}
