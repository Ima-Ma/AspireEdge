
// import 'package:aspire_edge/AdminScreens/homecomponents/bottombar.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:google_fonts/google_fonts.dart';

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // 🔵 Top Blue Section
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.only(
//                   top: 50, left: 20, right: 20, bottom: 30),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF6C95DA),
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(30),
//                   bottomRight: Radius.circular(30),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Profile Row
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           const CircleAvatar(
//                             radius: 25,
//                             backgroundImage: AssetImage("assets/profile.png"),
//                           ),
//                           const SizedBox(width: 12),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Imama Mushtaq",
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               Text(
//                                 "sample@xyz.com",
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.white70,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       const Icon(Icons.more_vert, color: Colors.white),
//                     ],
//                   ),

//                   const SizedBox(height: 20),

//                   // Info Cards Row (Users & Admins) using StreamBuilder
//                   StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('users')
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return const Center(
//                             child: CircularProgressIndicator(
//                                 color: Colors.white));
//                       }

//                       // Count roles
//                       final docs = snapshot.data!.docs;
//                       int userCount = docs
//                           .where((d) => d['Role'] == 'User')
//                           .length;
//                       int adminCount = docs
//                           .where((d) => d['Role'] == 'Admin')
//                           .length;

//                       return Row(
//                         children: [
//                           Expanded(
//                             child: _infoCard(
//                               title: "Total Users",
//                               subtitle: "$userCount Users",
//                               icon: Icons.people,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _infoCard(
//                               title: "Total Admins",
//                               subtitle: "$adminCount Admins",
//                               icon: Icons.admin_panel_settings,
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📊 Chart Section
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Bandwidth Usage",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       DropdownButton<String>(
//                         value: "Weekly",
//                         items: const [
//                           DropdownMenuItem(
//                               value: "Weekly", child: Text("Weekly")),
//                           DropdownMenuItem(
//                               value: "Monthly", child: Text("Monthly")),
//                         ],
//                         onChanged: (val) {},
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 200, child: _BandwidthChart()),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📌 Feature Icons
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: const [
//                   _featureIcon(icon: Icons.bar_chart, label: "Reports"),
//                   _featureIcon(icon: Icons.insert_chart, label: "Stats"),
//                   _featureIcon(icon: Icons.devices, label: "Devices"),
//                   _featureIcon(icon: Icons.settings, label: "Settings"),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//           ],
//         ),
//       ),

//       // ✅ Custom bottom bar
//       bottomNavigationBar: const CustomBottomBar(currentIndex: 0),
//     );
//   }
// }

// // 📊 Chart Widget
// class _BandwidthChart extends StatelessWidget {
//   const _BandwidthChart();

//   @override
//   Widget build(BuildContext context) {
//     return LineChart(
//       LineChartData(
//         gridData: FlGridData(
//           show: true,
//           horizontalInterval: 2,
//           getDrawingHorizontalLine: (value) =>
//               FlLine(color: Colors.grey.shade300, strokeWidth: 1),
//           getDrawingVerticalLine: (value) =>
//               FlLine(color: Colors.grey.shade200, strokeWidth: 1),
//         ),
//         titlesData: FlTitlesData(
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 35,
//               interval: 2,
//               getTitlesWidget: (value, meta) => Text(
//                 value.toInt().toString(),
//                 style: const TextStyle(fontSize: 10, color: Colors.black54),
//               ),
//             ),
//           ),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 25,
//               getTitlesWidget: (value, meta) {
//                 switch (value.toInt()) {
//                   case 0:
//                     return const Text("Mon",
//                         style: TextStyle(fontSize: 10));
//                   case 1:
//                     return const Text("Tue",
//                         style: TextStyle(fontSize: 10));
//                   case 2:
//                     return const Text("Wed",
//                         style: TextStyle(fontSize: 10));
//                   case 3:
//                     return const Text("Thu",
//                         style: TextStyle(fontSize: 10));
//                   case 4:
//                     return const Text("Fri",
//                         style: TextStyle(fontSize: 10));
//                   case 5:
//                     return const Text("Sat",
//                         style: TextStyle(fontSize: 10));
//                   case 6:
//                     return const Text("Sun",
//                         style: TextStyle(fontSize: 10));
//                 }
//                 return const Text("");
//               },
//             ),
//           ),
//           rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         minX: 0,
//         maxX: 6,
//         minY: 0,
//         maxY: 10,
//         lineBarsData: [
//           LineChartBarData(
//             isCurved: true,
//             color: Colors.blue,
//             barWidth: 3,
//             dotData: FlDotData(show: true),
//             spots: const [
//               FlSpot(0, 6),
//               FlSpot(1, 7),
//               FlSpot(2, 8),
//               FlSpot(3, 9),
//               FlSpot(4, 8),
//               FlSpot(5, 9),
//               FlSpot(6, 10),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // 📌 Info Card Widget
// Widget _infoCard(
//     {required String title,
//     required String subtitle,
//     required IconData icon}) {
//   return Card(
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//     elevation: 4,
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Colors.blue.shade700),
//           const SizedBox(height: 8),
//           Text(title,
//               style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600, fontSize: 14)),
//           Text(subtitle,
//               style: GoogleFonts.poppins(
//                   fontSize: 12, color: Colors.black54)),
//         ],
//       ),
//     ),
//   );
// }

// // 📌 Feature Icon Widget
// class _featureIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _featureIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           radius: 24,
//           backgroundColor: Colors.blue.shade100,
//           child: Icon(icon, color: Colors.blue.shade800),
//         ),
//         const SizedBox(height: 6),
//         Text(label,
//             style: const TextStyle(fontSize: 12, color: Colors.black87)),
//       ],
//     );
//   }
// }


// import 'package:aspire_edge/AdminScreens/homecomponents/bottombar.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class DashboardPage extends StatefulWidget {
//   const DashboardPage({super.key});

//   @override
//   State<DashboardPage> createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // 🔵 Top Blue Section
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.only(
//                   top: 50, left: 20, right: 20, bottom: 30),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF6C95DA),
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(30),
//                   bottomRight: Radius.circular(30),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Profile Row
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           const CircleAvatar(
//                             radius: 25,
//                             backgroundImage: AssetImage("assets/profile.png"),
//                           ),
//                           const SizedBox(width: 12),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Imama Mushtaq",
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               Text(
//                                 "sample@xyz.com",
//                                 style: GoogleFonts.poppins(
//                                   color: Colors.white70,
//                                   fontSize: 13,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       const Icon(Icons.more_vert, color: Colors.white),
//                     ],
//                   ),

//                   const SizedBox(height: 20),

//                   // Info Cards Row (Users & Admins)
//                   StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('users')
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return const Center(
//                           child: CircularProgressIndicator(color: Colors.white),
//                         );
//                       }

//                       final docs = snapshot.data!.docs;
//                       int userCount =
//                           docs.where((d) => d['Role'] == 'User').length;
//                       int adminCount =
//                           docs.where((d) => d['Role'] == 'Admin').length;

//                       return Row(
//                         children: [
//                           Expanded(
//                             child: _infoCard(
//                               title: "Total Users",
//                               subtitle: "$userCount Users",
//                               icon: Icons.people,
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: _infoCard(
//                               title: "Total Admins",
//                               subtitle: "$adminCount Admins",
//                               icon: Icons.admin_panel_settings,
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📊 Chart Section (Dynamic CareerBank Data)
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "CareerBank Entries (This Month)",
//                         style: GoogleFonts.poppins(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 250, child: _CareerBankChart()),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 📌 Feature Icons
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: const [
//                   _featureIcon(icon: Icons.bar_chart, label: "Reports"),
//                   _featureIcon(icon: Icons.insert_chart, label: "Stats"),
//                   _featureIcon(icon: Icons.devices, label: "Devices"),
//                   _featureIcon(icon: Icons.settings, label: "Settings"),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),
//           ],
//         ),
//       ),

//       // ✅ Custom bottom bar
//       bottomNavigationBar: const CustomBottomBar(currentIndex: 0),
//     );
//   }
// }

// // 📊 CareerBank Chart Widget
// class _CareerBankChart extends StatelessWidget {
//   const _CareerBankChart();

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('CareerBank')
//           .where(
//             'createdAt',
//             isGreaterThanOrEqualTo: DateTime(
//               DateTime.now().year,
//               DateTime.now().month,
//               1,
//             ),
//           )
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         final docs = snapshot.data!.docs;

//         // 🔹 Group by day
//         Map<int, int> dailyCounts = {};
//         for (var doc in docs) {
//           final ts = doc['createdAt'] as Timestamp?;
//           if (ts != null) {
//             final date = ts.toDate();
//             final day = date.day;
//             dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
//           }
//         }

//         List<FlSpot> spots = [];
//         dailyCounts.forEach((day, count) {
//           spots.add(FlSpot(day.toDouble(), count.toDouble()));
//         });
//         spots.sort((a, b) => a.x.compareTo(b.x));

//         // Fallback when no data
//         if (spots.isEmpty) spots.add(const FlSpot(0, 0));

//         final maxY = (dailyCounts.values.isEmpty
//                 ? 1
//                 : dailyCounts.values.reduce((a, b) => a > b ? a : b))
//             .toDouble();

//         return LineChart(
//           LineChartData(
//             gridData: FlGridData(
//               show: true,
//               drawVerticalLine: true,
//               horizontalInterval: 1,
//               verticalInterval: 5,
//               getDrawingHorizontalLine: (value) => FlLine(
//                 color: Colors.grey.shade300,
//                 strokeWidth: 1,
//               ),
//               getDrawingVerticalLine: (value) => FlLine(
//                 color: Colors.grey.shade200,
//                 strokeWidth: 1,
//               ),
//             ),
//             titlesData: FlTitlesData(
//               leftTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   reservedSize: 36,
//                   getTitlesWidget: (value, meta) => Text(
//                     value.toInt().toString(),
//                     style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//               bottomTitles: AxisTitles(
//                 sideTitles: SideTitles(
//                   showTitles: true,
//                   reservedSize: 28,
//                   interval: 2,
//                   getTitlesWidget: (value, meta) => Text(
//                     value.toInt().toString(),
//                     style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//               rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//             ),
//             borderData: FlBorderData(
//               show: true,
//               border: Border.all(color: Colors.grey.shade300),
//             ),
//             minX: 1,
//             maxX: DateTime.now().day.toDouble(),
//             minY: 0,
//             maxY: maxY + 2,
//             lineBarsData: [
//               LineChartBarData(
//                 isCurved: true,
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFF6C95DA), Color(0xFF3B82F6)],
//                 ),
//                 barWidth: 4,
//                 isStrokeCapRound: true,
//                 spots: spots,
//                 belowBarData: BarAreaData(
//                   show: true,
//                   gradient: LinearGradient(
//                     colors: [
//                       const Color(0xFF6C95DA).withOpacity(0.3),
//                       const Color(0xFF3B82F6).withOpacity(0.05),
//                     ],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                 ),
//                 dotData: FlDotData(
//                   show: true,
//                   getDotPainter: (spot, percent, bar, index) =>
//                       FlDotCirclePainter(
//                     radius: 3.5,
//                     color: Colors.white,
//                     strokeColor: Colors.blue.shade700,
//                     strokeWidth: 2,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // 📌 Info Card Widget
// Widget _infoCard(
//     {required String title, required String subtitle, required IconData icon}) {
//   return Card(
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//     elevation: 4,
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: Colors.blue.shade700),
//           const SizedBox(height: 8),
//           Text(title,
//               style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600, fontSize: 14)),
//           Text(subtitle,
//               style:
//                   GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
//         ],
//       ),
//     ),
//   );
// }

// // 📌 Feature Icon Widget
// class _featureIcon extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _featureIcon({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         CircleAvatar(
//           radius: 24,
//           backgroundColor: Colors.blue.shade100,
//           child: Icon(icon, color: Colors.blue.shade800),
//         ),
//         const SizedBox(height: 6),
//         Text(label,
//             style: const TextStyle(fontSize: 12, color: Colors.black87)),
//       ],
//     );
//   }
// }



import 'package:aspire_edge/AdminScreens/ShowAdminCareerPage.dart';
import 'package:aspire_edge/AdminScreens/admin_interest_page.dart';
import 'package:aspire_edge/AdminScreens/admin_resources_show.dart';
import 'package:aspire_edge/AdminScreens/homecomponents/bottombar.dart';
import 'package:aspire_edge/AdminScreens/manage_interest_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔵 Top Blue Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 50, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Color(0xFF6C95DA),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage("assets/profile.jpg"),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Admin",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "admin@gmail.com",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.more_vert, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Cards Row (Users & Admins)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      int userCount =
                          docs.where((d) => d['Role'] == 'User').length;
                      int adminCount =
                          docs.where((d) => d['Role'] == 'Admin').length;

                      return Row(
                        children: [
                          Expanded(
                            child: _infoCard(
                              title: "Total Users",
                              subtitle: "$userCount Users",
                              icon: Icons.people,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _infoCard(
                              title: "Total Admins",
                              subtitle: "$adminCount Admins",
                              icon: Icons.admin_panel_settings,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📊 CareerBank Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    "CareerBank Monthly Trend",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 250, child: _CareerBankChart()),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📌 Feature Icons
            Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      // Reports Page
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInterestPage()),
          );
        },
        child: const _featureIcon(icon: Icons.school, label: "Add interest"),
      ),

      // Stats Page
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageInterestPage()),
          );
        },
        child: const _featureIcon(icon: Icons.menu_book, label: "manage interest"),
      ),

      // Devices Page
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ShowAdminCareerPage()),
          );
        },
        child: const _featureIcon(icon: Icons.devices, label: "show career"),
      ),

      // Settings Page
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminResourcesShowPage()),
          );
        },
        child: const _featureIcon(icon: Icons.settings, label: "Resources show"),
      ),
    ],
  ),
),

            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceAround,
            //     children: const [
            //       _featureIcon(icon: Icons.bar_chart, label: "Reports"),
            //       _featureIcon(icon: Icons.insert_chart, label: "Stats"),
            //       _featureIcon(icon: Icons.devices, label: "Devices"),
            //       _featureIcon(icon: Icons.settings, label: "Settings"),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 30),
          ],
        ),
      ),

      // ✅ Custom bottom bar
      bottomNavigationBar: const CustomBottomBar(currentIndex: 0),
    );
  }
}

// 📊 CareerBank Chart Widget
class _CareerBankChart extends StatelessWidget {
  const _CareerBankChart();

  Future<List<FlSpot>> _fetchCareerData() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final careerSnap = await FirebaseFirestore.instance
        .collection('CareerBank')
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    // Count CareerBank entries per day
    Map<int, int> dayCounts = {};
    for (var doc in careerSnap.docs) {
      final ts = doc['createdAt'];
      if (ts is Timestamp) {
        final day = ts.toDate().day;
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }
    }

    // Convert to FlSpot list for all days of month
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    List<FlSpot> spots = List.generate(
        daysInMonth,
        (i) => FlSpot(
              (i + 1).toDouble(),
              dayCounts[i + 1]?.toDouble() ?? 0,
            ));
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FlSpot>>(
      future: _fetchCareerData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No CareerBank data"));
        }

        final spots = snapshot.data!;
        final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

        return LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 2,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            minX: 1,
            maxX: spots.length.toDouble(),
            minY: 0,
            maxY: maxY + 2,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                color: Colors.blue,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 📌 Info Card Widget
Widget _infoCard(
    {required String title, required String subtitle, required IconData icon}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700),
          const SizedBox(height: 8),
          Text(title,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle,
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
        ],
      ),
    ),
  );
}

// 📌 Feature Icon Widget
class _featureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _featureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: Icon(icon, color: Colors.blue.shade800),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}
