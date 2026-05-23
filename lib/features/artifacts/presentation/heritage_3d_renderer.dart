import 'dart:async';
import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_math/three_js_math.dart' as math;
import '../../../core/theme/app_theme.dart';
import 'simulation_info_overlay.dart';

class Heritage3DRenderer extends StatefulWidget {
  final String title;
  final String simulationId;

  const Heritage3DRenderer({
    super.key,
    required this.title,
    required this.simulationId,
  });

  @override
  State<Heritage3DRenderer> createState() => _Heritage3DRendererState();
}

class _Heritage3DRendererState extends State<Heritage3DRenderer> {
  three.ThreeJS? _threeJs;
  String? _sceneError;
  bool _sceneReady = false;

  @override
  void initState() {
    super.initState();
    _initializeScene();
  }

  void _initializeScene() {
    try {
      final engine = three.ThreeJS(
        setup: _setupScene,
        onSetupComplete: () {
          _markSceneReady();
        },
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

    final aspect = engine.height == 0 ? 1.0 : engine.width / engine.height;
    engine.camera = three.PerspectiveCamera(48, aspect, 0.1, 2200);
    engine.camera.position.setValues(-34, 28, -34);
    engine.camera.lookAt(math.Vector3(0, 0, 0));

    engine.scene = three.Scene();
    engine.scene.background = math.Color.fromHex32(0x0F1116);

    three.OrbitControls(engine.camera, engine.globalKey);

    engine.scene.add(three.AmbientLight(0xF0E6D8, 0.72));

    final sunLight = three.DirectionalLight(0xFFD9B0, 1.85);
    sunLight.position.setValues(44, 74, 22);
    engine.scene.add(sunLight);

    final fillLight = three.PointLight(0x8AB3FF, 0.8);
    fillLight.position.setValues(-50, 22, -40);
    engine.scene.add(fillLight);

    _buildLalibelaChurch(engine.scene);
    _buildExcavationEnvironment(engine.scene);
    engine.scene.fog = three.Fog(0x0F1116, 46, 210);

    engine.addAnimationEvent((dt) {
      // This animation event forces a continuous render loop,
      // which is required for OrbitControls to be interactive and
      // truly explorable in 3D.
    });
    _markSceneReady();
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
    setState(() {
      _sceneReady = true;
    });
  }

  void _buildLalibelaChurch(three.Scene scene) {
    final stoneMaterial = three.MeshStandardMaterial({
      three.MaterialProperty.color: math.Color.fromHex32(0xB56D4A),
      three.MaterialProperty.roughness: 0.78,
      three.MaterialProperty.metalness: 0.04,
    });

    final cutoutMaterial = three.MeshStandardMaterial({
      three.MaterialProperty.color: math.Color.fromHex32(0x1D0E08),
      three.MaterialProperty.roughness: 1.0,
    });

    const tierHeight = 4.2;
    final tierScale = [1.0, 0.94, 0.89];
    for (var i = 0; i < tierScale.length; i++) {
      final scale = tierScale[i];
      final y = (i * tierHeight) - 4.6;

      final verticalArm = three.Mesh(
        three.BoxGeometry(4.2 * scale, tierHeight, 12.2 * scale),
        stoneMaterial,
      );
      verticalArm.position.setValues(0, y, 0);
      scene.add(verticalArm);

      final horizontalArm = three.Mesh(
        three.BoxGeometry(12.2 * scale, tierHeight, 4.2 * scale),
        stoneMaterial,
      );
      horizontalArm.position.setValues(0, y, 0);
      scene.add(horizontalArm);

      _addWindowRing(
        scene,
        cutoutMaterial,
        y,
        scale,
        isTopTier: i == tierScale.length - 1,
      );
    }

    final roofLevels = [0.0, 0.45, 0.9];
    for (final roofOffset in roofLevels) {
      final span = 1.0 - (roofOffset * 0.38);
      final y = 6.45 + roofOffset;

      final roofHorizontal = three.Mesh(
        three.BoxGeometry(10.2 * span, 0.46, 2.2 * span),
        cutoutMaterial,
      );
      roofHorizontal.position.setValues(0, y, 0);
      scene.add(roofHorizontal);

      final roofVertical = three.Mesh(
        three.BoxGeometry(2.2 * span, 0.46, 10.2 * span),
        cutoutMaterial,
      );
      roofVertical.position.setValues(0, y, 0);
      scene.add(roofVertical);
    }
  }

  void _addWindowRing(
    three.Scene scene,
    three.Material material,
    double y,
    double scale, {
    required bool isTopTier,
  }) {
    final windowGeometry = isTopTier
        ? three.BoxGeometry(0.62, 1.26, 0.16)
        : three.BoxGeometry(0.52, 0.88, 0.16);

    for (final zOffset in [-4.0, 0.0, 4.0]) {
      _addWindow(
        scene,
        windowGeometry,
        material,
        x: 2.12 * scale + 0.08,
        y: y,
        z: zOffset * scale,
        rotY: dart_math.pi / 2,
      );
      _addWindow(
        scene,
        windowGeometry,
        material,
        x: -2.12 * scale - 0.08,
        y: y,
        z: zOffset * scale,
        rotY: dart_math.pi / 2,
      );
    }

    for (final xOffset in [-4.0, 0.0, 4.0]) {
      _addWindow(
        scene,
        windowGeometry,
        material,
        x: xOffset * scale,
        y: y,
        z: 2.12 * scale + 0.08,
        rotY: 0,
      );
      _addWindow(
        scene,
        windowGeometry,
        material,
        x: xOffset * scale,
        y: y,
        z: -2.12 * scale - 0.08,
        rotY: 0,
      );
    }
  }

  void _addWindow(
    three.Scene scene,
    three.BufferGeometry geometry,
    three.Material material, {
    required double x,
    required double y,
    required double z,
    required double rotY,
  }) {
    final mesh = three.Mesh(geometry, material);
    mesh.position.setValues(x, y, z);
    mesh.rotation.y = rotY;
    scene.add(mesh);
  }

  void _buildExcavationEnvironment(three.Scene scene) {
    final terrainMaterial = three.MeshStandardMaterial({
      three.MaterialProperty.color: math.Color.fromHex32(0x6D3D25),
      three.MaterialProperty.roughness: 1.0,
      three.MaterialProperty.metalness: 0.0,
    });

    const pitWallHeight = 16.0;
    _addTerrainBlock(
      scene,
      terrainMaterial,
      width: 220,
      height: pitWallHeight,
      depth: 220,
      x: 122,
      y: -2,
      z: 0,
    );
    _addTerrainBlock(
      scene,
      terrainMaterial,
      width: 220,
      height: pitWallHeight,
      depth: 220,
      x: -122,
      y: -2,
      z: 0,
    );
    _addTerrainBlock(
      scene,
      terrainMaterial,
      width: 28,
      height: pitWallHeight,
      depth: 220,
      x: 0,
      y: -2,
      z: 122,
    );
    _addTerrainBlock(
      scene,
      terrainMaterial,
      width: 28,
      height: pitWallHeight,
      depth: 220,
      x: 0,
      y: -2,
      z: -122,
    );

    final floor = three.Mesh(three.PlaneGeometry(28, 28), terrainMaterial);
    floor.rotation.x = -dart_math.pi / 2;
    floor.position.y = -10.1;
    scene.add(floor);

    for (var step = 0; step < 20; step++) {
      final stair = three.Mesh(three.BoxGeometry(6.2, 1.15, 3.1), terrainMaterial);
      stair.position.setValues(-13.6, 6.0 - (step * 0.84), -12.0 - (step * 1.5));
      scene.add(stair);
    }
  }

  void _addTerrainBlock(
    three.Scene scene,
    three.Material material, {
    required double width,
    required double height,
    required double depth,
    required double x,
    required double y,
    required double z,
  }) {
    final block = three.Mesh(three.BoxGeometry(width, height, depth), material);
    block.position.setValues(x, y, z);
    scene.add(block);
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

    return Container(
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
                'Explore the 3D Lalibela church of Biete Giyorgis with its beautiful structured chruch and architecture. You can Orbit, zoom, and inspect the carved cross layout and surrounding excavation walls.',
            badges: [
              'Lalibela',
              'Biete Giyorgis',
              'True 3D',
              'Hell yeah it worked',
              widget.simulationId,
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _threeJs?.dispose();
    super.dispose();
  }
}

class _InteractionHint extends StatelessWidget {
  const _InteractionHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                'True 3D view: drag to orbit, pinch to zoom, and explore.',
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
