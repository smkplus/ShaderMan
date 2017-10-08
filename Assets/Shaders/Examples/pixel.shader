// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderToyConverter/pixel"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
_iMouse("iMouse", Vector) = (0,0,0,0)
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
float4 _iMouse;

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

// radius of the blur
const int bokehRad = 7;

// tweak this to get bigger bokeh by dithering
// this should be an integer
const fixed tapSpacing = 1.0;


fixed3 hsv(fixed h, fixed s, fixed v)
{
  return pow(lerp(fixed3(1.0,1.0,1.0),clamp((abs(frac(h+fixed3(3.0, 2.0, 1.0)/3.0)*6.0-3.0)-1.0), 0.0, 1.0),s)*v,fixed3(2.2,2.2,2.2));
}

fixed shape(fixed2 p)
{
    return abs(p.x)+abs(p.y)-1.0;
}

fixed3 weave( fixed2 pos )
{
	fixed a = .777+_Time.y*.0001*(1.0+.3*pow(length(pos.xy/1),2.0));
	pos = pos*cos(a)+fixed2(pos.y,-pos.x)*sin(a);
    pos = fmod(pos/87.0, 2.0)-1.0;
    fixed h= abs(sin(0.3*_Time.y*shape(3.0*pos)));
    fixed c= 0.05/h;
    fixed3 col = hsv(frac(0.1*_Time.y+h),1.0,1.0);
	return col*c;
}


fixed4 frag(v2f i) : SV_Target{

{
	fixed2 pos = i.uv.xy-_iMouse.xy;
	
	// I've written this so the compiler can, hopefully unroll all the integer maths to consts.
	fixed3 col = fixed3(0,0,0);
	int count = 0;
	const int h = ((bokehRad+1)*15)/13; // compiler won't let me cast to fixeds and do *2/sqrt(3) in a const
	for ( int i=-bokehRad; i <= bokehRad; i++ )
	{
		int ai = (i>0)?i:-i; // seriously? no int abs?
		for ( int j=-h; j <= h; j++ )
		{
			int aj = (j>0)?j:-j;
			if ( (h-aj)*2 > ai )
			{
				col += weave(pos+tapSpacing*fixed2(i,j));
				count++;
			}
		}
	}
	
	col /= fixed(count);

		
	return fixed4(pow(col,fixed3(1.0/2.2,1.0/2.2,1.0/2.2)),1.0);
}
}ENDCG
}
}
}

