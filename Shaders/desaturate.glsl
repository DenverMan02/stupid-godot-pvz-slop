
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

uniform vec4 Saturation;
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
    vec4 color;
    float value;
    PS_OUTPUT Out;

    color = texture2D( Tex0, In.Texture0);
    color.w  = texture2D( Tex1, In.Texture0).w ;
    value = dot( color, vec4( 0.212600, 0.715200, 0.0722000, 0.00000));
    Out.Color.xyz  = (mix( vec3( value, value, value), color.xyz , Saturation.xxx ) * color.www );
    Out.Color.w  = color.w ;
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


