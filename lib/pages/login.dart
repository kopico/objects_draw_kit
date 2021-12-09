import 'package:flutter/material.dart';

import 'package:objects_draw_kit/static_assets/ui_parameters.dart';
import 'package:objects_draw_kit/tools/utils.dart';
import 'package:objects_draw_kit/io/authentication.dart';
import 'package:objects_draw_kit/static_assets/app_widgets.dart';

class LoginPage extends StatefulWidget {
  Authentication authInstance;
  LoginPage(this.authInstance, {Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  List<String> loadingList = ["checkStayLoggedIn"];
  String currentLoad = "Connecting ...";
  bool showAuthMethods = true;
  bool stayLoggedIn = true;
  bool enableLoginEmail = false;
  bool enableLoginPassword = false;
  bool showPassword = false;
  bool enableResetPasswordLink = false;
  bool enableResendEmailVerificationLink = false;
  bool processing = false;
  LoginStatus _loginStatus = LoginStatus.LOGGED_OUT;
  Orientation currentOrientation = Orientation.portrait;

  TextEditingController emailAdd = TextEditingController();
  TextEditingController pwd = TextEditingController();
  FocusNode emailFocus = FocusNode();
  FocusNode pwdFocus = FocusNode();

  @override
  void initState(){
    super.initState();
    // load authentication status
    if(widget.authInstance.fUser == null){
      _checkStayLoggedInStatus();
    }
  }

  @override
  void dispose(){
    emailAdd.dispose();
    pwd.dispose();
    emailFocus.dispose();
    pwdFocus.dispose();
    super.dispose();
  }

  Future<void> _checkStayLoggedInStatus() async {
    print("Checking login status. Checking stay logged in status");
    setState(() {
      currentLoad = "Checking login status ...";
    });
    _loginStatus = await widget.authInstance.checkStayLoggedInStatus(context);
    if (_loginStatus == LoginStatus.LOGGED_IN){
      // In this case, user is logged in on the firebase server and is registered in the app memory as logged in.
      // App can continue to load other data.
      setState(() {
        currentLoad = "Loading data ...";
        processing = true;
      });
      _loadUserData();
    } else {
      // In this case, user is logged out on the firebase server and login authentication with the firebase server is required.
      // The app should display login form for user.
      setState(() {
        currentLoad = "Sign in to continue";
        showAuthMethods = true;
        enableLoginEmail = false;
        enableLoginPassword = false;
      });
    }
    loadingList.remove("checkStayLoggedIn");
  }

  void _loadUserData() async {
    // load user info, load app configs, display configs, task configs and goal configs
    loadingList.clear();
    _checkAndProceedToHome();
    // loadingList.addAll(["userInfo"]);
    // fBaseAuth.User fUser = Provider.of<Authentication>(context, listen: false).fUser!;
    // Provider.of<TimeAccount>(context, listen:false).initializeAccountInfoOnLogin(context, fUser).then((res){
    //   Provider.of<TimeAccount>(context, listen:false)
    //       .updateStayLoggedInStatus(context, stayLoggedIn)
    //       .catchError((e){
    //     print("Unable to update 'stayLoggedin' status to local file. Error: $e");
    //   });
    //   loadingList.remove("userInfo");
    //   loadingList.add("encryption");
    //   Provider.of<CloudIO>(context, listen:false).readKey(context).then((res){
    //     loadingList.remove("encryption");
    //     _checkAndProceedToHome();
    //   }).catchError((e){
    //     print("Error loading encryption. Error: $e");
    //   });
    //   loadingList.add("calendar");
    //   Provider.of<CalendarTasks>(context, listen:false).loadUserTasksFromCloud(context);
    //   loadingList.remove("calendar");
    //   _checkAndProceedToHome();
    // }).catchError((e){
    //   print("Error loading user info or tasks db. Error:$e");
    //   SnackBarMessage.sendMessage("Unable to load user data.", context, clearSnackBar: true);
    //   loadingList.remove("userInfo");
    //   loadingList.remove("tasks");
    //   _checkAndProceedToHome();
    // });
  }

  void _checkAndProceedToHome(){
    if (loadingList.isEmpty){
      setState(() {
        currentLoad = "Log in complete!";
        processing = false;
      });
    }
  }

  // void _reset(){
  //   pwd.clear();
  //   emailAdd.clear();
  //   currentLoad = "";
  //   enableLoginEmail = widget.authInstance.fUser == null;
  //   enableLoginPassword = enableLoginEmail;
  //   enableResetPasswordLink = false;
  //   processing = false;
  // }

  void updateOrientation(){
    currentOrientation = MediaQuery.of(context).orientation;
  }

  void _handleLoginStatus({Map<String, dynamic> userData: const {"status": LoginStatus.LOGIN_FAILED}}) async {
    if(_loginStatus == LoginStatus.LOGIN_SUCCESS_AND_CREATING_ACCOUNT){
      // setState(() {
      //   enableLoginEmail = false;
      //   enableLoginPassword = false;
      //   currentLoad = "Signed in success. Creating new account ...";
      //   emailAdd.clear();
      //   pwd.clear();
      //   enableResetPasswordLink = false;
      //   enableResendEmailVerificationLink = false;
      // });
      // String response = await context
      //     .read<TimeAccount>()
      //     .createNewUser(userData["email"]!, "", context, true, authMethod: AuthenticationMethod.Google, userData: userData);
      // if (response == "Account created via Google Sign In"){
      //   _loginStatus = LoginStatus.LOGIN_SUCCESS;
      //   loadingList.remove("checkStayLoggedIn");
      //   await Provider.of<TimeAccount>(context, listen:false).updateStayLoggedInStatus(context, false);
      //   setState(() {
      //     currentLoad = "Loading data ...";
      //   });
      //   _loadUserData();
      // } else {
      //   setState(() {
      //     currentLoad = response;
      //     processing = false;
      //   });
      // }
    } else if (_loginStatus == LoginStatus.LOGIN_SUCCESS){
      loadingList.remove("checkStayLoggedIn");
      _loadUserData();
      setState(() {
        enableLoginEmail = false;
        enableLoginPassword = false;
        currentLoad = "Signed in success. Loading data ...";
        emailAdd.clear();
        pwd.clear();
        enableResetPasswordLink = false;
        enableResendEmailVerificationLink = false;
      });
    } else if(_loginStatus == LoginStatus.EMAIL_UNVERIFIED){
      setState(() {
        currentLoad = "Verify email address before log in";
        processing = false;
        pwd.clear();
        enableResetPasswordLink = false;
        enableResendEmailVerificationLink = true;
      });
    } else {
      setState(() {
        currentLoad = "Login fail.";
        processing = false;
        pwd.clear();
        enableResetPasswordLink = true;
        enableResendEmailVerificationLink = false;
      });
    }
  }

  Widget buildAnimatedAuthMethods(){
    return AnimatedContainer(
      duration: const Duration(microseconds: 500),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical:10),
      child: Center(
        child: Column(
            children:[
              const SizedBox(
                  height: 15
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      height: 50,
                      width: 90,
                      alignment: Alignment.topCenter,
                      child: Text("Sign in with:", style: Theme.of(context).textTheme.bodyText1)
                  ),
                  const SizedBox(
                    width:20,
                  ),
                  getButton(
                      context, buttonSize, Icons.email, "Email", () async {
                        widget.authInstance.updateAuthenticationMethod(AuthenticationMethod.Email);
                        setState(() {
                          showAuthMethods = false;
                          enableLoginEmail = true;
                          enableLoginPassword = true;
                        });
                  }, iconColor: Colors.white
                  ),
                  SizedBox(width:10),
                  getButton(
                    context, buttonSize, Icons.lock_open, "Google", () async {
                    widget.authInstance.updateAuthenticationMethod(AuthenticationMethod.Google);
                    setState(() {
                      processing = true;
                      currentLoad = "Signing in Google";
                    });
                    Map<String, String> authResult = await widget.authInstance.authenticateGoogle();
                    if(authResult.containsKey("provider_id")){
                      setState(() {
                        currentLoad = "Signing in ${authResult["provider_id"]}";
                      });
                      Map<String, dynamic>? userData = await widget.authInstance.authenticateFirebaseWithGoogleAccount();
                      if(userData != null){
                        _loginStatus = userData['status'];
                        _handleLoginStatus(userData: userData);
                      }
                    } else {
                      print("${authResult["error"]}");
                      setState(() {
                        processing = false;
                        currentLoad = "Unable to sign in. Try again later";
                      });
                    }
                  },
                    iconWidget: Material(
                      shape:CircleBorder(),
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: ExactAssetImage("assets/icons/google_icon.png",)
                            )
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]
        ),
      ),

    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double appBarHeight = 50;
    var fUser = widget.authInstance.fUser;
    bool loggedIn = fUser != null;
    updateOrientation();
    if (loggedIn && !enableLoginEmail){
      enableLoginEmail = false;
      enableLoginPassword = false;
      showAuthMethods = false;
      currentLoad = "Signed in as ${fUser.email}";
    } else if (loggedIn && enableLoginEmail){
      enableLoginEmail = false;
      enableLoginPassword = false;
      showAuthMethods = false;
    } else if (!loggedIn && !enableLoginEmail){
      enableLoginEmail = true;
      enableLoginPassword = true;
      showAuthMethods = true;
      currentLoad = "Sign in to continue";
    }
    double textInputWidth = 220;

    EdgeInsets currentLoadEdgeInsets = const EdgeInsets.symmetric(vertical:20);
    EdgeInsets textInputContainerEdgeInsets = EdgeInsets.zero;
    EdgeInsets textInputTextFieldEdgeInsets = EdgeInsets.fromLTRB(8,5,5,12);

    return Material(
      type: MaterialType.canvas,
      child: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Column(
          children:[
            Container(
              width: screenWidth,
              height: appBarHeight,
              child: AppBar(
                title: Text("Login"),
                leading: MaterialButton(
                  onPressed:(){
                    Navigator.pop(context, {
                      "user": fUser,
                      "login_status": fUser != null ? LoginStatus.LOGIN_SUCCESS : LoginStatus.LOGIN_FAILED,
                    });
                  },
                  color: Colors.orange,
                    elevation: 0.0,
                    hoverColor: Colors.orange,
                    highlightColor: Colors.orange,
                    padding:EdgeInsets.zero,
                  child: Icon(Icons.arrow_back, size:24, color: Colors.white)
                ),
              )
            ),
            Expanded(
              child: Center(
                  child:Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width:130,
                        height:130,
                        decoration: BoxDecoration(
                          border: Border.all(width:1),
                        ),
                      ),
                      Container(
                          padding:currentLoadEdgeInsets,
                          height:textFieldHeight * 2,
                          alignment: Alignment.center,
                          child: Text(currentLoad,
                            style:Theme.of(context).textTheme.bodyText1,
                            textAlign: TextAlign.center,
                          )
                      ),
                      showAuthMethods ? buildAnimatedAuthMethods() : Container(),
                      enableLoginEmail && !showAuthMethods ? Container(
                          width:textInputWidth,
                          height:textFieldHeight,
                          padding: textInputContainerEdgeInsets,
                          child:TextField(
                            decoration: InputDecoration(
                              icon: const Icon(Icons.email, color: Colors.grey),
                              contentPadding: textInputTextFieldEdgeInsets,
                              border: const UnderlineInputBorder(),
                              hintText: "Email",
                            ),
                            style: Theme.of(context).textTheme.bodyText1,
                            controller:emailAdd,
                            focusNode: emailFocus,
                            keyboardType: TextInputType.emailAddress,
                          )
                      ) : Container(),
                      enableLoginPassword && !showAuthMethods ? Container(
                          width: textInputWidth,
                          height:textFieldHeight,
                          padding: textInputContainerEdgeInsets,
                          child:TextField(
                            decoration: InputDecoration(
                              icon: const Icon(Icons.vpn_key, color: Colors.grey),
                              contentPadding: const EdgeInsets.fromLTRB(8,12,5,5),
                              border: const UnderlineInputBorder(),
                              suffixIcon: IconButton(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  onPressed: (){
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  },
                                  icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, size: inlineIconSize)
                              ),
                              hintText: "Password",
                            ),
                            style: Theme.of(context).textTheme.bodyText1,
                            controller:pwd,
                            focusNode: pwdFocus,
                            obscureText: !showPassword,
                            keyboardType: TextInputType.visiblePassword,
                          )
                      ) : Container(),
                      enableLoginEmail && enableLoginPassword && !showAuthMethods ? Container(
                          height: textFieldHeight,
                          width: textInputWidth,
                          padding: textInputContainerEdgeInsets,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                  value: stayLoggedIn,
                                  onChanged: (val){
                                    setState(() {
                                      stayLoggedIn = !stayLoggedIn;
                                    });
                                  }),
                              Text("Stay logged in", style: Theme.of(context).textTheme.bodyText1,),
                            ],
                          )
                      ) : Container(),
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: processing ? const CircularProgressIndicator(semanticsLabel: "Processing ... ",) : Container(),
                      ),
                      enableLoginEmail && enableLoginPassword && !showAuthMethods ? Padding(
                        padding: const EdgeInsets.symmetric(vertical:5.0, horizontal: 0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: getButton(
                                    context,
                                    buttonSize,
                                    Icons.keyboard_return,
                                    "Other", (){
                                  setState(() {
                                    showAuthMethods = true;
                                    enableLoginEmail = false;
                                    enableLoginPassword = false;
                                  },);
                                },iconColor: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal:16.0),
                                child: getButton(
                                    context,
                                    buttonSize,
                                    Icons.supervisor_account,
                                    "New Acc", () async {
                                  setState(() {
                                    currentLoad = "Creating new account ...";
                                    processing = true;
                                    pwdFocus.unfocus();
                                    emailFocus.unfocus();
                                  });
                                  String response = await widget.authInstance.createNewUser(emailAdd.text, pwd.text, context, stayLoggedIn);
                                  setState(() {
                                    currentLoad = response;
                                    emailAdd.clear();
                                    pwd.clear();
                                    processing = false;
                                  });
                                },iconColor: Colors.white),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal:16.0),
                                child: getButton(
                                    context,
                                    buttonSize,
                                    Icons.lock_open_outlined,
                                    "Sign In", () async {
                                      setState(() {
                                        currentLoad = "Signing in ...";
                                        processing = true;
                                        pwdFocus.unfocus();
                                        emailFocus.unfocus();
                                      });
                                      _loginStatus = await widget.authInstance.authenticateEmail(emailAdd.text, pwd.text);
                                      _handleLoginStatus();
                                },iconColor: Colors.white),
                              ),
                              enableResetPasswordLink ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal:16.0),
                                child: getButton(
                                    context,
                                    buttonSize,
                                    Icons.replay_circle_filled,
                                    "Forgot password", () async {
                                  setState(() {
                                    currentLoad = "Sending password reset link ...";
                                    processing = true;
                                    pwdFocus.unfocus();
                                    emailFocus.unfocus();
                                  });
                                  String outcome = await widget.authInstance.forgotPasswordSequence(emailAdd.text, context);
                                  setState(() {
                                    currentLoad = outcome;
                                    processing = false;
                                  });
                                  if(outcome == "Password reset link sent."){
                                    setState(() {
                                      enableResetPasswordLink = false;
                                    });
                                  }
                                },iconColor: Colors.white),
                              ) : Container(),
                              enableResendEmailVerificationLink ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal:16.0),
                                child: getButton(
                                    context,
                                    buttonSize,
                                    Icons.double_arrow,
                                    "Resend verification", () async {
                                  widget.authInstance.resendEmailVerificationLink(context);
                                },iconColor: Colors.white),
                              ) : Container(),
                            ]
                        ),
                      ) : Container(),
                      loggedIn ? Padding(
                        padding: const EdgeInsets.symmetric(vertical:20.0, horizontal: 0),
                        child: getButton(
                            context,
                            buttonSize,
                            Icons.keyboard_return,
                            "Return", (){
                          Navigator.pop(context, {
                            "user": fUser,
                            "login_status": fUser != null ? LoginStatus.LOGIN_SUCCESS : LoginStatus.LOGIN_FAILED,
                          });
                        },iconColor: Colors.white),
                      ) : Container(),
                    ],
                  )
              ),
            )
          ]
        )
      )
    );
  }
}
