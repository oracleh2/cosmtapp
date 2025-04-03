import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:skin_analyzer/models/analysis_type.dart';
import 'package:skin_analyzer/providers/analysis_provider.dart';
import 'package:skin_analyzer/screens/analysis_screen.dart';
import 'package:skin_analyzer/widgets/loading_overlay.dart';

class CameraScreen extends StatefulWidget {
  final AnalysisType analysisType;

  const CameraScreen({
    Key? key,
    required this.analysisType,
  }) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isRearCameraSelected = true;
  bool _isLoading = false;

  // Состояние вспышки
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Управление ресурсами камеры при переключении приложения
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  // Инициализация камеры
  Future<void> _initCamera() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras!.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final CameraDescription cameraDescription = _isRearCameraSelected
          ? _cameras!.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back)
          : _cameras!.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);

      _controller = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      setState(() {
        _isCameraInitialized = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Ошибка при инициализации камеры: $e');
    }
  }

  // Переключение между фронтальной и задней камерой
  Future<void> _switchCamera() async {
    setState(() {
      _isRearCameraSelected = !_isRearCameraSelected;
      _isCameraInitialized = false;
    });

    await _controller?.dispose();
    await _initCamera();
  }

  // Переключение режима вспышки
  Future<void> _switchFlashMode() async {
    if (_controller == null) return;

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextMode = FlashMode.off;
        break;
    }

    await _controller!.setFlashMode(nextMode);

    setState(() {
      _flashMode = nextMode;
    });
  }

  // Получение иконки для текущего режима вспышки
  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }

  // Выбор изображения из галереи
  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _processImage(File(image.path));
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Ошибка при выборе изображения: $e');
    }
  }

  // Сделать снимок
  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      _showErrorMessage('Камера не инициализирована');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      _processImage(File(photo.path));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('Ошибка при съемке: $e');
    }
  }

  // Обработка выбранного изображения
  Future<void> _processImage(File imageFile) async {
    try {
      // Создаем временную копию изображения
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(tempDir.path, 'analysis_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final File targetFile = await imageFile.copy(targetPath);

      if (mounted) {
        final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);

        if (widget.analysisType == AnalysisType.skin) {
          // Переходим на экран анализа, где обрабатывается изображение кожи
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisScreen(
                imageFile: targetFile,
                analysisType: widget.analysisType,
              ),
            ),
          ).then((_) {
            // Удаляем временный файл после использования
            targetFile.delete().catchError((e) => debugPrint('Ошибка при удалении временного файла: $e'));
          });
        } else if (widget.analysisType == AnalysisType.product) {
          // Анализируем изображение косметического продукта сразу здесь
          final result = await analysisProvider.analyzeProductIngredients(targetFile);

          // После получения результатов переходим на экран анализа
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalysisScreen(
                  imageFile: targetFile,
                  analysisType: widget.analysisType,
                  initialData: result,
                ),
              ),
            ).then((_) {
              // Удаляем временный файл после использования
              targetFile.delete().catchError((e) => debugPrint('Ошибка при удалении временного файла: $e'));
            });
          }
        }
      }
    } catch (e) {
      _showErrorMessage('Ошибка при обработке изображения: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Показать сообщение об ошибке
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.analysisType == AnalysisType.skin
              ? 'Сделайте фото кожи'
              : 'Сфотографируйте состав',
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        loadingText: 'Обработка изображения...',
        child: Stack(
          children: [
            // Предпросмотр камеры
            if (_isCameraInitialized && _controller != null)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              )
            else if (!_isLoading)
              const Positioned.fill(
                child: Center(
                  child: Text('Ошибка при инициализации камеры'),
                ),
              ),

            // Инструкции для пользователя
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    widget.analysisType == AnalysisType.skin
                        ? 'Сделайте четкое фото проблемной зоны кожи при хорошем освещении'
                        : 'Сфотографируйте состав на упаковке так, чтобы текст был хорошо виден',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Контролы камеры
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Кнопка галереи
                  FloatingActionButton(
                    heroTag: 'galleryButton',
                    mini: true,
                    onPressed: _pickImage,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    child: const Icon(Icons.photo_library),
                  ),

                  // Кнопка съемки
                  FloatingActionButton(
                    heroTag: 'cameraButton',
                    onPressed: _takePicture,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    child: const Icon(Icons.camera_alt, size: 32),
                  ),

                  // Кнопка переключения камеры
                  if (_cameras != null && _cameras!.length > 1)
                    FloatingActionButton(
                      heroTag: 'switchCameraButton',
                      mini: true,
                      onPressed: _switchCamera,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      child: const Icon(Icons.flip_camera_ios),
                    ),
                ],
              ),
            ),

            // Кнопка вспышки
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'flashButton',
                mini: true,
                onPressed: _switchFlashMode,
                backgroundColor: Colors.black54,
                child: Icon(
                  _getFlashIcon(),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}