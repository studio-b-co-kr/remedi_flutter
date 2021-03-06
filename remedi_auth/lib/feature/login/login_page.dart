import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:remedi_auth/viewmodel/i_login_viewmodel.dart';
import 'package:stacked_mvvm/stacked_mvvm.dart';

import 'login_view.dart';

class LoginPage extends IPage<ILoginViewModel> {
  static const ROUTE_NAME_SPLASH = '/login_splash';
  static const ROUTE_NAME = '/login';

  static Future<dynamic> pushAndReplacement(BuildContext context) async {
    return Navigator.pushReplacementNamed(context, ROUTE_NAME_SPLASH);
  }

  static Future<dynamic> push(BuildContext context) async {
    return Navigator.pushNamed(context, ROUTE_NAME);
  }

  final String? logoApp;
  final String? logoCompany;
  final String? routeBackTo;
  final Color? backgroundColors;
  final Color? appbarColor;

  LoginPage(
      {Key? key,
      this.logoApp,
      this.logoCompany,
      this.routeBackTo,
      this.appbarColor,
      this.backgroundColors,
      required ILoginViewModel viewModel})
      : super(key: key, viewModel: viewModel);

  @override
  IView<ILoginViewModel> body(
      BuildContext context, ILoginViewModel viewModel, Widget? child) {
    return LoginView(
      logoApp: logoApp,
      appbarColor: appbarColor,
      backgroundColors: backgroundColors,
      logoCompany: logoCompany,
    );
  }

  @override
  void onListen(BuildContext context, ILoginViewModel viewModel) {
    super.onListen(context, viewModel);
    switch (viewModel.state) {
      case LoginViewState.Idle:
        break;
      case LoginViewState.Loading:
        break;
      case LoginViewState.Error:
        break;
      case LoginViewState.Success:
        if (routeBackTo != null) {
          Navigator.pushReplacementNamed(context, routeBackTo!);
        } else {
          Navigator.pop(context);
        }
        break;
    }
  }

  @override
  Future logScreenOpen(String screenName) async {}

  @override
  String get screenName => 'login';
}
