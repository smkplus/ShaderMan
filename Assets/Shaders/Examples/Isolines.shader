// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"ShaderMan/Isolines"{
Properties{
_MainTex("_MainTex", 2D) = "white"{}
_SecondTex("SecondTex", 2D) = "white"{}

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
sampler2D _MainTex;
sampler2D _SecondTex;

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

fixed2 doit( in fixed2 p, in fixed off, fixed amp )
{
    fixed f = 0.0;
	fixed a = 0.0;
    [unroll(100)]
for( int i=0; i<10; i++ )
    {
  	    fixed h = fixed(i)/10.0;
  	    fixed g = tex2D( _SecondTex, fixed2(0.01+h*0.5, 0.25)).x;
  	    fixed k = 1.0 + 0.4*g*g;

        fixed2 q;
        q.x = sin(_Time.y*0.015+0.67*g*(1.0+amp) + off + fixed(i)*121.45) * 0.5 + 0.5;
        q.y = cos(_Time.y*0.016+0.63*g*(1.0+amp) + off + fixed(i)*134.76) * 0.5 + 0.5;
	    fixed2 d = p - q;
		fixed at = 1.0/(0.01+dot(d,d));
        f += k*0.1*at;
		a += 0.5 + 0.5*sin(2.0*atan2(d.x,d.y));//*at;
    }
	
    return fixed2(f,a);
}

fixed4 frag(v2f i) : SV_Target{

{
    fixed2 p = i.uv.xy / 1;

	fixed isTripy = smoothstep( 86.5, 87.5, iChannelTime[1] ) - 
		            smoothstep( 100.5, 108.0, iChannelTime[1] );

    fixed2 ref = doit( p, 0.0, isTripy );
    fixed b = ref.x;	

	
    fixed3 col = tex2D( _MainTex,fixed2(pow(0.25*ref.x,0.25), 0.5)).xyz
             * tex2D( _MainTex,fixed2(0.1*pow(ref.y,1.2), 0.6)).xyz;
	col = sqrt(col)*2.0;
	
	fixed3 col2 = col;
	col2 = 4.0*col2*(1.0-col2);
	col2 = 4.0*col2*(1.0-col2);
	col2 = 4.0*col2*(1.0-col2);
    
	col = lerp( col, col2, isTripy );

	fixed useLights = 0.5 + 1.5*smoothstep( 45.0, 45.2, iChannelTime[1] );
	col += useLights*0.5*pow( b*0.1, 4.0 ) * pow( tex2D( _SecondTex, fixed2(0.1,0.25) ).x, 2.0 );

	return  fixed4( col, 1.0 );;
}

}ENDCG
}
}
}

