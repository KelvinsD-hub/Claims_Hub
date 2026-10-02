import '/flutter_flow/flutter_flow_util.dart';
import '/menus_file/menn_pro/menn_pro_widget.dart';
import 'monitor_widget.dart' show MonitorWidget;
import 'package:flutter/material.dart';

class MonitorModel extends FlutterFlowModel<MonitorWidget> {
  late MennProModel mennProModel;

  @override
  void initState(BuildContext context) {
    mennProModel = createModel(context, () => MennProModel());
  }

  @override
  void dispose() {
    mennProModel.dispose();
  }
}
