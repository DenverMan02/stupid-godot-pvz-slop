
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

PS_OUTPUT ps_main( in PS_INPUT In );

//
// Function definitions
//

PS_OUTPUT ps_main( in PS_INPUT In ) {
    float testX;
    float testY;
    PS_OUTPUT Out;

    testX = (In.Texture0.x  + (sin( (Params.x  + (In.Texture0.x  * 10.0000)) ) * 0.0100000));
    testY = (In.Texture0.y  + (cos( (Params.x  + (In.Texture0.y  * 10.0000)) ) * 0.0100000));
    if ( (testX < 0.00000) ){
        testX = 0.00000;
    }
    if ( (testX > 1.00000) ){
        testX = 1.00000;
    }
    if ( (testY < 0.00000) ){
        testY = 0.00000;
    }
    if ( (testY > 1.00000) ){
        testY = 1.00000;
    }
    In.Texture0.x  = testX;
    In.Texture0.y  = testY;
    Out.Color = texture2D( Tex0, In.Texture0);
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


