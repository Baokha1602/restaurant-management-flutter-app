import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // cần gói này

class HomeRestaurantScreen extends StatelessWidget {
  const HomeRestaurantScreen({super.key});

  // ✅ Mở liên kết Facebook
  Future<void> _openFacebook() async {
    const url = "https://www.facebook.com/share/18mNXM76sB";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Không thể mở liên kết: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.orange;
    final textColor = Colors.grey.shade800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE0B2),
              Color(0xFFFFCC80),
              Color(0xFFFFB74D),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🌟 HERO SECTION
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/hero.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 280,
                    ),
                    Container(
                      width: double.infinity,
                      height: 280,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned.fill( // ❌ bỏ const ở đây
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "WELCOME TO",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 24,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "HUTECH RESTAURANT",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [
                                      Colors.orangeAccent,
                                      Colors.yellow,
                                      Colors.white,
                                    ],
                                  ).createShader(
                                    Rect.fromLTWH(0, 0, 200, 70),
                                  ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // 🧡 ABOUT SECTION
                _buildSection(
                  title: "ĐA PHONG CÁCH ẨM THỰC",
                  description:
                  "HUTECH RESTAURANT là hệ thống nhà hàng lẩu nướng & hải sản lớn nhất, nổi bật với sự đa dạng trong phong cách ẩm thực. Tại đây, thực khách có thể thưởng thức hành trình vị giác phong phú từ món nướng BBQ, sushi, sashimi, salad kiểu Địa Trung Hải, đến dimsum đậm chất Hong Kong.",
                  imagePath: 'assets/images/about1.png',
                  textColor: textColor,
                ),

                // 🏛️ LUXURY SECTION
                _buildSection(
                  title: "KHÔNG GIAN SANG TRỌNG",
                  description:
                  "Không chỉ ẩm thực tinh tế, HUTECH RESTAURANT còn nổi bật bởi không gian sang trọng, thiết kế hiện đại kết hợp Á – Âu, ánh sáng ấm áp, nội thất cao cấp và phòng VIP riêng tư – lý tưởng cho gia đình, đối tác, hay tiệc sang trọng.",
                  imagePath: 'assets/images/about2.png',
                  textColor: textColor,
                ),

                // 🤝 SERVICE SECTION
                _buildSection(
                  title: "DỊCH VỤ CHUYÊN NGHIỆP",
                  description:
                  "HUTECH RESTAURANT ghi điểm nhờ dịch vụ chuyên nghiệp. Đội ngũ nhân viên thân thiện, hiểu rõ thực đơn, phục vụ tận tâm, chu đáo, mang đến trải nghiệm ẩm thực hoàn hảo nhất cho mỗi thực khách.",
                  imagePath: 'assets/images/about3.png',
                  textColor: textColor,
                ),

                // 🧾 FOOTER
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  padding:
                  const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "HỆ THỐNG NHÀ HÀNG HUTECH",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Đơn vị chủ quản: Công ty Cổ phần 3 Thành Viên\n"
                            "Trụ sở: 27 Lê Văn Lương, Thanh Xuân, Hà Nội",
                        style: TextStyle(color: textColor, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: mainColor),
                          const SizedBox(width: 8),
                          Text("0353 413 73", style: TextStyle(color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, color: mainColor),
                          const SizedBox(width: 8),
                          Text(
                            "htbuffetrestaurant2025@gmail.com",
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          "Copyright © 2025 Hutech Restaurant",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required String imagePath,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              " $title ",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              description,
              textAlign: TextAlign.justify,
              style: TextStyle(color: textColor, height: 1.6, fontSize: 15.5),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ],
        ),
      ),
    );
  }
}
