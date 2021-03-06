import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:remedi_update/viewmodel/i_force_update_viewmodel.dart';
import 'package:stacked_mvvm/stacked_mvvm.dart';

import 'force_update_view.dart';

class ForceUpdatePage extends IPage<IForceUpdateViewModel> {
  static const String ROUTE_NAME = "/force_update";

  final String? image;

  ForceUpdatePage(
      {Key? key, this.image, required IForceUpdateViewModel viewModel})
      : super(key: key, viewModel: viewModel);

  @override
  ForceUpdateView body(
      BuildContext context, IForceUpdateViewModel viewModel, Widget? child) {
    return ForceUpdateView(
      image: image,
    );
  }

  @override
  Future logScreenOpen(String screenName) async {}

  @override
  String get screenName => "force_update";
}
