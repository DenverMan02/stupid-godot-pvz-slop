
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
    vec4 color;
    PS_OUTPUT Out;

    color = (texture2D( Tex0, In.Texture0) * In.Color);
    color.w  = texture2D( Tex1, In.Texture0).w ;
    Out.Color.w  = color.w ;
    Out.Color.xyz  = mix( color.xyz , Params.xyz , vec3( Params.w ));
    Out.Color.xyz  *= Out.Color.w ;
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


