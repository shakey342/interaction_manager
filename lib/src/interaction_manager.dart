
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:interaction_manager/src/dialog_builders/message_dialog.dart';
import 'package:interaction_manager/src/dialog_builders/network_configuration_dialog.dart';
import 'package:interaction_manager/src/interaction_manager_impl.dart';

import 'dialog_builders/form_dialog.dart';

export 'package:interaction_manager/src/dialog_builders/message_dialog.dart';
export 'package:interaction_manager/src/dialog_builders/network_configuration_dialog.dart';

/// To register a dialog you have to provide a builder function that
/// returns the content of the dialog that has this signatur.
/// The generic parameter [T] defines the type of data that you want
/// to pass when the dialog should be displayed. It will be passed
/// to the builder function
typedef DialogBuilderFunc<T> = Widget Function(BuildContext, T);

/// The [InteractionManager] allows you to display dialogs and push `Routes` from
/// anywhere in your code even from places where this is normally not possible because
/// you might not have a `BuildContext` available like from your business logic.
/// To make this possible you have to register builder functions for your dialogs and
/// add an [InteractionConnector] widget directly above
/// your `Material/CupertinoApp` like
///``` 
/// return MaterialApp(
///    theme: ThemeData(
///        brightness: Brightness.dark,
///        accentColor: Colors.white,
///    home: InteractionConnector(
///       dialogsInitFunction: registerDialogs, 
///       appInitFunction: () async => registerBackend(),
///       child: StartUpPage()),
/// ```
/// Use [dialogsInitFunction] to register your own dialogs
/// The function that you pass to [appInitFunction] will be called after
/// the [InteractionManager] is initialized so it can be used inside of [appInitFunction]
/// 
/// [InteractionManager] registers itself inside `GetIt` (https://pub.dev/packages/get_it) so
/// you can access it from anywhere in your app when you add `GetIt` to your project like it
/// this example that displays a [QueryDialog]
/// ```
///  MessageDialogResults result =
///      await GetIt.I<InteractionManager>().showQueryDialog(
///    'This is a query dialog!',
///    title: 'Query Dialog',
///  );
/// ```
/// This was also an example for the available standard dialogs that you can directly
/// use: 
///  * MessageDialog
///  * QueryDialog
///  * LoginDialog
///  * NetworkConfigurationDialog
///  * FormDialog
/// 
/// More details in the documentation of the methods and classes below.
abstract class InteractionManager {
  /// Dialogs are registered with a name. In most cases registering more
  /// than one dialog with the same name is probably a bug. Therefore an
  /// assertion will be thrown if you try.
  /// If you really need to replace a registered dialog set [allowReassigningDialogs]
  /// to `true`.
  bool allowReassigningDialogs = false;

  /// [navigateTo] allows you to push a named `Route` from anywhere in your app.
  ///The route name will be passed to the root navigator's [onGenerateRoute] callback . 
  ///The returned route will be pushed into the navigator. 
  ///The new route and the previous route (if any) are notified (see [Route.didPush] 
  ///and [Route.didChangeNext]). If the [Navigator] has any [Navigator.observers], 
  ///they will be notified as well (see [NavigatorObserver.didPush]).
  ///Ongoing gestures within the current route are canceled when a new route is pushed.
  ///
  ///Returns a [Future] that completes to the result value passed to [pop] when the 
  ///pushed route is popped off the navigator.
  ///The [T] type argument is the type of the return value of the route.
  ///
  ///To use [pushNamed], an [onGenerateRoute] callback must be provided,
  ///
  ///The provided arguments are passed to the pushed route via [RouteSettings.arguments]. 
  ///Any object can be passed as arguments (e.g. a [String], [int], or an instance of a custom MyRouteArguments class). Often, a [Map] is used to pass key-value pairs.
  ///
  ///The arguments may be used in [Navigator.onGenerateRoute] or [Navigator.onUnknownRoute] to construct the route.
  Future<T> navigateTo<T>(String routeName, {Object arguments});

  /// If the [InteractionManager] has open dialog(s) this will close the top one. You can pass an optional
  /// argument [result] that will be received at the place where the dialog was opened as if the dialog 
  /// popped itself with it
  void closeDialog<TResult>([TResult result]);


  void registerCustomDialog<DialogDataType>(
      DialogBuilderFunc<DialogDataType> builder, String dialogName);

  Future<ResultType> showRegisteredDialog<DialogDataType, ResultType>(
      {String dialogName,
      DialogDataType data,
      bool barrierDismissible = false});

  Future showMessageDialog(
    String message, {
    String title,
    String closeButtonText = 'OK',
    bool barrierDismissible = false,
  });


  Future<Map<String, Object>> showLoginDialog({
    String title = 'Login',
    String okButtonText = 'OK',
    String cancelButtonText,
    String logInLabel = 'User name',
    String passwordLabel = 'Password',
    String header,
    String footer,
    String Function(String) loginValidator,
    String Function(String) passwordValidator,
    EdgeInsets defaultFieldPadding = const EdgeInsets.only(bottom: 24),
    double labelSpacing = 0,
    TextStyle labelStyle,
    TextStyle fieldStyle,
    VoidCallback onValidationError,
    bool barrierDismissible = false,
  });

  Future<MessageDialogResults> showQueryDialog(
    String message, {
    String title,
    Map<MessageDialogResults, String> buttonDefinitions = const {
      MessageDialogResults.yes: 'Yes',
      MessageDialogResults.no: 'No',
    },
    bool barrierDismissible = false,
  });

  Future<NetworkConfiguration> showNetworkConfigurationDialog({
    String title = 'Connection Settings',
    String message,
    String serverAdressLabel = 'Server Address',
    String portLabel = 'Server Port',
    String sslLabel = 'Use SSL',
    bool showProtocolSelection = true,
    String portFormatErrorMessage = 'Only Numbers',
    String okButtonText = 'Ok',
    String cancelButtonText,
    NetworkConfiguration networkConfiguration = const NetworkConfiguration(),
    bool barrierDismissible = false,
  });

  Future<Map<String, Object>> showFormDialog({
    String title,
    List<FormFieldConfig> fields,
    String okButtonText = 'OK',
    String cancelButtonText = 'Cancel',
    String header,
    String footer,
    EdgeInsets defaultFieldPadding = const EdgeInsets.only(bottom: 24),
    double labelSpacing = 0,
    TextStyle labelStyle,
    TextStyle fieldStyle,
    VoidCallback onValidationError,
    bool barrierDismissible = false,
  });


  /// If you don't want to use the [InteractionConnector] you have to set the
  /// `NavigatorState` of your root navigator with this method.
  void setRootNavigator(NavigatorState navigatorState);

}

class InteractionConnector extends StatefulWidget {
  final Widget child;

  /// Fire and forget async ApplicationInitFunction that will be called as soon as the
  /// Interaction Manager is ready
  final Future Function() appInitFunction;

  /// Will be called before [appInitFunction] pass here your funtion where you register your custom dialogs.
  final void Function(InteractionManager) dialogsInitFunction;

  const InteractionConnector(
      {this.appInitFunction, this.dialogsInitFunction, this.child, Key key})
      : super(key: key);
  @override
  InteractionConnectorState createState() => InteractionConnectorState();
}

