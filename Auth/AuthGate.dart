import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:earth_is_the_best/HomePageState.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

typedef OAuthSignIn = void Function();

final FirebaseAuth _auth = FirebaseAuth.instance;

/// Helper class to show a snackbar using the passed context.
class ScaffoldSnackbar {
  // ignore: public_member_api_docs
  ScaffoldSnackbar(this._context);

  /// The scaffold of current context.
  factory ScaffoldSnackbar.of(BuildContext context) {
    return ScaffoldSnackbar(context);
  }

  final BuildContext _context;

  /// Helper method to show a SnackBar.
  void show(String message) {
    ScaffoldMessenger.of(_context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

/// The mode of the current auth session, either [AuthMode.login] or [AuthMode.register].
// ignore: public_member_api_docs
enum AuthMode { login, register, phone }

extension on AuthMode {
  String get label => this == AuthMode.login
      ? 'Sign in'
      : this == AuthMode.phone
          ? 'Sign in'
          : 'Register';
}

/// Entrypoint example for various sign-in flows with Firebase.
class AuthGate extends StatefulWidget {
  // ignore: public_member_api_docs
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String error = '';
  String verificationId = '';

  AuthMode mode = AuthMode.login;

  bool isLoading = false;

  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('Users');

  void setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  late Map<Buttons, OAuthSignIn> authButtons;

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 47, 85, 151),
      statusBarIconBrightness: Brightness.light,
    ));
    if ((!kIsWeb && Platform.isMacOS) || Platform.isIOS) {
      authButtons = {
        // Buttons.Google: () => _handleMultiFactorException(
        //       _signInWithGoogle,
        //     ),
        Buttons.Apple: () => _handleMultiFactorException(
              _signInWithApple,
            ),
        // Buttons.Facebook: () => _handleMultiFactorException(
        //   _signInWithFacebook,
        // ),
      };
    } else {
      authButtons = {
        // Buttons.Apple: () => _handleMultiFactorException(
        //   _signInWithApple,
        // ),
        Buttons.Google: () => _handleMultiFactorException(
              _signInWithGoogle,
            ),
        // Buttons.Facebook: () => _handleMultiFactorException(
        //   _signInWithFacebook,
        // ),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Scaffold(
        backgroundColor: _mainColor,
        body: Center(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SafeArea(
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: error.isNotEmpty,
                            child: MaterialBanner(
                              backgroundColor: Theme.of(context).errorColor,
                              content: Text(error),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      error = '';
                                    });
                                  },
                                  child: const Text(
                                    'dismiss',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )
                              ],
                              contentTextStyle:
                                  const TextStyle(color: Colors.white),
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (mode != AuthMode.phone)
                            Column(
                              children: [
                                // Image.asset(
                                //     "assets/style/logo/logo_earth_is_the_best.png",
                                //     width: 100),
                                // const SizedBox(height: 20),
                                if (mode == AuthMode.register)
                                  Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(5)),
                                      ),
                                      child: TextFormField(
                                        controller: userNameController,
                                        decoration: const InputDecoration(
                                          hintText: 'Username',
                                          border: OutlineInputBorder(),
                                        ),
                                        validator: (value) =>
                                            value != null && value.isNotEmpty
                                                ? null
                                                : 'Required',
                                      )),
                                const SizedBox(height: 20),
                                Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: TextFormField(
                                      controller: emailController,
                                      decoration: const InputDecoration(
                                        hintText: 'Email',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                          value != null && value.isNotEmpty
                                              ? null
                                              : 'Required',
                                    )),
                                const SizedBox(height: 20),
                                Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: TextFormField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        hintText: 'Password',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                          value != null && value.isNotEmpty
                                              ? null
                                              : 'Required',
                                    ))
                              ],
                            ),
                          if (mode == AuthMode.phone)
                            TextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                hintText: '+12345678910',
                                labelText: 'Phone number',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value != null && value.isNotEmpty
                                      ? null
                                      : 'Required',
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _handleMultiFactorException(
                                _emailAndPassword,
                              ),
                              child: Text(mode.label),
                            ),
                          ),
                          TextButton(
                            onPressed: _resetPassword,
                            child: const Text('Forgot password?'),
                          ),
                          ...authButtons.keys
                              .map(
                                (button) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: SignInButton(
                                        button,
                                        onPressed: authButtons[button]!,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          // SizedBox(
                          //   width: double.infinity,
                          //   height: 50,
                          //   child: OutlinedButton(
                          //     onPressed: isLoading
                          //         ? null
                          //         : () {
                          //       if (mode != AuthMode.phone) {
                          //         setState(() {
                          //           mode = AuthMode.phone;
                          //         });
                          //       } else {
                          //         setState(() {
                          //           mode = AuthMode.login;
                          //         });
                          //       }
                          //     },
                          //     child: isLoading
                          //         ? const CircularProgressIndicator.adaptive()
                          //         : Text(
                          //       mode != AuthMode.phone
                          //           ? 'Sign in with Phone Number'
                          //           : 'Sign in with Email and Password',
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(height: 20),
                          if (mode != AuthMode.phone)
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyText1,
                                children: [
                                  TextSpan(
                                    text: mode == AuthMode.login
                                        ? "Don't have an account? "
                                        : 'You have an account? ',
                                  ),
                                  TextSpan(
                                    text: mode == AuthMode.login
                                        ? 'Register now'
                                        : 'Click to login',
                                    style: const TextStyle(color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        setState(() {
                                          mode = mode == AuthMode.login
                                              ? AuthMode.register
                                              : AuthMode.login;
                                        });
                                      },
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          // RichText(
                          //   text: TextSpan(
                          //     style: Theme.of(context).textTheme.bodyText1,
                          //     children: [
                          //       const TextSpan(text: 'Or '),
                          //       TextSpan(
                          //         text: 'continue as guest',
                          //         style: const TextStyle(color: Colors.blue),
                          //         recognizer: TapGestureRecognizer()
                          //           ..onTap = _anonymousAuth,
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future _resetPassword() async {
    String? email;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Send'),
            ),
          ],
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email'),
              const SizedBox(height: 20),
              TextFormField(
                onChanged: (value) {
                  email = value;
                },
              ),
            ],
          ),
        );
      },
    );

    if (email != null) {
      try {
        await _auth.sendPasswordResetEmail(email: email!);
        ScaffoldSnackbar.of(context).show('Password reset email is sent');
      } catch (e) {
        ScaffoldSnackbar.of(context).show('Error resetting');
      }
    }
  }

  Future<void> _anonymousAuth() async {
    setIsLoading();

    try {
      await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    } catch (e) {
      setState(() {
        error = '$e';
      });
    } finally {
      setIsLoading();
    }
  }

  Future<void> _handleMultiFactorException(
    Future<void> Function() authFunction,
  ) async {
    setIsLoading();
    try {
      await authFunction();
    } on FirebaseAuthMultiFactorException catch (e) {
      setState(() {
        error = '${e.message}';
      });
      final firstHint = e.resolver.hints.first;
      if (firstHint is! PhoneMultiFactorInfo) {
        return;
      }
      final auth = FirebaseAuth.instance;
      await auth.verifyPhoneNumber(
        multiFactorSession: e.resolver.session,
        multiFactorInfo: firstHint,
        verificationCompleted: (_) {},
        verificationFailed: print,
        codeSent: (String verificationId, int? resendToken) async {
          final smsCode = await getSmsCodeFromUser(context);

          if (smsCode != null) {
            // Create a PhoneAuthCredential with the code
            final credential = PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: smsCode,
            );

            try {
              await e.resolver.resolveSignIn(
                PhoneMultiFactorGenerator.getAssertion(
                  credential,
                ),
              );
            } on FirebaseAuthException catch (e) {
              print(e.message);
            }
          }
        },
        codeAutoRetrievalTimeout: print,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = '${e.message}';
      });
    } catch (e) {
      setState(() {
        error = '$e';
      });
    } finally {
      setIsLoading();
    }
  }

  Future<void> _emailAndPassword() async {
    if (formKey.currentState?.validate() ?? false) {
      setIsLoading();
      if (mode == AuthMode.login) {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      } else if (mode == AuthMode.register) {
        await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        await _collectionRef
            .doc(_auth.currentUser?.uid)
            .set({
              'userName': userNameController.text,
              'photoUrl':
                  "https://cdn.iconscout.com/icon/free/png-256/account-avatar-profile-human-man-user-30448.png",
              'scoreEUR': 0,
              'scoreAFR': 0,
              'scoreAM': 0,
              'scoreASIE': 0,
              'scoreOCE': 0,
            })
            .then((value) => print("User Added"))
            .catchError((error) => print("Failed to add user: $error"));

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MyHomePage(selectedIndex: 1)));
      } else {
        await _phoneAuth();
      }
    }
  }

  Future<void> _phoneAuth() async {
    if (mode != AuthMode.phone) {
      setState(() {
        mode = AuthMode.phone;
      });
    } else {
      if (kIsWeb) {
        final confirmationResult =
            await _auth.signInWithPhoneNumber(phoneController.text);
        final smsCode = await getSmsCodeFromUser(context);

        if (smsCode != null) {
          await confirmationResult.confirm(smsCode);
        }
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneController.text,
          verificationCompleted: (_) {},
          verificationFailed: (e) {
            setState(() {
              error = '${e.message}';
            });
          },
          codeSent: (String verificationId, int? resendToken) async {
            final smsCode = await getSmsCodeFromUser(context);

            if (smsCode != null) {
              // Create a PhoneAuthCredential with the code
              final credential = PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: smsCode,
              );

              try {
                // Sign the user in (or link) with the credential
                await _auth.signInWithCredential(credential);
              } on FirebaseAuthException catch (e) {
                setState(() {
                  error = e.message ?? '';
                });
              }
            }
          },
          codeAutoRetrievalTimeout: (e) {
            setState(() {
              error = e;
            });
          },
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    // Trigger the authentication flow
    final googleUser = await GoogleSignIn().signIn();
    // Obtain the auth details from the request
    final googleAuth = await googleUser?.authentication;

    if (googleAuth != null) {
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Once signed in, return the UserCredential
      await _auth.signInWithCredential(credential).then((value) => {
            _collectionRef.doc(_auth.currentUser?.uid).get().then((value) => {
                  if (!value.exists)
                    {
                      _collectionRef
                          .doc(_auth.currentUser?.uid)
                          .set({
                            'userName': googleUser?.displayName,
                            'photoUrl': googleUser?.photoUrl,
                            'scoreEUR': 0,
                            'scoreAFR': 0,
                            'scoreAM': 0,
                            'scoreASIE': 0,
                            'scoreOCE': 0,
                          })
                          .then((value) => print("User Added"))
                          .catchError(
                              (error) => print("Failed to add user: $error"))
                    }
                })
          });

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MyHomePage(selectedIndex: 1)));
    }
  }

  // Future<void> _signInWithFacebook() async {
  //   // Trigger the authentication flow
  //   final LoginResult loginResult = await FacebookAuth.instance.login();
  //
  //   // Obtain the auth details from the request
  //   final OAuthCredential facebookAuthCredential = FacebookAuthProvider.credential(loginResult.accessToken.token);
  //
  //   // Once signed in, return the UserCredential
  //   _auth.signInWithCredential(facebookAuthCredential);
  //   }

  Future<void> _signInWithTwitter() async {
    TwitterAuthProvider twitterProvider = TwitterAuthProvider();

    if (kIsWeb) {
      await _auth.signInWithPopup(twitterProvider);
    } else {
      await _auth.signInWithProvider(twitterProvider);
    }
  }

  Future<void> _signInWithApple() async {
    // final appleProvider = AppleAuthProvider();
    // appleProvider.addScope('email');
    // appleProvider.addScope('fullName');
    // User? user;

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oAuthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
    );

    await _auth.signInWithCredential(oAuthCredential);

    if (kIsWeb) {
      // Once signed in, return the UserCredential
      await _auth.signInWithCredential(oAuthCredential);
    } else {
      await _auth
          .signInWithCredential(oAuthCredential)
          .then((result) => {
                // The signed-in user info.
                _collectionRef
                    .doc(_auth.currentUser?.uid)
                    .get()
                    .then((value) => {
                          if (!value.exists)
                            {
                              _collectionRef
                                  .doc(_auth.currentUser?.uid)
                                  .set({
                                    'userName': appleCredential.givenName,
                                    'photoUrl':
                                        "https://cdn.iconscout.com/icon/free/png-256/account-avatar-profile-human-man-user-30448.png",
                                    'scoreEUR': 0,
                                    'scoreAFR': 0,
                                    'scoreAM': 0,
                                    'scoreASIE': 0,
                                    'scoreOCE': 0,
                                  })
                                  .then((value) => print("User Added"))
                                  .catchError((error) =>
                                      print("Failed to add user: $error"))
                            }
                        })
              })
          .catchError((error) => print("Failed to auth with apple : $error"));

      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MyHomePage(selectedIndex: 1)));
    }
  }

  Future<void> _signInWithYahoo() async {
    final yahooProvider = YahooAuthProvider();

    if (kIsWeb) {
      // Once signed in, return the UserCredential
      await _auth.signInWithPopup(yahooProvider);
    } else {
      await _auth.signInWithProvider(yahooProvider);
    }
  }

  Future<void> _signInWithGitHub() async {
    final githubProvider = GithubAuthProvider();

    if (kIsWeb) {
      await _auth.signInWithPopup(githubProvider);
    } else {
      await _auth.signInWithProvider(githubProvider);
    }
  }

  Future<void> _signInWithMicrosoft() async {
    final microsoftProvider = MicrosoftAuthProvider();

    if (kIsWeb) {
      await _auth.signInWithPopup(microsoftProvider);
    } else {
      await _auth.signInWithProvider(microsoftProvider);
    }
  }
}

Future<String?> getSmsCodeFromUser(BuildContext context) async {
  String? smsCode;

  // Update the UI - wait for the user to enter the SMS code
  await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('SMS code:'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Sign in'),
          ),
          OutlinedButton(
            onPressed: () {
              smsCode = null;
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
        content: Container(
          padding: const EdgeInsets.all(20),
          child: TextField(
            onChanged: (value) {
              smsCode = value;
            },
            textAlign: TextAlign.center,
            autofocus: true,
          ),
        ),
      );
    },
  );

  return smsCode;
}
