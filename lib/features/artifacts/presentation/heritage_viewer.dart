import 'dart:async';
import 'dart:math' as dart_math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_math/three_js_math.dart' as math;
import '../../../core/theme/app_theme.dart';
import 'simulation_info_overlay.dart';

class HeritageViewer extends StatefulWidget {
  final String title;
  final String simulationId;

  const HeritageViewer({
    super.key,
    this.title = '3D Heritage Explorer',
    this.simulationId = 'lalibela',
  });

  @override
  State<HeritageViewer> createState() => _HeritageViewerState();
}

class _HeritageViewerState extends State<HeritageViewer> {
  three.ThreeJS? _threeJs;
  three.OrbitControls? _controls;
  Timer? _sceneTimeout;
  bool _sceneReady = false;
  String? _sceneError;

  @override
  void initState() {
    super.initState();
    _initializeScene();
    _sceneTimeout = Timer(const Duration(seconds: 12), () {
      if (!mounted || _sceneReady || _sceneError != null) {
        return;
      }
      setState(() {
        _sceneError = kIsWeb
            ? '3D viewer failed to initialize on web. Refresh the page after the WebGL support script loads, and make sure your browser supports WebGL2.'
            : '3D viewer failed to initialize.';
      });
    });
  }

  void _initializeScene() {
    try {
      final engine = three.ThreeJS(
        onSetupComplete: () {
          _markSceneReady();
        },
        setup: _setupScene,
      );
      _threeJs = engine;
    } catch (_) {
      _sceneError = 'Unable to initialize 3D rendering on this device.';
    }
  }

  Future<void> _setupScene() async {
    final engine = await _resolveEngine();
    if (engine == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sceneError = 'Unable to initialize 3D rendering on this device.';
      });
      return;
    }

    try {
      final aspect = engine.height == 0 ? 1.0 : engine.width / engine.height;
      engine.camera = three.PerspectiveCamera(47, aspect, 0.1, 2200);
      engine.camera.position.setValues(-30, 34, -30);
      engine.camera.lookAt(math.Vector3(0, 0, 0));

      engine.scene = three.Scene();
      engine.scene.background = math.Color.fromHex32(0x0A0A0A);
      engine.scene.fog = three.Fog(0x0A0A0A, 20, 220);

      _controls = three.OrbitControls(engine.camera, engine.globalKey)
        ..enableDamping = true
        ..dampingFactor = 0.08
        ..minDistance = 12
        ..maxDistance = 130
        ..minPolarAngle = 0.2
        ..maxPolarAngle = dart_math.pi * 0.48
        ..target = math.Vector3(0, -0.8, 0)
        ..update();

      engine.scene.add(three.AmbientLight(0xFFF3E3, 0.42));

      final keyLight = three.DirectionalLight(0xFFD2A2, 2.4);
      keyLight.position.setValues(44, 72, 24);
      engine.scene.add(keyLight);

      final fillLight = three.PointLight(0x7DB0FF, 0.95);
      fillLight.position.setValues(-56, 20, -48);
      engine.scene.add(fillLight);

      _buildDetailedChurch(engine.scene);
      _buildDetailedEnvironment(engine.scene);

      engine.addAnimationEvent((dt) {
        _controls?.update();
      });
      _markSceneReady();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sceneError = 'Failed to load the 3D Lalibela scene.';
      });
    }
  }

  Future<three.ThreeJS?> _resolveEngine() async {
    final engine = _threeJs;
    if (engine != null) {
      return engine;
    }

    await Future<void>.delayed(Duration.zero);
    return _threeJs;
  }



  void _markSceneReady() {
    if (!mounted || _sceneReady) {
      return;
    }
    _sceneTimeout?.cancel();
    setState(() {
      _sceneReady = true;
    });
  }

  void _buildDetailedChurch(three.Scene scene) {
    final rockColor = 0xb76b4d;
    final detailColor = 0x1a0a05;
    final churchMat = three.MeshStandardMaterial({
      three.MaterialProperty.color: math.Color.fromHex32(rockColor),
      three.MaterialProperty.roughness: 0.7,
      three.MaterialProperty.metalness: 0.1,
    });
    final winMat = three.MeshStandardMaterial({
      three.MaterialProperty.color: math.Color.fromHex32(detailColor),
      three.MaterialProperty.roughness: 1.0,
    });
    double tierHeight = 4.0;
    List<double> scales = [1.0, 0.96, 0.92];
    for (int i = 0; i < 3; i++) {
      double yPos = (i * tierHeight) - 4.0;
      double s = scales[i];
      final vGeom = three.BoxGeometry(4.0 * s, tierHeight, 12.0 * s);
      final vMesh = three.Mesh(vGeom, churchMat);
      vMesh.position.setValues(0, yPos, 0);
      scene.add(vMesh);
      final hGeom = three.BoxGeometry(12.0 * s, tierHeight, 4.0 * s);
      final hMesh = three.Mesh(hGeom, churchMat);
      hMesh.position.setValues(0, yPos, 0);
      scene.add(hMesh);
      _addDetailedWindows(scene, winMat, yPos, s, i == 2);
    }
    for (int j = 0; j < 3; j++) {
      double rs = 1.0 - (j * 0.15);
      double rh = 0.4 + (j * 0.4);
      final hGeom = three.BoxGeometry(10.0 * rs, 0.4, 2.2 * rs);
      final hMesh = three.Mesh(hGeom, winMat);
      hMesh.position.setValues(0, 6.0 + rh, 0);
      scene.add(hMesh);
      final vGeom = three.BoxGeometry(2.2 * rs, 0.4, 10.0 * rs);
      final vMesh = three.Mesh(vGeom, winMat);
      vMesh.position.setValues(0, 6.0 + rh, 0);
      scene.add(vMesh);
    }

    // Add depth accents so the church reads as carved volume from every angle.
    for (final x in [-5.2, 5.2]) {
      for (final z in [-5.2, 5.2]) {
        final buttress = three.Mesh(three.BoxGeometry(1.15, 12.0, 1.15), churchMat);
        buttress.position.setValues(x, -0.2, z);
        scene.add(buttress);
      }
    }

    final entrance = three.Mesh(three.BoxGeometry(3.8, 2.0, 2.5), winMat);
    entrance.position.setValues(0, -8.5, -7.3);
    scene.add(entrance);
  }

  void _addDetailedWindows(three.Scene scene, three.Material mat, double y, double scale, bool arched) {
    final geom = arched ? three.BoxGeometry(0.6, 1.2, 0.15) : three.BoxGeometry(0.5, 0.8, 0.15);
    for (double zOff in [-4.0, 0.0, 4.0]) {
      _putWindow(scene, geom, mat, 2.0 * scale + 0.05, y, zOff * scale, dart_math.pi / 2);
      _putWindow(scene, geom, mat, -2.0 * scale - 0.05, y, zOff * scale, dart_math.pi / 2);
    }
    for (double xOff in [-4.0, 0.0, 4.0]) {
      _putWindow(scene, geom, mat, xOff * scale, y, 2.0 * scale + 0.05, 0);
      _putWindow(scene, geom, mat, xOff * scale, y, -2.0 * scale - 0.05, 0);
    }
  }

  void _putWindow(three.Scene scene, three.BufferGeometry geom, three.Material mat, double x, double y, double z, double rotY) {
    final mesh = three.Mesh(geom, mat);
    mesh.position.setValues(x, y, z);
    mesh.rotation.y = rotY;
    scene.add(mesh);
  }

  void _buildDetailedEnvironment(three.Scene scene) {
    final groundColor = 0x6e3c23;
    final groundMat = three.MeshStandardMaterial({
      three.MaterialProperty.color: math.Color.fromHex32(groundColor),
      three.MaterialProperty.roughness: 1.0,
    });
    final pitWallHeight = 16.0;
    _addBlock(scene, groundMat, 200, pitWallHeight, 200, 112, -2, 0);
    _addBlock(scene, groundMat, 200, pitWallHeight, 200, -112, -2, 0);
    _addBlock(scene, groundMat, 24, pitWallHeight, 200, 0, -2, 112);
    _addBlock(scene, groundMat, 24, pitWallHeight, 200, 0, -2, -112);
    final floorGeom = three.PlaneGeometry(24, 24);
    final floorMesh = three.Mesh(floorGeom, groundMat);
    floorMesh.rotation.x = -dart_math.pi / 2;
    floorMesh.position.y = -10.0;
    scene.add(floorMesh);
    for (int k = 0; k < 20; k++) {
      double stepY = 6.0 - (k * 0.85);
      double stepZ = -12.0 - (k * 1.5);
      final stepGeom = three.BoxGeometry(6, 1.2, 3);
      final step = three.Mesh(stepGeom, groundMat);
      step.position.setValues(-13, stepY, stepZ);
      scene.add(step);
    }

    for (int i = 0; i < 26; i++) {
      final x = -11.5 + (i * 0.92);
      final grooveFront = three.Mesh(three.BoxGeometry(0.35, 0.65, 1.25), groundMat);
      grooveFront.position.setValues(x, -9.6, 11.4);
      scene.add(grooveFront);

      final grooveBack = three.Mesh(three.BoxGeometry(0.35, 0.65, 1.25), groundMat);
      grooveBack.position.setValues(x, -9.6, -11.4);
      scene.add(grooveBack);
    }

    final poolGeom = three.BoxGeometry(4, 1, 4);
    final poolMat = three.MeshStandardMaterial({
      three.MaterialProperty.color: math.Color.fromHex32(0x2244aa),
    });
    final pool = three.Mesh(poolGeom, poolMat);
    pool.position.setValues(-8, -9.5, -8);
    scene.add(pool);
  }

  void _addBlock(three.Scene scene, three.Material material, double w, double h, double d, double x, double y, double z) {
    final geom = three.BoxGeometry(w, h, d);
    final mesh = three.Mesh(geom, material);
    mesh.position.setValues(x, y, z);
    scene.add(mesh);
  }

  @override
  Widget build(BuildContext context) {
    if (_sceneError != null) {
      return _ErrorView(message: _sceneError!);
    }

    final engine = _threeJs;
    if (engine == null) {
      return const ColoredBox(
        color: AppTheme.kBg,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.kAccent),
        ),
      );
    }

    return ColoredBox(
      color: AppTheme.kBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: engine.build()),
          if (!_sceneReady)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.kAccent),
              ),
            ),
          const Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: _InteractionHint(),
          ),
          SimulationInfoOverlay(
            title: widget.title,
            description:
                'Explore Biete Giyorgis in true 3D. Orbit, zoom, and inspect the carved cross volume, buttresses, and excavation trench.',
            badges: [
              'Lalibela',
              'Biete Giyorgis',
              'Explorable 3D',
              widget.simulationId,
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sceneTimeout?.cancel();
    _controls?.dispose();
    final engine = _threeJs;
    if (engine != null) {
      engine.dispose();
      three.loading.clear();
    }
    super.dispose();
  }
}

class _InteractionHint extends StatelessWidget {
  const _InteractionHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.threed_rotation, color: AppTheme.kAccent, size: 18),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'True 3D view: drag to orbit and pinch to zoom.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.kBg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF12151D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
