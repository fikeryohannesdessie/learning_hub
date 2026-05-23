import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void registerArtifact3D(String viewId, String url) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) => html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%',
  );
}
