import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';
import 'ntexture.dart';
import 'nprogram.dart';

main() async {
  Nonno nonno = new Nonno("assets/ic.jpg");
  html.document.body.append(nonno.element);
  await nonno.init();
  await nonno.start();
}


class Nonno {
  final int width;
  final int height;
  final int cellSize;
  html.CanvasElement _canvas;
  final String texturePath;

  Nonno(this.texturePath, {this.width: 600, this.height: 400, this.cellSize: 20}) {
    _canvas = new html.CanvasElement(width: this.width, height: this.height);
  }

  gl.RenderingContext context;


  init() async {
    print(">>>>>>A");
    double ratioHW = width / height;
    context = _canvas.getContext3d();
    context.viewport(0, 0, this.width, this.height);

    NProgram nprogram = new NProgram();
    nprogram.compile(context);

    //
    NTexture nTexture = await NTexture.newTexture(texturePath,ratioHW:ratioHW,h: 10,w:10);
    await nTexture.create(context);
    //
    //

    final vSize = 3;
    final cSize = 4;
    final tSize = 2;
    final strideSize = (9) * Float32List.BYTES_PER_ELEMENT;
    final colorOffset = (3) * Float32List.BYTES_PER_ELEMENT;
    final texOffset = (7) * Float32List.BYTES_PER_ELEMENT;
    gl.Buffer vertexBuffer = context.createBuffer();
    gl.Buffer indexBuffer = context.createBuffer();

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.enableVertexAttribArray(nprogram.vertexPositionLocation);
    context.enableVertexAttribArray(nprogram.colorLocation);
    context.enableVertexAttribArray(nprogram.texCoordLocation);
    context.vertexAttribPointer(nprogram.vertexPositionLocation, vSize, gl.FLOAT, false, strideSize, 0);
    context.vertexAttribPointer(nprogram.colorLocation, cSize, gl.FLOAT, false, strideSize, colorOffset);
    context.vertexAttribPointer(nprogram.texCoordLocation, tSize, gl.FLOAT, false, strideSize, texOffset);

    List vs = nTexture.makeVertex();
    var vertices = nTexture.vertices;
    var indexs = nTexture.indexs;
    //
    //

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexs, gl.STATIC_DRAW);
    // context.clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT );
    context.clearColor(0.0, 0.3, 0.3, 0.5);
    context.clear(gl.COLOR_BUFFER_BIT);
    context.drawElements(gl.TRIANGLES, indexs.length, gl.UNSIGNED_SHORT, 0);
    context.flush();
  }

  start() {

  }

  html.Element get element => _canvas;
}