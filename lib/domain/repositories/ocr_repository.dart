import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../entities/text_block.dart';

abstract class OcrRepository {
  Future<OcrResult> recognizeText(CameraImage image, InputImageRotation rotation);

  Future<void> dispose();
}
