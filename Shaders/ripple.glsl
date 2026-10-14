
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

//
// Function declarations
//

vec4 GetJpgSample( in vec2 uv, in vec4 keyColor );
vec2 Ripple( in vec2 uv );
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


vec2 Ripple( in vec2 uv ) {
    vec2 centerPoint;
    vec2 deltaFromCenter;
    float distance;
    vec2 result;

    centerPoint = vec2( Params.x , Params.y );
    deltaFromCenter = (centerPoint - uv);
    distance = length( deltaFromCenter );
    result = (normalize( deltaFromCenter ) * (cos( ((distance * 6.28000) + Params.z ) ) * distance));
    return fract( result );
}


PS_OUTPUT ps_main( in PS_INPUT In ) {
    vec2 uv;
    PS_OUTPUT Out;

    uv = In.Texture0;
    uv = Ripple( uv);
    Out.Color = GetJpgSample( uv, In.Color);
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


