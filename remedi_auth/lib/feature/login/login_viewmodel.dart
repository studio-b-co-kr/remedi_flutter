import 'dart:developer' as dev;

// ignore: implementation_imports
import 'package:flutter/services.dart';
import 'package:flutter_kakao_login/flutter_kakao_login.dart';
import 'package:remedi_auth/auth_repository.dart';
import 'package:remedi_auth/model/apple_credential.dart';
import 'package:remedi_auth/model/i_app_credential.dart';
import 'package:remedi_auth/model/kakao_credential.dart';
import 'package:remedi_auth/repository/i_login_repository.dart';
import 'package:remedi_auth/resources/app_strings.dart';
import 'package:remedi_auth/viewmodel/i_login_viewmodel.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../auth_error.dart';

class LoginViewModel extends ILoginViewModel {
  final String? kakaoAppId;
  final ILoginRepository repository;

  LoginViewModel({required this.repository, this.kakaoAppId}) : super();

  @override
  LoginViewState get initState => LoginViewState.Idle;

  @override
  loginWithApple() async {
    update(state: LoginViewState.Loading);
    bool isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      this.authError = AuthError(
          title: AppStrings.loginError,
          code: AppStrings.codeAppleLoginError,
          message: AppStrings.invalidVersionAppleLogin);
      update(state: LoginViewState.Error);
      return;
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      AppleCredential appleCredential = AppleCredential(
          userIdentifier: credential.userIdentifier,
          identityToken: credential.identityToken,
          authorizationCode: credential.authorizationCode,
          email: credential.email);

      ICredential appCredential =
          await repository.loginWithApple(appleCredential);

      if (appCredential.isError) {
        this.authError = appCredential.error;
        update(state: LoginViewState.Error);
        return;
      }

      await Future.wait([
        AuthRepository.instance().writeUserId(appCredential.userId),
        AuthRepository.instance().writeUserCode(appCredential.userCode),
        AuthRepository.instance().writeAccessToken(appCredential.accessToken),
        AuthRepository.instance()
            .writeRefreshToken(appCredential.refreshToken ?? "")
      ]);

      update(state: LoginViewState.Success);
      return;
    } catch (e) {
      String title = AppStrings.loginError;
      String code = AppStrings.codeAppleLoginError;
      String message = AppStrings.messageAuthError;

      if (e is SignInWithAppleAuthorizationException) {
        title = e.code.toString();
        code = e.message;
        message = e.message;
        if (e.code == AuthorizationErrorCode.canceled ||
            e.code == AuthorizationErrorCode.unknown) {
          update(state: LoginViewState.Idle);
          return;
        }
      }

      this.authError =
          AuthError(title: title, code: code, message: message, error: e);
      update(state: LoginViewState.Error);
    }
  }

  @override
  loginWithKakao() async {
    update(state: LoginViewState.Loading);

    final FlutterKakaoLogin kakaoSignIn = FlutterKakaoLogin();
    await kakaoSignIn.init(kakaoAppId!);

    final String hashKey = await (kakaoSignIn.hashKey);
    dev.log(hashKey, name: "Kakao HASH");
    String kakaoAccessToken;
    String? kakaoId;
    try {
      var login = await kakaoSignIn.logIn();

      switch (login.status) {
        case KakaoLoginStatus.loggedIn:
          dev.log("${login.token?.accessToken}", name: "Kakao Login Success");
          kakaoAccessToken = login.token!.accessToken!;
          login = await kakaoSignIn.getUserMe();
          break;
        case KakaoLoginStatus.loggedOut:
        case KakaoLoginStatus.unlinked:
          this.authError = AuthError(
              title: AppStrings.codeKakaoLoginError,
              code: AppStrings.codeKakaoLoginError,
              message: AppStrings.messageAuthError);
          await kakaoSignIn.logOut();
          update(state: LoginViewState.Error);
          return;
      }

      kakaoId = login.account?.userID ?? "";

      int id = 0;
      try {
        id = int.parse(kakaoId);
      } catch (e) {
        this.authError = AuthError(
            title: AppStrings.codeKakaoLoginError,
            code: AppStrings.codeKakaoLoginError,
            message: AppStrings.messageAuthError);
        await kakaoSignIn.logOut();
        update(state: LoginViewState.Error);
        return;
      }

      ICredential credential = await repository.loginWithKakao(
          KakaoCredential(accessToken: kakaoAccessToken, id: id));

      if (credential.isError) {
        this.authError = credential.error;
        await kakaoSignIn.logOut();
        update(state: LoginViewState.Error);
        return;
      }

      await Future.wait([
        AuthRepository.instance().writeUserId(credential.userId),
        AuthRepository.instance().writeUserCode(credential.userCode),
        AuthRepository.instance().writeAccessToken(credential.accessToken),
        AuthRepository.instance()
            .writeRefreshToken(credential.refreshToken ?? "")
      ]);

      await kakaoSignIn.logOut();
      update(state: LoginViewState.Success);
      return;
    } catch (error) {
      String? title = AppStrings.codeKakaoLoginError;
      String code = AppStrings.codeKakaoLoginError;
      String? message = AppStrings.messageAuthError;

      if (error is PlatformException) {
        title = error.message ?? "";
        code = error.code;
        message = error.details;
      }

      this.authError =
          AuthError(title: title, code: code, message: message, error: error);

      if (message == "cancelled." ||
          title ==
              "The operation couldn???t be completed. (KakaoSDKCommon.SdkError error 0.)") {
        update(state: LoginViewState.Idle);
      } else {
        update(state: LoginViewState.Error);
      }
    }
  }
}
