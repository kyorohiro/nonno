import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';


void main() {
  Nonno nonno = new Nonno("assets/ic.jpg");
  html.document.body.append(nonno.element);
  nonno.start();
}

class Nonno {
  final int width;
  final int height;
  final int cellSize;
  html.CanvasElement _canvas;

  // calc position
  String vertextShaderSrc = const [
    "attribute vec3 vertexPosition;",
    "attribute vec4 color;",
    "varying vec4 vColor;",
    "void main() {",
    "  vColor = color;",
    "  gl_Position = vec4(vertexPosition, 1.0);",
    "}",
  ].join("\r\n");

  // write to pixel
  String fragmentShaderSrc = const [
    "precision mediump float;",
    "varying vec4 vColor;",
    "void main() {",
    "  gl_FragColor = vColor;",
    "}",
  ].join("\r\n");

  Nonno(String texturePath, {this.width: 600, this.height: 400, this.cellSize: 20}) {
    _canvas = new html.CanvasElement(width: this.width, height: this.height);
    gl.RenderingContext context = _canvas.getContext3d();
    context.viewport(0, 0, this.width, this.height);
    //
    // compile shader
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
    gl.Program program = context.createProgram();
    context.attachShader(program, vertexS);
    context.attachShader(program, fragmS);
    context.linkProgram(program);
    if (false == context.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Exception(["failed to link program: ", //
      context.getProgramInfoLog(program)
      ].join("\r\n"));
    }
    context.useProgram(program);
    var vertexPositionLocation = context.getAttribLocation(program, "vertexPosition");
    var colorLocation = context.getAttribLocation(program, "color");

    //
    //
    final vSize = 3;
    final cSize = 4;
    final strideSize = (7)*Float32List.BYTES_PER_ELEMENT;
    final colorOffset = (3)*Float32List.BYTES_PER_ELEMENT;
    gl.Buffer vertexBuffer = context.createBuffer();
    gl.Buffer indexBuffer = context.createBuffer();

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.enableVertexAttribArray(vertexPositionLocation);
    context.enableVertexAttribArray(colorLocation);
    context.vertexAttribPointer(vertexPositionLocation, vSize, gl.FLOAT, false, strideSize, 0);
    context.vertexAttribPointer(colorLocation, cSize, gl.FLOAT, false, strideSize, colorOffset );


    var vertices = new Float32List.fromList(<double>[
      -0.5, 0.5, 0.0,  1.0, 0.0, 0.0, 1.0,
      -0.5, -0.5, 0.0,  0.0, 1.0, 0.0, 1.0,
      0.5, 0.5, 0.0,   0.0, 0.0, 1.0, 1.0,
      0.5, -0.5, 0.0, 0.0, 0.0, 0.0, 1.0,
    ]);

    var indexs = new Uint16List.fromList(<int>[
      0,1,2,//
      1,3,2
      ]);
    //

    context.bindBuffer(gl.ARRAY_BUFFER, vertexBuffer);
    context.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
    context.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
    context.bufferData(gl.ELEMENT_ARRAY_BUFFER, indexs, gl.STATIC_DRAW);
    context.drawElements(gl.TRIANGLES, indexs.length, gl.UNSIGNED_SHORT, 0);
    context.flush();
  }

  start() {

  }

  html.Element get element => _canvas;
}
