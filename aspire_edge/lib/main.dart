import 'package:aspire_edge/AdminScreens/Admin.dart';
import 'package:aspire_edge/AdminScreens/AdminHomePage.dart';
import 'package:aspire_edge/AdminScreens/ShowAdminCareerPage.dart';
import 'package:aspire_edge/AdminScreens/admin_careers_page.dart';
import 'package:aspire_edge/AdminScreens/admin_quizzes_page.dart';
import 'package:aspire_edge/AdminScreens/admin_resources_page.dart';
import 'package:aspire_edge/AdminScreens/admin_resources_show.dart';
import 'package:aspire_edge/UserScreens/CVTips.dart';
import 'package:aspire_edge/UserScreens/ChatPage.dart';
import 'package:aspire_edge/UserScreens/FeedBack.dart';
import 'package:aspire_edge/UserScreens/GetStarted.dart';
import 'package:aspire_edge/UserScreens/Index.dart';
import 'package:aspire_edge/UserScreens/InterviewGuide.dart';
import 'package:aspire_edge/UserScreens/Login.dart';
import 'package:aspire_edge/UserScreens/MainHome.dart';
import 'package:aspire_edge/UserScreens/Notifi.dart';
import 'package:aspire_edge/UserScreens/Quiz.dart';
import 'package:aspire_edge/UserScreens/SignUp.dart';
import 'package:aspire_edge/UserScreens/Splashscreen.dart';
import 'package:aspire_edge/UserScreens/TestimonialPage.dart';
import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:aspire_edge/UserScreens/UserProfile.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main()async {
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aspire Edge',
     
       home: HomePage (),
                  routes: {
        '/GetStarted': (context) => const GetStarted(),
        '/SignUp': (context) => const SignUp(),
        '/Login': (context) => const Login(),
        '/mainhome': (context) => const MainHome(),
        '/Admin': (context) => const DashboardPage(),
        '/UserProfile': (context) => const UserProfile(),
        '/Quiz': (context) => const Quiz(),
        '/Splashscreen': (context) => const Splashscreen(),
        '/AspireAppBar': (context) => const AspireAppBar(),
        '/HomePage': (context) => const HomePage(),
        '/ChatPage': (context) => const ChatPage(),
        '/Notifi': (context) => const Notifi(),
        '/TestimonialPage': (context) => const TestimonialPage(),
        '/FeedBack': (context) => const FeedBack(),
        '/CVTips': (context) => const CVTips(),
        '/InterviewGuide': (context) => const InterviewGuide(),
        '/admin-careers': (context) => const AdminCareerPage(),
        '/admin-quizzes': (context) => const AdminQuizzesPage(),
        '/AdminResourcesShowPage': (context) => const AdminResourcesShowPage(),
        '/AdminResourcesPage': (context) => const AdminResourcesPage(),
        // '/YoutubePlayerScreen': (context) => const YoutubePlayerScreen(),
        '/ShowAdminCareerPage': (context) => const ShowAdminCareerPage(),




















                  }
    );
  }
}

