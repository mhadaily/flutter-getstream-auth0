import 'package:flutter/material.dart';
import 'package:mjcoffee/screens/menu.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mjcoffee/services/auth_service.dart';
import 'package:mjcoffee/services/chat_service.dart';
import 'package:mjcoffee/services/coffee_router.dart';
import 'package:mjcoffee/widgets/button.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = 'homeScreen';
  static Route<HomeScreen> route() {
    return MaterialPageRoute<HomeScreen>(
      settings: RouteSettings(name: routeName),
      builder: (BuildContext context) => HomeScreen(),
    );
  }

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final loginScaffoldKey = GlobalKey<ScaffoldState>();

  bool isBusy = false;
  bool isLoggedIn = false;
  String errorMessage = '';
  String? name;
  String? picture;

  @override
  void initState() {
    initAction();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Image.asset(
              "assets/logo.png",
              height: 150,
              width: 150,
            ),
            SvgPicture.asset(
              "assets/hangout.svg",
              height: MediaQuery.of(context).size.height / 3,
              width: MediaQuery.of(context).size.width,
              semanticsLabel: 'MJ Coffee',
              fit: BoxFit.fitWidth,
            ),
            Text(
              "Get the best coffee!",
              style: Theme.of(context).textTheme.headline2,
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isBusy)
                  CircularProgressIndicator()
                else if (!isLoggedIn)
                  CommonButton(
                    onPressed: loginAction,
                    text: 'Sign In / Sign Up',
                  )
                else
                  Text('Welcome $name'),
              ],
            ),
            if (errorMessage.isNotEmpty) Text(errorMessage),
          ],
        ),
      ),
    );
  }

  setSuccessAuthState() {
    setState(() {
      isBusy = false;
      isLoggedIn = true;
      name = AuthService.instance.idToken?.name;
      picture = AuthService.instance.profile?.picture;
    });

    ChatService.instance.connectUser(AuthService.instance.profile);
    CoffeeRouter.instance.push(MenuScreen.route());
  }

  setLoadingState() {
    setState(() {
      isBusy = true;
      errorMessage = '';
    });
  }

  Future<void> loginAction() async {
    setLoadingState();
    final message = await AuthService.instance.login();
    if (message == 'Success') {
      setSuccessAuthState();
    } else {
      setState(() {
        isBusy = false;
        errorMessage = message;
      });
    }
  }

  initAction() async {
    setLoadingState();
    final bool isAuth = await AuthService.instance.init();
    if (isAuth) {
      setSuccessAuthState();
    } else {
      setState(() {
        isBusy = false;
      });
    }
  }
}
