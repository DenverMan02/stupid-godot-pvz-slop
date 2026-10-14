
precision mediump float;

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

uniform vec4 Params;
uniform sampler2D Tex0;
uniform sampler2D Tex1;

//
// Function declarations
//

PS_OUTPUT ps_main( in PS_INPUT In );

//
// Function definitions
//

PS_OUTPUT ps_main( in PS_INPUT In ) {
    float inTime;
    vec2 wavyPoint;
    float clampTime;
    float percentIntoTime;
    float halfDuration = 0.750000;
    float currentFrequency;
    float currentAmplitude;
    vec4 color;
    PS_OUTPUT Out;

    inTime = Params.x ;
    wavyPoint = In.Texture0;
    clampTime = clamp( inTime, 0.00000, 1.50000);
    percentIntoTime = (clampTime / 1.50000);
    currentFrequency = mix( 0.00000, 9.00000, percentIntoTime);
    currentAmplitude = mix( 0.00000, 0.160000, percentIntoTime);
    wavyPoint.x  += (sin( ((inTime * 9.00000) + ((currentFrequency * 3.14159) * wavyPoint.y )) ) * currentAmplitude);
    color = texture2D( Tex0, wavyPoint);
    color.w  = texture2D( Tex1, wavyPoint).w ;
    if ( (wavyPoint.x  < 0.00000) ){
        color.xyz  = vec3( 0.00000, 0.00000, 0.00000);
    }
    if ( (wavyPoint.x  > 1.00000) ){
        color.xyz  = vec3( 0.00000, 0.00000, 0.00000);
    }
    if ( (clampTime > halfDuration) ){
        color.xyz  = mix( color.xyz , vec3( 1.00000, 1.00000, 1.00000), vec3( ((clampTime - halfDuration) / halfDuration)));
    }
    Out.Color = color;
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


