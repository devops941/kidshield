import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/child_auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import 'enter_pairing_code_screen.dart';
import 'permissions_grant_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with SingleTickerProviderStateMixin {
  late MobileScannerController _cameraController;
  late AnimationController _laserController;
  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleScannedCode(String rawCode) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Haptic feedback just like standard QR scanners (GPay/PhonePe)
    HapticFeedback.mediumImpact();

    // Clean up code: Parent QR might send "KS-3683" or "{\"pairingCode\":\"KS-3683\"}" or plain JSON
    String cleanCode = rawCode.trim();
    try {
      if (cleanCode.startsWith('{') && cleanCode.endsWith('}')) {
        final dynamic decoded = jsonDecode(cleanCode);
        if (decoded is Map) {
          cleanCode = (decoded['pairingCode'] ?? decoded['code'] ?? cleanCode).toString().trim();
        }
      }
    } catch (_) {}

    final match = RegExp(r'KS-[\dA-Za-z]+', caseSensitive: false).firstMatch(cleanCode);
    if (match != null) {
      cleanCode = match.group(0)!.toUpperCase();
    }

    final auth = Provider.of<ChildAuthProvider>(context, listen: false);
    final success = await auth.pairWithCode(cleanCode);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionsGrantScreen()),
      );
    } else {
      _isProcessing = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Pairing failed. Please re-scan parent QR or enter code manually.'),
          backgroundColor: AppColors.sosRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar(
        title: 'Scan QR Code',
        actions: [
          // Torch / Flash Button
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? AppColors.electricCyan : Colors.white70,
            ),
            onPressed: () async {
              await _cameraController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          // Switch Front/Back Camera
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white70),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.navyBackgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Live Camera Scanner Viewfinder with Glowing Cyan Corners
                Center(
                  child: Container(
                    width: 250.r,
                    height: 250.r,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricCyan.withValues(alpha: 0.25),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Real Camera Feed
                          MobileScanner(
                            controller: _cameraController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                                  _handleScannedCode(barcode.rawValue!);
                                  break;
                                }
                              }
                            },
                            errorBuilder: (context, error) {
                              final errText = error.toString().toLowerCase();
                              final isPermissionError = errText.contains('permission');
                              return Container(
                                color: const Color(0xFF07122C),
                                padding: EdgeInsets.all(20.r),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isPermissionError ? Icons.no_photography_rounded : Icons.camera_alt_outlined,
                                      size: 40.r,
                                      color: isPermissionError ? AppColors.sosRed : AppColors.electricCyan,
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      isPermissionError
                                          ? 'Camera permission denied.\nPlease enable Camera in Settings.'
                                          : 'Camera initializing...\nPoint at Parent QR',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: isPermissionError ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // 2. Animated Scanning Laser
                          AnimatedBuilder(
                            animation: _laserController,
                            builder: (context, child) {
                              return Positioned(
                                top: 20.r + (_laserController.value * 210.r),
                                left: 20.r,
                                right: 20.r,
                                child: Container(
                                  height: 2.5.h,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.electricCyan,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.electricCyan,
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // 3. 4 Glowing Cyan Viewfinder Corners
                          CustomPaint(
                            size: Size(250.r, 250.r),
                            painter: _QrCornerPainter(),
                          ),

                          // 4. Processing overlay
                          if (_isProcessing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricCyan),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Instruction matching wireframe
                Text(
                  'Scan the QR code\nfrom your parent\'s app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),

                const Spacer(flex: 2),

                // OR Divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),

                // Enter Pairing Code Option Button
                CustomButton(
                  text: 'Enter Pairing Code',
                  icon: Icons.dialpad_rounded,
                  isOutlined: true,
                  height: 48.h,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const EnterPairingCodeScreen()),
                    );
                  },
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = AppColors.electricCyan
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;
    const padding = 12.0;

    // Top-Left
    canvas.drawLine(const Offset(padding, padding + cornerLength), const Offset(padding, padding), pen);
    canvas.drawLine(const Offset(padding, padding), const Offset(padding + cornerLength, padding), pen);

    // Top-Right
    canvas.drawLine(Offset(size.width - padding - cornerLength, padding), Offset(size.width - padding, padding), pen);
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding, padding + cornerLength), pen);

    // Bottom-Left
    canvas.drawLine(Offset(padding, size.height - padding - cornerLength), Offset(padding, size.height - padding), pen);
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding + cornerLength, size.height - padding), pen);

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width - padding - cornerLength, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      pen,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding - cornerLength),
      Offset(size.width - padding, size.height - padding),
      pen,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
