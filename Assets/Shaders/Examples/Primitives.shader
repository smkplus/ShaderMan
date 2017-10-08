// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader"ShaderMan/Primitives"{
Properties{
_MainTex("MainTex", 2D) = "white"{}
_iMouse("iMouse", Vector) = (0,0,0,0)
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
uniform sampler2D  _MainTex;
uniform fixed4     fragColor;
uniform fixed      iChannelTime[4];// channel playback time (in seconds)
uniform fixed3     iChannelResolution[4];// channel resolution (in pixels)
uniform fixed4     iMouse;// mouse pixel coords. xy: current (if MLB down), zw: click
uniform fixed4     iDate;// (year, month, day, time in seconds)
uniform fixed      iSampleRate;// sound sample rate (i.e., 44100)
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
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, fmodify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    

// A list of useful distance function to simple primitives, and an example on how to 
// do some interesting boolean operations, repetition and displacement.
//
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm


#define AA 1   // make this 1 is your machine is too slow

//------------------------------------------------------------------

fixed sdPlane( fixed3 p )
{
	return p.y;
}

fixed sdSphere( fixed3 p, fixed s )
{
    return length(p)-s;
}

fixed sdBox( fixed3 p, fixed3 b )
{
    fixed3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

fixed sdEllipsoid( in fixed3 p, in fixed3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

fixed udRoundBox( fixed3 p, fixed3 b, fixed r )
{
    return length(max(abs(p)-b,0.0))-r;
}

fixed sdTorus( fixed3 p, fixed2 t )
{
    return length( fixed2(length(p.xz)-t.x,p.y) )-t.y;
}

fixed sdHexPrism( fixed3 p, fixed2 h )
{
    fixed3 q = abs(p);
#if 0
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
#else
    fixed d1 = q.z-h.y;
    fixed d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

fixed sdCapsule( fixed3 p, fixed3 a, fixed3 b, fixed r )
{
	fixed3 pa = p-a, ba = b-a;
	fixed h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

fixed sdTriPrism( fixed3 p, fixed2 h )
{
    fixed3 q = abs(p);
#if 0
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
#else
    fixed d1 = q.z-h.y;
    fixed d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

fixed sdCylinder( fixed3 p, fixed2 h )
{
  fixed2 d = abs(fixed2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

fixed sdCone( in fixed3 p, in fixed3 c )
{
    fixed2 q = fixed2( length(p.xz), p.y );
    fixed d1 = -q.y-c.z;
    fixed d2 = max( dot(q,c.xy), q.y);
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

fixed sdConeSection( in fixed3 p, in fixed h, in fixed r1, in fixed r2 )
{
    fixed d1 = -p.y - h;
    fixed q = p.y - h;
    fixed si = 0.5*(r1-r2)/h;
    fixed d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(fixed2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

fixed sdPryamid4(fixed3 p, fixed3 h ) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    fixed box = sdBox( p - fixed3(0,-2.0*h.z,0), fixed3(2.0*h.z,2.0*h.z,2.0*h.z) );
 
    fixed d = 0.0;
    d = max( d, abs( dot(p, fixed3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, fixed3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, fixed3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, fixed3(  0, h.y,-h.x )) ));
    fixed octa = d - h.z;
    return max(-box,octa); // Subtraction
 }

fixed length2( fixed2 p )
{
	return sqrt( p.x*p.x + p.y*p.y );
}

fixed length6( fixed2 p )
{
	p = p*p*p; p = p*p;
	return pow( p.x + p.y, 1.0/6.0 );
}

fixed length8( fixed2 p )
{
	p = p*p; p = p*p; p = p*p;
	return pow( p.x + p.y, 1.0/8.0 );
}

fixed sdTorus82( fixed3 p, fixed2 t )
{
    fixed2 q = fixed2(length2(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

fixed sdTorus88( fixed3 p, fixed2 t )
{
    fixed2 q = fixed2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

fixed sdCylinder6( fixed3 p, fixed2 h )
{
    return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}

//------------------------------------------------------------------

fixed opS( fixed d1, fixed d2 )
{
    return max(-d2,d1);
}

fixed2 opU( fixed2 d1, fixed2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

fixed3 opRep( fixed3 p, fixed3 c )
{
    return fmod(p,c)-0.5*c;
}

fixed3 opTwist( fixed3 p )
{
    fixed  c = cos(10.0*p.y+10.0);
    fixed  s = sin(10.0*p.y+10.0);
    fixed2x2   m = fixed2x2(c,-s,s,c);
    return fixed3(mul(m,p.xz),p.y);
}

//------------------------------------------------------------------

fixed2 map( in fixed3 pos )
{
    fixed2 res = opU( fixed2( sdPlane(     pos), 1.0 ),
	                fixed2( sdSphere(    pos-fixed3( 0.0,0.25, 0.0), 0.25 ), 46.9 ) );
    res = opU( res, fixed2( sdBox(       pos-fixed3( 1.0,0.25, 0.0), fixed3(0.25,0.25,0.25) ), 3.0 ) );
    res = opU( res, fixed2( udRoundBox(  pos-fixed3( 1.0,0.25, 1.0), fixed3(0.15,0.15,0.15), 0.1 ), 41.0 ) );
	res = opU( res, fixed2( sdTorus(     pos-fixed3( 0.0,0.25, 1.0), fixed2(0.20,0.05) ), 25.0 ) );
    res = opU( res, fixed2( sdCapsule(   pos,fixed3(-1.3,0.10,-0.1), fixed3(-0.8,0.50,0.2), 0.1  ), 31.9 ) );
	res = opU( res, fixed2( sdTriPrism(  pos-fixed3(-1.0,0.25,-1.0), fixed2(0.25,0.05) ),43.5 ) );
	res = opU( res, fixed2( sdCylinder(  pos-fixed3( 1.0,0.30,-1.0), fixed2(0.1,0.2) ), 8.0 ) );
	res = opU( res, fixed2( sdCone(      pos-fixed3( 0.0,0.50,-1.0), fixed3(0.8,0.6,0.3) ), 55.0 ) );
	res = opU( res, fixed2( sdTorus82(   pos-fixed3( 0.0,0.25, 2.0), fixed2(0.20,0.05) ),50.0 ) );
	res = opU( res, fixed2( sdTorus88(   pos-fixed3(-1.0,0.25, 2.0), fixed2(0.20,0.05) ),43.0 ) );
	res = opU( res, fixed2( sdCylinder6( pos-fixed3( 1.0,0.30, 2.0), fixed2(0.1,0.2) ), 12.0 ) );
	res = opU( res, fixed2( sdHexPrism(  pos-fixed3(-1.0,0.20, 1.0), fixed2(0.25,0.05) ),17.0 ) );
	res = opU( res, fixed2( sdPryamid4(  pos-fixed3(-1.0,0.15,-2.0), fixed3(0.8,0.6,0.25) ),37.0 ) );
    res = opU( res, fixed2( opS( udRoundBox(  pos-fixed3(-2.0,0.2, 1.0), fixed3(0.15,0.15,0.15),0.05),
	                           sdSphere(    pos-fixed3(-2.0,0.2, 1.0), 0.25)), 13.0 ) );
    res = opU( res, fixed2( opS( sdTorus82(  pos-fixed3(-2.0,0.2, 0.0), fixed2(0.20,0.1)),
	                           sdCylinder(  opRep( fixed3(atan2(pos.z,pos.x+2.0)/6.2831, pos.y, 0.02+0.5*length(pos-fixed3(-2.0,0.2, 0.0))), fixed3(0.05,1.0,0.05)), fixed2(0.02,0.6))), 51.0 ) );
	res = opU( res, fixed2( 0.5*sdSphere(    pos-fixed3(-2.0,0.25,-1.0), 0.2 ) + 0.03*sin(50.0*pos.x)*sin(50.0*pos.y)*sin(50.0*pos.z), 65.0 ) );
	res = opU( res, fixed2( 0.5*sdTorus( opTwist(pos-fixed3(-2.0,0.25, 2.0)),fixed2(0.20,0.05)), 46.7 ) );
    res = opU( res, fixed2( sdConeSection( pos-fixed3( 0.0,0.35,-2.0), 0.15, 0.2, 0.1 ), 13.67 ) );
    res = opU( res, fixed2( sdEllipsoid( pos-fixed3( 1.0,0.35,-2.0), fixed3(0.15, 0.2, 0.05) ), 43.17 ) );
        
    return res;
}

fixed2 castRay( in fixed3 ro, in fixed3 rd )
{
    fixed tmin = 1.0;
    fixed tmax = 20.0;
   
#if 1
    // bounding volume
    fixed tp1 = (0.0-ro.y)/rd.y; if( tp1>0.0 ) tmax = min( tmax, tp1 );
    fixed tp2 = (1.6-ro.y)/rd.y; if( tp2>0.0 ) { if( ro.y>1.6 ) tmin = max( tmin, tp2 );
                                                 else           tmax = min( tmax, tp2 ); }
#endif
    
    fixed t = tmin;
    fixed m = -1.0;
    [unroll(100)]
for( int i=0; i<64; i++ )
    {
	    fixed precis = 0.0005*t;
	    fixed2 res = map( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
	    m = res.y;
    }

    if( t>tmax ) m=-1.0;
    return fixed2( t, m );
}


fixed softshadow( in fixed3 ro, in fixed3 rd, in fixed mint, in fixed tmax )
{
	fixed res = 1.0;
    fixed t = mint;
    [unroll(100)]
for( int i=0; i<16; i++ )
    {
		fixed h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

fixed3 calcNormal( in fixed3 pos )
{
    fixed2 e = fixed2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
					  e.yyx*map( pos + e.yyx ).x + 
					  e.yxy*map( pos + e.yxy ).x + 
					  e.xxx*map( pos + e.xxx ).x );
    /*
	fixed3 eps = fixed3( 0.0005, 0.0, 0.0 );
	fixed3 nor = fixed3(
	    map(pos+eps.xyy).x - map(pos-eps.xyy).x,
	    map(pos+eps.yxy).x - map(pos-eps.yxy).x,
	    map(pos+eps.yyx).x - map(pos-eps.yyx).x );
	return normalize(nor);
	*/
}

fixed calcAO( in fixed3 pos, in fixed3 nor )
{
	fixed occ = 0.0;
    fixed sca = 1.0;
    [unroll(100)]
for( int i=0; i<5; i++ )
    {
        fixed hr = 0.01 + 0.12*fixed(i)/4.0;
        fixed3 aopos =  nor * hr + pos;
        fixed dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca  = mul(        sca ,0.95);
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

fixed3 render( in fixed3 ro, in fixed3 rd )
{ 
    fixed3 col = fixed3(0.7, 0.9, 1.0) +rd.y*0.8;
    fixed2 res = castRay(ro,rd);
    fixed t = res.x;
	fixed m = res.y;
    if( m>-0.5 )
    {
        fixed3 pos = ro + t*rd;
        fixed3 nor = calcNormal( pos );
        fixed3 ref = reflect( rd, nor );
        
        // material        
		col = 0.45 + 0.35*sin( fixed3(0.05,0.08,0.10)*(m-1.0) );
        if( m<1.5 )
        {
            
            fixed f = fmod( floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
            col = 0.3 + 0.1*f*fixed3(1.0,1.0,1.0);
        }

        // lighitng        
        fixed occ = calcAO( pos, nor );
		fixed3  lig = normalize( fixed3(-0.4, 0.7, -0.6) );
		fixed amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        fixed dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        fixed bac = clamp( dot( nor, normalize(fixed3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        fixed dom = smoothstep( -0.1, 0.1, ref.y );
        fixed fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
		fixed spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);
        
        dif  = mul(        dif ,softshadow( pos, lig, 0.02, 2.5 ));
        dom  = mul(        dom ,softshadow( pos, ref, 0.02, 2.5 ));

		fixed3 lin = fixed3(0.0,0.0,0.0);
        lin += 1.30*dif*fixed3(1.00,0.80,0.55);
		lin += 2.00*spe*fixed3(1.00,0.90,0.70)*dif;
        lin += 0.40*amb*fixed3(0.40,0.60,1.00)*occ;
        lin += 0.50*dom*fixed3(0.40,0.60,1.00)*occ;
        lin += 0.50*bac*fixed3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*fixed3(1.00,1.00,1.00)*occ;
		col = col*lin;

    	col = lerp( col, fixed3(0.8,0.9,1.0), 1.0-exp( -0.0002*t*t*t ) );
    }

	return fixed3( clamp(col,0.0,1.0) );
}

fixed3x3 setCamera( in fixed3 ro, in fixed3 ta, fixed cr )
{
	fixed3 cw = normalize(ta-ro);
	fixed3 cp = fixed3(sin(cr), cos(cr),0.0);
	fixed3 cu = normalize( cross(cw,cp) );
	fixed3 cv = normalize( cross(cu,cw) );
    return fixed3x3( cu, cv, cw );
}

fixed4 frag(v2f i) : SV_Target{

{
    fixed2 mo = _iMouse.xy/1;
	fixed time = 15.0 + _Time.y;

    
    fixed3 tot = fixed3(0.0,0.0,0.0);
#if AA>1
    [unroll(100)]
for( int m=0; m<AA; m++ )
    [unroll(100)]
for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        fixed2 o = fixed2(fixed(m),fixed(n)) / fixed(AA) - 0.5;
        fixed2 p = (-1 + 2.0*(i.uv+o))/1;
#else    
        fixed2 p = (-1 + 2.0*i.uv)/1;
#endif

		// camera	
        fixed3 ro = fixed3( -0.5+3.5*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 4.0*sin(0.1*time + 6.0*mo.x) );
        fixed3 ta = fixed3( -0.5, -0.4, 0.5 );
        // camera-to-world transformation
        fixed3x3 ca = setCamera( ro, ta, 0.0 );
        // ray direction
        fixed3 rd = mul(ca , normalize( fixed3(p.xy,2.0)) );

        // render	
        fixed3 col = render( ro, rd );

		// gamma
        col = pow( col, fixed3(0.4545,0.4545,0.4545) );

        tot += col;
#if AA>1
    }
    tot /= fixed(AA*AA);
#endif

    
    return fixed4( tot, 1.0 );
}
}ENDCG
}
}
}

