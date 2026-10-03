import '/claims/component/staffs_roles/staffs_roles_widget.dart';
import '/components/staff_invites.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'staffs_model.dart';
export 'staffs_model.dart';

class StaffsWidget extends StatefulWidget {
  const StaffsWidget({super.key});

  static String routeName = 'Staffs';
  static String routePath = '/staffs';

  @override
  State<StaffsWidget> createState() => _StaffsWidgetState();
}

class _StaffsWidgetState extends State<StaffsWidget> {
  late StaffsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _invites = GlobalKey<PendingInvitesPanelState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StaffsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Title(
        title: 'Staffs',
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
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const WorkSidebar(selected: WorkPage.staff),
                  Expanded(
                    child: WorkBody(
                      page: WorkPage.staff,
                      title: 'Staff',
                      subtitle: 'Who can sign in, and what each person may do',
                      icon: Icons.groups_outlined,
                      actions: [
                        WorkButton(
                          label: 'Invite staff',
                          icon: Icons.person_add_alt_1_outlined,
                          filled: true,
                          onTap: () async {
                            if (await showInviteStaff(context)) {
                              _invites.currentState?.reload();
                            }
                          },
                        ),
                      ],
                      child: Container(
                        decoration: BoxDecoration(),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              40.0, 40.0, 40.0, 40.0),
                          child: SingleChildScrollView(
                            primary: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                PendingInvitesPanel(key: _invites),
                                wrapWithModel(
                                  model: _model.staffsRolesModel,
                                  updateCallback: () => safeSetState(() {}),
                                  child: StaffsRolesWidget(),
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
        ));
  }
}
