import 'dart:io';
import 'package:cico_project/core/widgets/app_notifier.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';

class SnapPaymentPage extends StatefulWidget {
  final String redirectUrl;

  const SnapPaymentPage({super.key, required this.redirectUrl});

  @override
  State<SnapPaymentPage> createState() => _SnapPaymentPageState();
}

class _SnapPaymentPageState extends State<SnapPaymentPage> {
  late final WebViewController _controller;
  late final Dio _downloadDio; // reusable — tidak buat ulang setiap download
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi Dio sekali untuk download QRIS
    _downloadDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    if (kDebugMode) {
      (_downloadDio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SnapChannel',
        onMessageReceived: (message) {
          Get.back(result: message.message);
        },
      )
      ..addJavaScriptChannel(
        'QrisChannel',
        onMessageReceived: (message) async {
          await _downloadQrisFromUrl(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains('midtrans.com')) {
              _injectInterceptor();
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Cegah blob URL navigation (download)
            if (url.startsWith('blob:')) {
              _extractQrisUrl();
              return NavigationDecision.prevent;
            }
            // Deteksi hasil payment dari finish redirect URL
            if (!url.contains('midtrans.com')) {
              _detectPaymentResult(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  @override
  void dispose() {
    _downloadDio.close();
    super.dispose();
  }

  /// Inject JS ke halaman Snap setelah load.
  /// Snap UI sekarang adalah halaman utama (bukan iframe),
  /// sehingga kita bisa akses DOM-nya langsung.
  void _injectInterceptor() {
    _controller.runJavaScript("""
      (function() {
        // Intercept tombol "Download QRIS"
        document.addEventListener('click', function(e) {
          var target = e.target;
          while (target && target !== document) {
            if (target.classList && target.classList.contains('qris-download-button')) {
              e.preventDefault();
              e.stopImmediatePropagation();
              var img = document.querySelector('img.qr-image');
              QrisChannel.postMessage(img && img.src ? img.src : 'NO_QR');
              return;
            }
            // Intercept tombol close
            if (target.classList && target.classList.contains('close-snap-button')) {
              SnapChannel.postMessage('closed');
              return;
            }
            target = target.parentElement;
          }
        }, true);
      })();
    """);
  }

  /// Fallback: extract QR image URL via JS jika blob navigation tertangkap
  void _extractQrisUrl() {
    _controller.runJavaScript("""
      (function() {
        var img = document.querySelector('img.qr-image');
        QrisChannel.postMessage(img && img.src ? img.src : 'NO_QR');
      })();
    """);
  }

  Future<void> _downloadQrisFromUrl(String url) async {
    if (url == 'NO_QR' || !url.startsWith('http')) {
      AppNotifier.error('Gagal', 'Gambar QRIS tidak ditemukan.');
      return;
    }
    setState(() => _isDownloading = true);
    try {
      final response = await _downloadDio.get<Uint8List>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        AppNotifier.error('Gagal', 'Data gambar kosong.');
        return;
      }

      final hasAccess = await Gal.hasAccess(toAlbum: false);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) {
          AppNotifier.error('Izin Ditolak', 'Berikan izin penyimpanan untuk menyimpan QRIS.');
          return;
        }
      }

      await Gal.putImageBytes(
        bytes,
        name: 'QRIS_${DateTime.now().millisecondsSinceEpoch}',
      );
      AppNotifier.success('Tersimpan', 'QRIS berhasil disimpan ke galeri.');
    } on DioException catch (e) {
      AppNotifier.error('Gagal', 'Gagal mengunduh QRIS (${e.response?.statusCode ?? 'no response'})');
    } on GalException catch (e) {
      AppNotifier.error('Gagal', 'Gagal menyimpan ke galeri: ${e.type.message}');
    } catch (e) {
      AppNotifier.error('Error', 'Gagal: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _detectPaymentResult(String url) {
    final uri = Uri.tryParse(url);
    final status = uri?.queryParameters['transaction_status'] ?? '';
    final result = uri?.queryParameters['result'] ?? '';

    if (status == 'settlement' || status == 'capture' || result == 'success') {
      Get.back(result: 'success');
    } else if (status == 'pending') {
      Get.back(result: 'pending');
    } else if (status == 'deny' || status == 'failure' || result == 'failure') {
      Get.back(result: 'failed');
    } else {
      Get.back(result: 'closed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isDownloading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Menyimpan QRIS...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
