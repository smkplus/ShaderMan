// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderToyConverter/ChromaticAberration"{
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
    fixed2 uv = i.uv.xy;

	fixed amount = 0.0;
	
	amount = (1.0 + sin(_Time.y*6.0)) * 0.5;
	amount *= 1.0 + sin(_Time.y*16.0) * 0.5;
	amount *= 1.0 + sin(_Time.y*19.0) * 0.5;
	amount *= 1.0 + sin(_Time.y*27.0) * 0.5;
	amount = pow(amount, 3.0);

	amount *= 0.05;
	
    fixed3 col;
    col.r = tex2D( _MainTex, fixed2(uv.x+amount,uv.y) ).r;
    col.g = tex2D( _MainTex, uv ).g;
    col.b = tex2D( _MainTex, fixed2(uv.x-amount,uv.y) ).b;

	col *= (1.0 - amount * 0.5);
	
    return fixed4(col,1.0);
}

}ENDCG
}
}
}

