// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Bubbles"{
Properties{

}
SubShader{
Pass{
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#include "UnityCG.cginc"
struct appdata{
float4 vertex : POSITION;
float2 uv : TEXCOORD0;
};
uniform fixed4     fragColor;
uniform fixed      iChannelTime[4];// channel playback time (in seconds)
uniform fixed3     iChannelResolution[4];// channel resolution (in pixels)
uniform fixed4     iMouse;// mouse pixel coords. xy: current (if MLB down), zw: click
uniform fixed4     iDate;// (year, month, day, time in seconds)
uniform fixed      iSampleRate;// sound sample rate (i.e., 44100)

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
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

fixed4 frag(v2f i) : SV_Target{

{
	fixed2 uv = i.uv;
	uv.x *=  1 / 1;

    // background	 
	fixed3 color = fixed3(0.8 + 0.2*uv.y,0.8 + 0.2*uv.y,0.8 + 0.2*uv.y);

    // bubbles	
	[unroll(100)]
for( int i=0; i<40; i++ )
	{
        // bubble seeds
		fixed pha =      sin(fixed(i)*546.13+1.0)*0.5 + 0.5;
		fixed siz = pow( sin(fixed(i)*651.74+5.0)*0.5 + 0.5, 4.0 );
		fixed pox =      sin(fixed(i)*321.55+4.1) * 1 / 1;

        // buble size, position and color
		fixed rad = 0.1 + 0.5*siz;
		fixed2  pos = fixed2( pox, -1.0-rad + (2.0+2.0*rad)*fmod(pha+0.1*_Time.y*(0.2+0.8*siz),1.0));
		fixed dis = length( uv - pos );
		fixed3  col = lerp( fixed3(0.94,0.3,0.0), fixed3(0.1,0.4,0.8), 0.5+0.5*sin(fixed(i)*1.2+1.9));
		//    col+= 8.0*smoothstep( rad*0.95, rad, dis );
		
        // render
		fixed f = length(uv-pos)/rad;
		f = sqrt(clamp(1.0-f*f,0.0,1.0));
		color -= col.zyx *(1.0-smoothstep( rad*0.95, rad, dis )) * f;
	}

    // vigneting	
	color *= sqrt(1.5-0.5*length(uv));

	return  fixed4(color,1.0);
}
}ENDCG
}
}
}

