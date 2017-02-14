import 'dart:html' as html;
import 'dart:web_gl' as gl;
import 'dart:typed_data';
import 'dart:async';
import 'imageutil.dart';

class NProgram {
  // calc position
  String vertextShaderSrc = const [
    "attribute vec3 vertexPosition;",
    "attribute vec3 optPosition;",
    "attribute vec4 color;",
    "attribute vec2 texCoord;",
    "varying vec4 vColor;",
    "varying vec2 textureCoord;",
    "void main() {",
    "  vColor = color;",
    "  textureCoord= texCoord;",
    "  gl_Position = vec4(optPosition+vertexPosition, 1.0);",
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
//    "  gl_FragColor = texture2D(texture, vec2(gl_FragCoord.x/256.0, -1.0*gl_FragCoord.y/256.0));",
    "}",
  ].join("\r\n");

  int _vertexPositionLocation;
  int _colorLocation;
  int _texCoordLocation;
  int _optPositionLocation;

  int get vertexPositionLocation => _vertexPositionLocation;

  int get colorLocation => _colorLocation;

  int get texCoordLocation => _texCoordLocation;

  int get optPositionLocation => _optPositionLocation;

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
    _optPositionLocation = context.getAttribLocation(program, "optPosition");
    context.useProgram(_program);
    return program;
  }
}
