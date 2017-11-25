
Shader "ShaderMan/MyShader"
	{

	Properties{
	//Properties
	}

	SubShader
	{
	Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

	Pass
	{
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"

	struct VertexInput {
    fixed4 vertex : POSITION;
	fixed2 uv:TEXCOORD0;
    fixed4 tangent : TANGENT;
    fixed3 normal : NORMAL;
	//VertexInput
	};


	struct VertexOutput {
	fixed4 pos : SV_POSITION;
	fixed2 uv:TEXCOORD0;
	//VertexOutput
	};

	//Variables

	// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.





	VertexOutput vert (VertexInput v)
	{
	VertexOutput o;
	o.pos = UnityObjectToClipPos (v.vertex);
	o.uv = v.uv;
	//VertexFactory
	return o;
	}
	fixed4 frag(VertexOutput i) : SV_Target
	{
	
	fixed2 p = (2.0*i.uv-1)/min(1,1);
	
    // background color
    fixed3 bcol = fixed3(1.0,0.8,0.7-0.07*p.y)*(1.0-0.25*length(p));

    // animate
    fixed tt = fmod(_Time.y,1.5)/1.5;
    fixed ss = pow(tt,.2)*0.5 + 0.5;
    ss = 1.0 + ss*0.5*sin(tt*6.2831*3.0 + p.y*0.5)*exp(-tt*4.0);
    p *= fixed2(0.5,1.5) + ss*fixed2(0.5,-0.5);

    // shape
#if 0
    p *= 0.8;
    p.y = -0.1 - p.y*1.2 + abs(p.x)*(1.0-abs(p.x));
    fixed r = length(p);
	fixed d = 0.5;
#else
	p.y -= 0.25;
    fixed a = atan2(p.y,p.x)/3.141593;
    fixed r = length(p);
    fixed h = abs(a);
    fixed d = (13.0*h - 22.0*h*h + 10.0*h*h*h)/(6.0-5.0*h);
#endif
    
	// color
	fixed s = 0.75 + 0.75*p.x;
	s *= 1.0-0.4*r;
	s = 0.3 + 0.7*s;
	s *= 0.5+0.5*pow( 1.0-clamp(r/d, 0.0, 1.0 ), 0.1 );
	fixed3 hcol = fixed3(1.0,0.5*r,0.3)*s;
	
    fixed3 col = lerp( bcol, hcol, smoothstep( -0.01, 0.01, d-r) );

    return fixed4(col,1.0);

	}
	ENDCG
	}
  }
}

