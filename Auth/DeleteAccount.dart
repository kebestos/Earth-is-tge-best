import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../HomePageState.dart';
import 'AuthGate.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final Color _mainColor = const Color.fromARGB(255, 47, 85, 151);

  final CollectionReference _collectionUsers =
      FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Map<Buttons, OAuthSignIn> authButtons;

  bool isLoading = false;
  String error = '';

  Future<void> deleteAccount() async {
    AuthCredential authCredential = EmailAuthProvider.credential(
      email: emailController.text,
      password: passwordController.text,
    );
    await _auth.currentUser?.reauthenticateWithCredential(authCredential);
    await _collectionUsers.doc(_auth.currentUser?.uid).delete();
    await _auth.currentUser?.delete();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromARGB(255, 47, 85, 151),
      statusBarIconBrightness: Brightness.light,
    ));
    if ((!kIsWeb && Platform.isMacOS) || Platform.isIOS) {
      authButtons = {
        Buttons.Apple: () => _handleMultiFactorException(
              _deleteAppleAcount,
            ),
        // Buttons.Google: () => _handleMultiFactorException(
        //       _deleteGoogleAccount,
        //     ),
      };
    } else {
      authButtons = {
        // Buttons.Google: () => _handleMultiFactorException(
        //       _deleteGoogleAccount,
        //     ),
      };
    }
  }

  Future<void> _deleteGoogleAccount() async {
    // Trigger the authentication flow
    final googleUser = GoogleSignIn().currentUser;
    // Obtain the auth details from the request
    final googleAuth = await googleUser?.authentication;

    if (googleAuth != null) {
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Once signed in, return the UserCredential
      await _auth.currentUser?.reauthenticateWithCredential(credential);
      await _collectionUsers.doc(_auth.currentUser?.uid).delete();
      await _auth.currentUser?.delete();
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const MyHomePage(selectedIndex: 2)));
  }

  Future<void> _deleteAppleAcount() async {
    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('fullName');

    if (kIsWeb) {
      // Once signed in, return the UserCredential
      await _auth.signInWithPopup(appleProvider);
    } else {
      await _auth.currentUser?.reauthenticateWithProvider(appleProvider);
      await _collectionUsers.doc(_auth.currentUser?.uid).delete();
      await _auth.currentUser?.delete();
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const MyHomePage(selectedIndex: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: FocusScope.of(context).unfocus,
        child: Scaffold(
            backgroundColor: _mainColor,
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SafeArea(
                        child: Stack(children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                                "assets/style/logo/logo_earth_is_the_best.png",
                                width: 100),
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
                                )),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () async => {
                                  await deleteAccount(),
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const MyHomePage(
                                                  selectedIndex: 2))),
                                },
                                child: Text("Delete account"),
                              ),
                            ),
                            TextButton(
                              onPressed: _resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                            const Padding(
                                padding: EdgeInsets.only(bottom: 16.0)),
                            const Text("re-authentication and delete"),
                            ...authButtons.keys
                                .map(
                                  (button) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
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
                          ],
                        ),
                      )
                    ]))))));
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

  void setIsLoading() {
    setState(() {
      isLoading = !isLoading;
    });
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
}

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
