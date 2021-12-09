import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fBaseAuth;
import 'package:google_sign_in/google_sign_in.dart';

import 'dart:async';

import 'package:objects_draw_kit/tools/utils.dart';
import 'package:objects_draw_kit/tools/error_handling.dart';


enum AuthenticationMethod{Email, Google, Microsoft, Apple, Facebook}

class Authentication{

  // Use local auth login status as the main basis of login status. This is so that user can login even if there is no internet connection.
  // Cloud authentication will be when user choose to sync user data onto the cloud.
  // Log firebase account out by default as there is little need to upload data to the cloud when there is a local database.

  fBaseAuth.User? _user;
  // _user to track net authentication status. Only non-null when localloginStatus is LOGGED_IN.

  fBaseAuth.User? get fUser => _user;

  Authentication({fBaseAuth.User? user}){
    _user = user;
  }

  AuthenticationMethod? _currentAuthenticationMethod;

  bool? _stayLoggedIn;
  // use to track local authentication status

  bool? get stayLoggedIn => _stayLoggedIn;

  fBaseAuth.FirebaseAuth auth = fBaseAuth.FirebaseAuth.instance;

  fBaseAuth.UserCredential? _userCredential;

  fBaseAuth.UserCredential? get credential => _userCredential;

  AuthenticationMethod? get authMethod => _currentAuthenticationMethod;

  fBaseAuth.AuthCredential? googleCredential;

  GoogleSignIn googleSignIn = GoogleSignIn(clientId: "544267561039-r32j4o27bopr3do678ns37sim7cmpkpo.apps.googleusercontent.com",);

  void updateUser(fBaseAuth.User? user){
    _user = user;
    print("User in authentication class updated to ${user?.uid}");
  }

  fBaseAuth.FirebaseAuth getFirebaseAuth(){
    return auth;
  }

  set setCredential(fBaseAuth.UserCredential? credential){
    _userCredential = credential;
  }

  void updateAuthenticationMethod(AuthenticationMethod method){
    _currentAuthenticationMethod = method;
  }

  Future<void> reloadUser(BuildContext context) async {
    if(auth.currentUser != null){
      await auth.currentUser!.reload().then((res){
        _user = auth.currentUser;
      });
    }
  }

  Future<LoginStatus> checkStayLoggedInStatus(BuildContext context) async {
    // This function is called when user loads the app.
    // The intent is to speed up login process if the user selected "Stay logged in" option when signing in.
    // This function will check local file if the previous logged in user has selected "stayLoggedIn" option.
    // If previous logged in user selected stayLoggedIn, this function will check with firebase authentication for the user.
    // If the firebase authentication does not have a logged in user, return status as logged out.
    // If the firebase authentication has a logged in user, register this user here.
    // If the previous logged in user did not select stayLoggedIn, return status as logged out.
    return _user != null ? LoginStatus.LOGGED_IN : LoginStatus.LOGGED_OUT;
    // String result = await appIO.readLocalAuth();
    // if(result != "FILE_READ_UNSUCCESSFUL"){
    //   List<String> userString = result.split(', ');
    //   _stayLoggedIn = userString[1] == "true";
    //   print("Stay logged in status: $_stayLoggedIn");
    //   if (_stayLoggedIn!){
    //     // The user might have signed in using another device, resulting in the current device logged out on the server. Synchronise log in status with the firebase server.
    //     // Firebase authentication does not log out user when logged in on multiple devices. To implement a stronger security, developers have to manually track login status.
    //     if (auth.currentUser == null){
    //       // The receiving function should process login sequence.
    //       _user = null;
    //       return LoginStatus.LOGGED_OUT;
    //     } else if ( auth.currentUser!.uid != userString[0]){
    //       // The local auth file registered stayLoggedIn of a user different from the firebase authentication server registered user for this device. Log out and relogin.
    //       _user = null;
    //       return LoginStatus.LOGGED_OUT;
    //     } else{
    //       // The receiving function can proceed to carry out other loading processes.
    //       _user = auth.currentUser;
    //       return LoginStatus.LOGGED_IN;
    //     }
    //   } else {
    //     // In this case, user should have logged out to reach this function.
    //     if (auth.currentUser != null){
    //       auth.signOut();
    //     }
    //     _user = null;
    //     return LoginStatus.LOGGED_OUT;
    //   }
    //   //
    // } else {
    //   print("Error reading local auth file.");
    //   // Treat this case as logged out and assume that user did not selected stay logged in.
    //   // This is the initial state when the app is first installed.
    //   // User will log in after creating their first account.
    //   if (auth.currentUser != null){
    //     auth.signOut();
    //   }
    //   updateUser(null);
    //   return LoginStatus.LOGGED_OUT;
    // }
  }

  Future<void> updateStayLoggedIn (bool val) async {
    _stayLoggedIn = val;
  }

  // void initializeLocalAccountInfo(fBaseAuth.User fUser, BuildContext context){
  //   Provider.of<TimeAccount>(context, listen:false).initializeAccountInfoOnLogin(context, fUser);
  // }

  Future<LoginStatus> authenticateEmail (String email, String password) async {
    // Authenticate will authenticate with network for login, and register local logged in status. App will log out of network login state thereafter.
    // String sec = "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";
    LoginStatus loginOutcome = await auth
        .signInWithEmailAndPassword(email: email, password: password)
        .then((userCredential) {
      fBaseAuth.User fUser = userCredential.user!;
      if(fUser.emailVerified){
        _userCredential = userCredential;
        updateUser(fUser);
        return LoginStatus.LOGIN_SUCCESS;
      } else {
        updateUser(null);
        return LoginStatus.EMAIL_UNVERIFIED;
      }
    }).catchError((error) {
      updateUser(null);
      return LoginStatus.LOGIN_FAILED;
    });
    return loginOutcome;
  }

  Future<Map<String, String>> authenticateGoogle () async {
    // authenticateGoogle will authenticate with Google for a googleSignInCredential
    // LoginStatus loginOutcome;
    String? errorString;

    fBaseAuth.GoogleAuthProvider provider = fBaseAuth.GoogleAuthProvider();

    fBaseAuth.UserCredential result = await auth.signInWithPopup(provider);

    fBaseAuth.AuthCredential? credential = result.credential;

    if(credential != null){
      googleCredential = credential;
      return {"provider_id": googleCredential!.providerId};
    } else {
      return {"error": errorString ?? "Unhandled error"};
    }
  }

  Future<Map<String, dynamic>> authenticateFirebaseWithGoogleAccount() async {
    // Obtain the auth details from the request
    if (googleCredential != null){
      return await fBaseAuth.FirebaseAuth.instance
          .signInWithCredential(googleCredential!)
          .then((userCredential) async {
        fBaseAuth.User fUser = userCredential.user!;
        _userCredential = userCredential;
        updateUser(fUser);
        return {
          "status": LoginStatus.LOGIN_SUCCESS,
          "user_id": fUser.uid,
          "email": fUser.email,
          "firebase_account": fUser,
          "authentication_method": AuthenticationMethod.Google,
        };
        // if(await checkTTDAAccountExistence(fUser.uid)){
        //
        // } else {
        //   return {
        //     "status": LoginStatus.LOGIN_SUCCESS_AND_CREATING_ACCOUNT,
        //     "user_id": fUser.uid,
        //     "email": fUser.email,
        //     "firebase_account": fUser,
        //     "authentication_method": AuthenticationMethod.Google,
        //   };
        // };
      }).catchError((error) {
        updateUser(null);
        return {"status": LoginStatus.LOGIN_FAILED};
      });
    } else {
      return {"status": LoginStatus.LOGIN_FAILED};
    }
  }

  Future<LoginStatus> reauthenticate (String password) async {
    switch (_currentAuthenticationMethod){
      case AuthenticationMethod.Email:
        return await authenticateEmail(_user!.email!, password);
      case AuthenticationMethod.Google:
        var res = await authenticateFirebaseWithGoogleAccount();
        return [LoginStatus.LOGIN_SUCCESS, LoginStatus.LOGIN_SUCCESS_AND_CREATING_ACCOUNT].contains(res["status"]) ? LoginStatus.REAUTHENTICATE_SUCCESS : LoginStatus.REAUTHENTICATE_FAILED;
      // case AuthenticationMethod.Apple:
      //   return await authenticateApple();
      // case AuthenticationMethod.Facebook:
      //   return await authenticateFaceBook();
      case AuthenticationMethod.Microsoft:
        throw Exception("Unimplemented");
      default:
        return LoginStatus.REAUTHENTICATE_SUCCESS;
    }
  }

  // Future<bool> checkTTDAAccountExistence(String uid) async {
  //   fBaseCloud.FirebaseFirestore db = fBaseCloud.FirebaseFirestore.instance;
  //   print("Checking existence of account $uid");
  //   return await db.collection("all_users").where("user_id", isEqualTo: uid).limit(1).get().then((queryResult){
  //     return queryResult.docs.isNotEmpty;
  //   });
  // }

  Future<String> createNewUser(String email, String password, BuildContext context, bool stayLoggedIn, {AuthenticationMethod authMethod: AuthenticationMethod.Email, Map<String, dynamic>? userData}) async {
    if(authMethod == AuthenticationMethod.Email){
      if (email.isEmpty) {
        return "Email cannot be blank.";
      } else if (password.isEmpty) {
        return "Password cannot be blank.";
      } else if (notValidPassword(password)) {
        return "Password must contain at least 8 alphanumeric"
            "characters, at least 1 capital letter, 1 small letter and 1 number";
      } else {
        return await getFirebaseAuth()
            .createUserWithEmailAndPassword(
            email: email,
            password: password)
            .then((userCredential) async
        {
          fBaseAuth.User fUser = userCredential.user!;
          fUser.sendEmailVerification();
          return "Account created. Login to continue.";
        }).catchError((e){
          String errorString = "";
          if ("$e".contains("email-already-in-use")){
            errorString = "Email already in use";
          }
          if ("$e".contains("invalid-email")){
            errorString = "Invalid email";
          }
          if ("$e".contains("operation-not-allowed")){
            errorString = "Operation not allowed";
          }
          if ("$e".contains("weak-password")){
            errorString = "Weak password. Use at least 8 alphanumeric "
                "characters, 1 capital letter, 1 small letter and 1 number";
          }
          print("Error creating account. Error: $e");
          return "Error creating account. $errorString";
        });
      }
    } else if (authMethod == AuthenticationMethod.Google){
      return "Account created via Google Sign In";
    } else {
      throw UnimplementedError("Authentication method not implemented");
    }
  }

  Future<String> forgotPasswordSequence(String email, BuildContext context) async {
    if (email == "") {
      return "Invalid email. Please input login email.";
    } else {
      return await getFirebaseAuth()
          .sendPasswordResetEmail(email: email)
          .then((res) {
        return "Password reset link sent.";
      }).catchError((error) {
        return "Password reset link sending failed. Please verify login email";
      });
    }
  }

  void resendEmailVerificationLink(BuildContext context) {
    var fUser = getFirebaseAuth().currentUser;
    if(fUser != null){
      fUser.sendEmailVerification().then((res) {
        showErrorMessage(context, "Verification email sent!", []);
      }).catchError((error) {
        print("$error");
        showErrorMessage(context, "Error sending verification email. Try again later.", []);
      });
    } else {
      showErrorMessage(context, "Error sending verification email. Try again later.", []);
    }
  }

  Future<void> signOutTimeApp(BuildContext context) async {
    // This will sign out of firebase server and register local _user variable to null
    if (auth.currentUser != null){
      await auth.signOut();
      // Provider.of<TimeAccount>(context, listen: false).signOutTimeAccount();
      switch (_currentAuthenticationMethod){
        case AuthenticationMethod.Google:
          googleSignIn.signOut();
          break;
        case AuthenticationMethod.Apple:
          throw Exception("Unimplemented");
        case AuthenticationMethod.Facebook:
          throw Exception("Unimplemented");
        case AuthenticationMethod.Microsoft:
          throw Exception("Unimplemented");
        default:
          if(googleSignIn != null){
            googleSignIn.signOut();
          }
          break;
      }
    }
    if(googleCredential != null){
      googleSignIn.signOut();
      googleCredential = null;
    }
    updateUser(null);
    // context.read<TimeAccount>().signOutTimeAccount();
  }
}