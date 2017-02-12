import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';


main() async {
  Nonno nonno = new Nonno("assets/ic.jpg");
  html.document.body.append(nonno.element);
  await nonno.init();
  await nonno.start();
}

class NTexture {
  html.ImageElement imageElement;
  gl.Texture texture;

  static Future<NTexture> newTexture(String path) async {
    print("start load");
    NTexture tex = new NTexture();

    tex.imageElement = new html.ImageElement();
    Completer comp = new Completer();
    tex.imageElement.onLoad.listen((e) async {
      print("found ${tex.imageElement.width} ${tex.imageElement.height}");
      tex.imageElement = await ImageUtil.resizeImage(tex.imageElement, nextWidth: 512);
      comp.complete(tex);
    });
    tex.imageElement.onError.listen((e) {
      print("not found");
      comp.completeError(e);
    });
    tex.imageElement.src = path;
    return comp.future;
  }

  create(gl.RenderingContext context) {
    this.texture = context.createTexture();
    context.bindTexture(gl.TEXTURE_2D, texture);
    context.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, this.imageElement);
    context.generateMipmap(gl.TEXTURE_2D);
  }

  int get widht => imageElement.clientWidth;

  int get height => imageElement.clientHeight;

}

class NProgram {
  // calc position
  String vertextShaderSrc = const [
    "attribute vec3 vertexPosition;",
    "attribute vec4 color;",
    "attribute vec2 texCoord;",
    "varying vec4 vColor;",
    "varying vec2 textureCoord;",
    "void main() {",
    "  vColor = color;",
    "  textureCoord= texCoord;",
    "  gl_Position = vec4(vertexPosition, 1.0);",
    "}",
  ].join("\r\n");

  // write to pixel
  String fragmentShaderSrc = const [
    "precision mediump float;",
    "uniform sampler2D texture;",
    "varying vec2 textureCoord;",
    "varying vec4 vColor;",
    "void main() {",
    "gl_FragColor = texture2D(texture, textureCoord);",
//    "  gl_FragColor = vColor;",
    "}",
  ].join("\r\n");

  int _vertexPositionLocation;
  int _colorLocation;
  int _texCoordLocation;

  int get vertexPositionLocation => _vertexPositionLocation;

  int get colorLocation => _colorLocation;

  int get texCoordLocation => _texCoordLocation;

  gl.Program get program => _program;
  gl.Program _program;

  gl.Program compile(gl.RenderingContext context, {bool doUse: true}) {
    gl.Shader vertexS = context.createShader(gl.VERTEX_SHADER);
    gl.Shader fragmS = context.createShader(gl.FRAGMENT_SHADER);
    context.shaderSource(vertexS, vertextShaderSrc);
    context.compileShader(vertexS);
    context.shaderSource(fragmS, fragmentShaderSrc);
    context.compileShader(fragmS);
    if (false == context.getShaderParameter(vertexS, gl.COMPILE_STATUS)) {
      throw new Exception(["failed to comile vertex shader: ", //
      context.getShaderInfoLog(vertexS)
      ].join("\r\n"));
    }
    if (false == context.getShaderParameter(fragmS, gl.COMPILE_STATUS)) {
      throw new Exception(["failed to comile fragment shader: ", //
      context.getShaderInfoLog(fragmS)
      ].join("\r\n"));
    }

    //
    // link program
    _program = context.createProgram();
    context.attachShader(program, vertexS);
    context.attachShader(program, fragmS);
    context.linkProgram(program);

    if (false == context.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Exception(["failed to link program: ", //
      context.getProgramInfoLog(program)
      ].join("\r\n"));
    }
    _vertexPositionLocation = context.getAttribLocation(program, "vertexPosition");
    _colorLocation = context.getAttribLocation(program, "color");
    _texCoordLocation = context.getAttribLocation(program, "texCoord");

    context.useProgram(_program);
    return program;
  }
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

  List makeVertex(double ratioHW,{int w:4, int h:4}) {
    var vertices = (<double>[]);
    var indexs = (<int>[]);

    double xsv = -0.5;
    double ysv = 0.5* ratioHW;
    double sv = 1.0/4;

    double xst = 0.0;
    double yst = 0.0;
    double st = 1.0/4;

      for(int y = 0; y <= h; y++) {
        for (int x = 0; x <= w; x++) {
          vertices.addAll(<double>[
            xsv + sv * x,
            ysv - sv * y * ratioHW,
            0.0, /**/1.0, 0.0, 0.0, 1.0, //
            xst + st * x,
            xst + st * y
          ]);
        }
      }

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        indexs.addAll(<int>[
          (x + 0) + ((y + 0) * (w + 1)), (x + 1) + ((y + 0) * (w + 1)), (x + 0) + ((y + 1) * (w + 1)),
        ]);
        indexs.addAll(<int>[
          (x + 1) + ((y + 0) * (w + 1)), (x + 1) + ((y + 1) * (w + 1)), (x + 0) + ((y + 1) * (w + 1)),
        ]);
      }
    }

    return [vertices, indexs];
  }

  init() async {
    print(">>>>>>A");
    double ratioHW = width / height;
    context = _canvas.getContext3d();
    context.viewport(0, 0, this.width, this.height);

    NProgram nprogram = new NProgram();
    nprogram.compile(context);

    //
    NTexture nTexture = await NTexture.newTexture(texturePath);
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

    List vs = makeVertex(ratioHW);
    var vertices = new Float32List.fromList(vs[0]);
    var indexs = new Uint16List.fromList(vs[1]);
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
