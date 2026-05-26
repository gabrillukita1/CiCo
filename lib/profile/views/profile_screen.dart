import 'package:cico_project/core/style/app_colors.dart';
import 'package:cico_project/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadProfile,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final p = controller.profile.value;
        if (p == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.textSub),
                const SizedBox(height: 12),
                const Text('Gagal memuat profil', style: TextStyle(color: AppColors.textSub)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildAvatarSection(p),
              const SizedBox(height: 20),
              _buildInfoCard(p),
              const SizedBox(height: 16),
              _buildVehicleCard(p),
              const SizedBox(height: 32),
              _buildLogoutButton(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAvatarSection(Map<String, dynamic> p) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
          ),
          child: const CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.background,
            child: Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          p['name'] ?? '-',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 6),
        _buildStatusBadge(p['status'] ?? 'offline'),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'standby':
        color = AppColors.active;
        label = 'Standby';
        break;
      case 'on_duty':
        color = AppColors.primary;
        label = 'Bertugas';
        break;
      case 'pending_payment':
        color = AppColors.waiting;
        label = 'Menunggu Pembayaran';
        break;
      default:
        color = AppColors.inactive;
        label = 'Offline';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> p) {
    return _card(
      title: 'Informasi Akun',
      icon: Icons.badge_rounded,
      children: [
        _infoRow(Icons.alternate_email_rounded, 'Email', p['email'] ?? '-'),
        _infoRow(Icons.phone_rounded, 'Telepon', p['phone'] ?? '-'),
        _infoRow(Icons.shield_rounded, 'Role', p['role'] ?? '-'),
      ],
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> p) {
    return _card(
      title: 'Informasi Kendaraan',
      icon: Icons.directions_car_rounded,
      children: [
        _infoRow(Icons.confirmation_number_rounded, 'Plat Nomor', p['vehicleNumber'] ?? '-'),
        _infoRow(Icons.directions_car_filled_rounded, 'Tipe Kendaraan', p['vehicleType'] ?? '-'),
      ],
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSub),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSub),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: controller.logout,
        icon: const Icon(Icons.logout_rounded, color: AppColors.inactive),
        label: const Text(
          'Logout dari Akun',
          style: TextStyle(
            color: AppColors.inactive,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.inactive),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
