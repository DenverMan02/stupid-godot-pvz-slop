
precision mediump float;

//
// Translator library functions
//

void xlat_lib_sincos( float x, out float s, out float c) {
  s = sin(x); 
  c = cos(x); 
}

void xlat_lib_sincos( vec2 x, out vec2 s, out vec2 c) {
  s = sin(x); 
  c = cos(x); 
}

void xlat_lib_sincos( vec3 x, out vec3 s, out vec3 c) {
  s = sin(x); 
  c = cos(x); 
}

void xlat_lib_sincos( vec4 x, out vec4 s, out vec4 c) {
  s = sin(x); 
  c = cos(x); 
}

void xlat_lib_sincos( mat2 x, out mat2 s, out mat2 c) {
  s = mat2 ( sin ( x[0] ), sin ( x[1] ) ); 
  c = mat2 ( cos ( x[0] ), cos ( x[1] ) ); 
}

void xlat_lib_sincos( mat3 x, out mat3 s, out mat3 c) {
  s = mat3 ( sin ( x[0] ), sin ( x[1] ), sin ( x[2] ) ); 
  c = mat3 ( cos ( x[0] ), cos ( x[1] ), cos ( x[2] ) ); 
}

void xlat_lib_sincos( mat4 x, out mat4 s, out mat4 c) {
  s = mat4 ( sin ( x[0] ), sin ( x[1] ), sin ( x[2] ), sin ( x[3] ) ); 
  c = mat4 ( cos ( x[0] ), cos ( x[1] ), cos ( x[2] ), cos ( x[3] ) ); 
}


float xlat_lib_saturate( float x) {
  return clamp( x, 0.0, 1.0);
}

vec2 xlat_lib_saturate( vec2 x) {
  return clamp( x, 0.0, 1.0);
}

vec3 xlat_lib_saturate( vec3 x) {
  return clamp( x, 0.0, 1.0);
}

vec4 xlat_lib_saturate( vec4 x) {
  return clamp( x, 0.0, 1.0);
}

mat2 xlat_lib_saturate(mat2 m) {
  return mat2( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0));
}

mat3 xlat_lib_saturate(mat3 m) {
  return mat3( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0));
}

mat4 xlat_lib_saturate(mat4 m) {
  return mat4( clamp(m[0], 0.0, 1.0), clamp(m[1], 0.0, 1.0), clamp(m[2], 0.0, 1.0), clamp(m[3], 0.0, 1.0));
}


//
// Structure definitions
//

struct PS_OUTPUT {
    vec4 Color;
};

struct PS_INPUT {
    vec4 Position;
    vec4 Color;
    vec2 Texture0;
};


//
// Global variable definitions
//

uniform mat4 Params;
uniform sampler2D Tex0;

//
// Function declarations
//

vec4 GetJpgSample( in vec2 uv, in vec4 keyColor );
PS_OUTPUT ps_main( in PS_INPUT In );

//
// Function definitions
//

vec4 GetJpgSample( in vec2 uv, in vec4 keyColor ) {
    vec4 result;

    result = texture2D( Tex0, uv);
    if ( (distance( result.xyz , keyColor.xyz ) == 0.00000) ){
        result = vec4( 0.00000);
    }
    return result;
}


PS_OUTPUT ps_main( in PS_INPUT In ) {
    float Frequency;
    float Phase;
    float Amplitude;
    float Spread;
    float CenterX;
    float CenterY;
    vec2 Center;
    vec2 srcPosition;
    vec2 toPixel;
    float distance;
    vec2 direction;
    vec2 wave;
    float falloff;
    vec2 uv2;
    float lighting;
    PS_OUTPUT Out;

    Frequency = Params[ 0 ].x ;
    Phase = Params[ 0 ].y ;
    Amplitude = Params[ 0 ].z ;
    Spread = Params[ 0 ].w ;
    CenterX = Params[ 1 ].x ;
    CenterY = Params[ 1 ].y ;
    Center = vec2( CenterX, CenterY);
    srcPosition = vec2( In.Position);
    toPixel = (srcPosition - Center);
    distance = length( toPixel );
    direction = normalize( toPixel );
    xlat_lib_sincos( ((Frequency * distance) + Phase), wave.x , wave.y );
    falloff = xlat_lib_saturate( (1.00000 - distance) );
    falloff = pow( falloff, (1.00000 / Spread));
    uv2 = (In.Texture0 + (((wave.x  * falloff) * Amplitude) * direction));
    lighting = mix( 1.00000, (1.00000 + ((wave.x  * falloff) * 0.200000)), xlat_lib_saturate( (Amplitude / 20.0000) ));
    Out.Color = GetJpgSample( uv2, In.Color);
    Out.Color.xyz  *= lighting;
    return Out;
}


//
// User varying
//
varying vec4 xlat_varying_POSITION;
varying vec4 xlat_varying_COLOR0;
varying vec4 xlat_varying_TEXCOORD0;

//
// Translator's entry point
//
void main() {
    PS_OUTPUT xlat_retVal;
    PS_INPUT xlat_temp_In;
    xlat_temp_In.Position = vec4( xlat_varying_POSITION);
    xlat_temp_In.Color = vec4( xlat_varying_COLOR0);
    xlat_temp_In.Texture0 = vec2( xlat_varying_TEXCOORD0);

    xlat_retVal = ps_main( xlat_temp_In);

    gl_FragData[0] = vec4( xlat_retVal.Color);
}


