// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderToyConverter/Cave"{
Properties{
_MainTex("MainTex", 2D) = "white"{}

}
SubShader{
Pass{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include "UnityCG.cginc"
struct appdata{
float4 vertex : POSITION;
float2 uv : TEXCOORD0;
};
sampler2D _MainTex;
fixed4 fragColor;

struct v2f
{
float2 uv : TEXCOORD0;
float4 vertex : SV_POSITION;
float4 screenCoord : TEXCOORD1;
};

v2f vert(appdata v)
{
v2f o;
o.vertex = UnityObjectToClipPos(v.vertex);
o.uv = v.uv;
o.screenCoord.xy = ComputeScreenPos(o.vertex);
return o;
}
fixed4 frag(v2f i) : SV_Target{

{
    // input: pixel coordinates
    fixed2 p = (-1 + 2.0*i.uv)/1;

    // angle of each pixel to the center of the screen
    fixed a = atan2(p.x,p.y);
    
    // fmodified distance metric
    fixed r = pow( pow(p.x*p.x,4.0) + pow(p.y*p.y,4.0), 1.0/8.0 );
    
    // index tex2D by (animated inverse) radious and angle
    fixed2 uv = fixed2( 1.0/r + 0.2*_Time.y, a );

    // pattern: cosines
    fixed f = cos(12.0*uv.x)*cos(6.0*uv.y);

    // color fetch: palette
    fixed3 col = 0.5 + 0.5*sin( 3.1416*f + fixed3(0.0,0.5,1.0) );
    
    // lighting: darken at the center    
    col = col*r;
    
    // output: pixel color
    return fixed4( col, 1.0 );
}
}ENDCG
}
}
}

