import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'lead_form_model.dart';
export 'lead_form_model.dart';

/// Create a page mobile responsive lead generation landing page for Claims
/// Assist The top has a professional logo and a heading Check Your Claim
/// Eligibility in 60 Seconds Below the heading place a vertical list of 5
/// large, high quality buttons with icons for Flight Delay PCP Car Finance
/// Housing Disrepair Bank Claim and Insurance Claim When a button is clicked
/// show a simple slide in form with 4 fields Full Name Email Phone Number and
/// Postcode  Use a Check Now primary action button at the bottom Style Clean
/// white background and professional gold and navy blue accents
class LeadFormWidget extends StatefulWidget {
  const LeadFormWidget({super.key, this.source});

  final String? source;

  static String routeName = 'leadForm';
  static String routePath = '/leadForm';

  @override
  State<LeadFormWidget> createState() => _LeadFormWidgetState();
}

class _LeadFormWidgetState extends State<LeadFormWidget> {
  late LeadFormModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LeadFormModel());

    _model.fullNameTextController ??= TextEditingController();
    _model.fullNameFocusNode ??= FocusNode();

    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();

    _model.phoneNumberTextController ??= TextEditingController();
    _model.phoneNumberFocusNode ??= FocusNode();

    _model.airlineNameTextController ??= TextEditingController();
    _model.airlineNameFocusNode ??= FocusNode();

    _model.noteTextFieldTextController ??= TextEditingController();
    _model.noteTextFieldFocusNode ??= FocusNode();

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
        title: 'leadForm',
        color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).info,
            appBar: valueOrDefault(currentUserDocument?.hide, '') != null &&
                    valueOrDefault(currentUserDocument?.hide, '') != ''
                ? AppBar(
                    backgroundColor: FlutterFlowTheme.of(context).info,
                    automaticallyImplyLeading: false,
                    leading: FlutterFlowIconButton(
                      borderColor: Colors.transparent,
                      borderRadius: 30.0,
                      borderWidth: 1.0,
                      buttonSize: 60.0,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 30.0,
                      ),
                      onPressed: () async {
                        context.pop();
                      },
                    ),
                    title: Text(
                      'Add Claim',
                      style: FlutterFlowTheme.of(context)
                          .headlineMedium
                          .override(
                            font: GoogleFonts.interTight(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).secondaryText,
                            fontSize: 22.0,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .fontStyle,
                          ),
                    ),
                    actions: [],
                    centerTitle: true,
                    elevation: 0.0,
                  )
                : null,
            body: SafeArea(
              top: true,
              child: Stack(
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(24.0, 10.0, 24.0, 0.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (responsiveVisibility(
                                context: context,
                                desktop: false,
                              ))
                                Container(
                                  width: double.infinity,
                                  height: 100.0,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      fit: BoxFit.fitWidth,
                                      image: Image.asset(
                                        'assets/images/claimsLogo1.jpeg',
                                      ).image,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              Text(
                                'Send Your Claim in 60 Seconds',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .displaySmall
                                    .override(
                                      font: GoogleFonts.interTight(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .displaySmall
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF1A237E),
                                      fontSize: 28.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .displaySmall
                                          .fontStyle,
                                      lineHeight: 1.2,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  TextFormField(
                                    controller: _model.fullNameTextController,
                                    focusNode: _model.fullNameFocusNode,
                                    autofocus: true,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelText: 'Full Name',
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF1A237E),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      hintText: 'Full Name',
                                      hintStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF999999),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFFFD700),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF1A237E),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              16.0, 16.0, 16.0, 16.0),
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A237E),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    keyboardType: TextInputType.name,
                                    cursorColor: Color(0xFF1A237E),
                                    validator: _model
                                        .fullNameTextControllerValidator
                                        .asValidator(context),
                                    inputFormatters: [
                                      if (!isAndroid && !isiOS)
                                        TextInputFormatter.withFunction(
                                            (oldValue, newValue) {
                                          return TextEditingValue(
                                            selection: newValue.selection,
                                            text: newValue.text
                                                .toCapitalization(
                                                    TextCapitalization.words),
                                          );
                                        }),
                                    ],
                                  ),
                                  TextFormField(
                                    controller: _model.emailTextController,
                                    focusNode: _model.emailFocusNode,
                                    textInputAction: TextInputAction.next,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF1A237E),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      hintText: 'Email Address',
                                      hintStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF999999),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFFFD700),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF1A237E),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              16.0, 16.0, 16.0, 16.0),
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A237E),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    keyboardType: TextInputType.emailAddress,
                                    cursorColor: Color(0xFF1A237E),
                                    validator: _model
                                        .emailTextControllerValidator
                                        .asValidator(context),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color:
                                              FlutterFlowTheme.of(context).info,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: Color(0xFFFFD700),
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(15.0),
                                                child: CachedNetworkImage(
                                                  fadeInDuration: Duration(
                                                      milliseconds: 100),
                                                  fadeOutDuration: Duration(
                                                      milliseconds: 100),
                                                  imageUrl: getCORSProxyUrl(
                                                    valueOrDefault<String>(
                                                      functions.countryFlag(_model
                                                          .countryDropDownValue),
                                                      'data:image/png;base64,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',
                                                    ),
                                                  ),
                                                  width: 50.0,
                                                  height: 40.0,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              FlutterFlowDropDown<String>(
                                                controller: _model
                                                        .countryDropDownValueController ??=
                                                    FormFieldController<String>(
                                                  _model.countryDropDownValue ??=
                                                      'United Kingdom',
                                                ),
                                                options:
                                                    functions.countryList(),
                                                onChanged: (val) =>
                                                    safeSetState(() => _model
                                                            .countryDropDownValue =
                                                        val),
                                                width: 260.0,
                                                height: 40.0,
                                                textStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF1A237E),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                hintText: 'Select your country',
                                                icon: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: Color(0xFF1A237E),
                                                  size: 24.0,
                                                ),
                                                fillColor:
                                                    FlutterFlowTheme.of(context)
                                                        .info,
                                                elevation: 2.0,
                                                borderColor: Colors.transparent,
                                                borderWidth: 0.0,
                                                borderRadius: 8.0,
                                                margin: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        12.0, 0.0, 12.0, 0.0),
                                                hidesUnderline: true,
                                                isOverButton: false,
                                                isSearchable: false,
                                                isMultiSelect: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color:
                                              FlutterFlowTheme.of(context).info,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                          border: Border.all(
                                            color: Color(0xFFFFD700),
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  5.0, 0.0, 5.0, 0.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        5.0, 0.0, 0.0, 0.0),
                                                child: InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    _model.countryCode = functions
                                                        .dialedCountryCode(_model
                                                            .countryDropDownValue);
                                                    safeSetState(() {});
                                                  },
                                                  child: Text(
                                                    valueOrDefault<String>(
                                                      functions.dialedCountryCode(
                                                          _model
                                                              .countryDropDownValue),
                                                      '+44',
                                                    ),
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: _model
                                                      .phoneNumberTextController,
                                                  focusNode: _model
                                                      .phoneNumberFocusNode,
                                                  autofocus: true,
                                                  textInputAction:
                                                      TextInputAction.next,
                                                  obscureText: false,
                                                  decoration: InputDecoration(
                                                    hintText: 'Enter Number',
                                                    hintStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryText,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                    enabledBorder:
                                                        InputBorder.none,
                                                    focusedBorder:
                                                        InputBorder.none,
                                                    errorBorder:
                                                        InputBorder.none,
                                                    focusedErrorBorder:
                                                        InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(16.0, 0.0,
                                                                16.0, 0.0),
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: const Color(0xFF1A237E),
                                                        fontSize: 16.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                  maxLines: null,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  validator: _model
                                                      .phoneNumberTextControllerValidator
                                                      .asValidator(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ].divide(SizedBox(height: 10.0)),
                                  ),
                                  TextFormField(
                                    controller:
                                        _model.airlineNameTextController,
                                    focusNode: _model.airlineNameFocusNode,
                                    textInputAction: TextInputAction.next,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelText: 'Airline Name',
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF1A237E),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      hintText: 'Enter name',
                                      hintStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF999999),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFFFD700),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF1A237E),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              16.0, 16.0, 16.0, 16.0),
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A237E),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    cursorColor: Color(0xFF1A237E),
                                    validator: _model
                                        .airlineNameTextControllerValidator
                                        .asValidator(context),
                                  ),
                                  FlutterFlowDropDown<String>(
                                    controller: _model
                                            .complainDropdownValueController ??=
                                        FormFieldController<String>(null),
                                    options: [
                                      'Flight Delay (3+ Hours)',
                                      'Flight Cancellation Without Notice',
                                      'Denied Boarding / Overbooking',
                                      'Missed Connection (Airline Fault)',
                                      'Tarmac Delay (4+ Hours)',
                                      'Duty of Care Failure (No Meals / Hotel)',
                                      'Involuntary Downgrade',
                                      'Lost Baggage',
                                      'Damaged Baggage',
                                      'Delayed Baggage',
                                      'Personal Injury During Flight',
                                      'Discriminatory Treatment',
                                      'Refund Not Received',
                                      'Failure to Rebook After Cancellation',
                                    ],
                                    onChanged: (val) => safeSetState(() =>
                                        _model.complainDropdownValue = val),
                                    width: double.infinity,
                                    height: 50.0,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A237E),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    hintText: 'Select Complaint Type',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF1A237E),
                                      size: 24.0,
                                    ),
                                    fillColor:
                                        FlutterFlowTheme.of(context).info,
                                    elevation: 2.0,
                                    borderColor: Color(0xFFFFD700),
                                    borderWidth: 2.0,
                                    borderRadius: 8.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        12.0, 0.0, 12.0, 0.0),
                                    hidesUnderline: true,
                                    isOverButton: false,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                  FlutterFlowDropDown<String>(
                                    controller: _model
                                            .contactDropdownValueController ??=
                                        FormFieldController<String>(null),
                                    options: [
                                      'WhatsApp',
                                      'Send Email',
                                      'Phone Call'
                                    ],
                                    onChanged: (val) => safeSetState(() =>
                                        _model.contactDropdownValue = val),
                                    width: double.infinity,
                                    height: 50.0,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.w500,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A237E),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    hintText: 'Select Medium of Contact',
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Color(0xFF1A237E),
                                      size: 24.0,
                                    ),
                                    fillColor:
                                        FlutterFlowTheme.of(context).info,
                                    elevation: 2.0,
                                    borderColor: Color(0xFFFFD700),
                                    borderWidth: 2.0,
                                    borderRadius: 8.0,
                                    margin: EdgeInsetsDirectional.fromSTEB(
                                        12.0, 0.0, 12.0, 0.0),
                                    hidesUnderline: true,
                                    isOverButton: false,
                                    isSearchable: false,
                                    isMultiSelect: false,
                                  ),
                                  TextFormField(
                                    controller:
                                        _model.noteTextFieldTextController,
                                    focusNode: _model.noteTextFieldFocusNode,
                                    textCapitalization: TextCapitalization.none,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      labelText: 'Any Note (Optional)',
                                      labelStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF1A237E),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      hintText: 'Enter here',
                                      hintStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Color(0xFF999999),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFFFD700),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF1A237E),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x00000000),
                                          width: 2.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              16.0, 16.0, 16.0, 16.0),
                                    ),
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF1A237E),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                    maxLines: 3,
                                    cursorColor: Color(0xFF1A237E),
                                    validator: _model
                                        .noteTextFieldTextControllerValidator
                                        .asValidator(context),
                                    inputFormatters: [
                                      if (!isAndroid && !isiOS)
                                        TextInputFormatter.withFunction(
                                            (oldValue, newValue) {
                                          return TextEditingValue(
                                            selection: newValue.selection,
                                            text: newValue.text
                                                .toCapitalization(
                                                    TextCapitalization.none),
                                          );
                                        }),
                                    ],
                                  ),
                                ].divide(SizedBox(height: 16.0)),
                              ),
                            ].divide(SizedBox(height: 9.0)),
                          ),
                          Align(
                            alignment: AlignmentDirectional(0.0, 1.0),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 20.0, 0.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  final docRef = LeadsRecord.collection.doc();
                                  await docRef.set(createLeadsRecordData(
                                    fullName:
                                        _model.fullNameTextController.text,
                                    email: _model.emailTextController.text,
                                    claimType: 'Flight Claims',
                                    utmSource: widget.source ?? 'direct',
                                    initialSummary: _model
                                        .noteTextFieldTextController.text,
                                    status: 'New lead',
                                    createdAt: getCurrentTimestamp,
                                    isQualified: false,
                                    complaintType:
                                        _model.complainDropdownValue,
                                    airlineName: _model
                                        .airlineNameTextController.text,
                                    agentRef: currentUserReference,
                                    mediumOfContact:
                                        _model.contactDropdownValue,
                                    isContacted: false,
                                    phone:
                                        '${functions.dialedCountryCode(_model.countryDropDownValue)}${_model.phoneNumberTextController.text}',
                                    country: _model.countryDropDownValue,
                                  ));
                                  final reference =
                                      'CA-${docRef.id.substring(0, 8).toUpperCase()}';

                                  context.pushNamed(
                                    IntakeSuccessWidget.routeName,
                                    queryParameters: {
                                      'reference': serializeParam(
                                          reference, ParamType.String),
                                    }.withoutNulls,
                                  );
                                },
                                text: 'Submit Claims',
                                options: FFButtonOptions(
                                  width: double.infinity,
                                  height: 56.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      32.0, 0.0, 32.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: Color(0xFF002855),
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleLarge
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFFE6B011),
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                  elevation: 0.0,
                                  borderSide: BorderSide(
                                    color: Color(0xFFE6B011),
                                    width: 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                          ),
                        ]
                            .divide(SizedBox(height: 25.0))
                            .addToStart(SizedBox(height: 10.0))
                            .addToEnd(SizedBox(height: 24.0)),
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
