using UnityEngine;
using System.Collections;
using System.Text.RegularExpressions;
[ExecuteInEditMode]
public class CodeGenerator : MonoBehaviour {
	public static CodeGenerator instance = null;//SingleTon

	private enum types{Texture,Int,Float,Vector,Color}
	private types Types;

	[HideInInspector]
	public string ShaderName;
	string Result;

	string BaseShader;


	#region MainFunctions
	void Update(){
		instance = this;
		//BaseShader = BaseShader.BaseReplace("ShaderName",ShaderName);
		BaseShader = @"Shader ""ShaderMan/ShaderName""
	{

	Properties{
	//Properties
	}

	SubShader
	{
	Tags { ""RenderType"" = ""Transparent"" ""Queue"" = ""Transparent"" }

	Pass
	{
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha

	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#include ""UnityCG.cginc""

	struct VertexInput {
    float4 vertex : POSITION;
	float2 uv:TEXCOORD0;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
	//VertexInput
	};


	struct VertexOutput {
	float4 pos : SV_POSITION;
	float2 uv:TEXCOORD0;
	//VertexOutput
	};

	//Variables

	//Functions



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
	//MainImage
	}
	ENDCG
	}
  }
}
";

	}

	#endregion




	public object Convert(string input)
	{
		var mainImage = Regex.Match(input, @"void\s+mainImage[^\{]+\{([^}]+)\}",RegexOptions.Multiline | RegexOptions.Singleline);
		var functions = Regex.Match(input, @"(.*)(?=void mainImage)",RegexOptions.Multiline | RegexOptions.Singleline);
		print ( mainImage.Groups [1].Value);
		BaseReplace("ShaderName",ShaderName);
		BaseReplace ("//MainImage", mainImage.Groups [1].Value);
		BaseReplace ("//Functions", functions.Groups[1].Value);



		var mainImageComponents = Regex.Match(input, @"void\s+mainImage\(\s*out\s*vec4\s*(.+?)\s*\,\s*in\s*vec2\s*(.+?)\s*\)",RegexOptions.Multiline | RegexOptions.Singleline);
		var fragColor = mainImageComponents.Groups [1].Value;
		var fragCoord = mainImageComponents.Groups [2].Value;

		BaseReplace(fragColor,"fragColor");
		BaseReplace(fragCoord,"fragCoord");



		//news
		BaseReplace( @"\=\s*vec3\(([^;,]+)\)", "= vec3($1,$1,$1)",RegexOptions.Multiline | RegexOptions.Singleline);
		BaseReplace( @"\=\s*vec4\(([^;,]+)\)", "= vec3($1,$1,$1,$1)",RegexOptions.Multiline | RegexOptions.Singleline);

		BaseReplace( "vec|half|float", "fixed");
		BaseReplace( "mix", "lerp");
		BaseReplace( "iGlobalTime", "_Time.y");
		BaseReplace( "fragColor =", "return");
		BaseReplace( "fract", "frac");
		BaseReplace( @"ifixed(\d)", "fixed$1");//ifixed to fixed
		BaseReplace( "texture", "tex2D");
		BaseReplace( "tex2DLod", "tex2Dlod");
		BaseReplace( "refrac", "refract");
		BaseReplace( "iChannel0", "_MainTex");
		BaseReplace( "iChannel1", "_SecondTex");
		BaseReplace( "iChannel2", "_ThirdTex");
		BaseReplace( "iChannel3", "_FourthTex");
		//BaseReplace( "fragCoord", "i.vertex");
		BaseReplace (@"iResolution.((x|y){1,2})?", "1");
		BaseReplace( @"fragCoord.xy / iResolution.xy", "i.uv");
		BaseReplace( @"fragCoord(.xy)?", "i.uv");
		BaseReplace( @"iResolution(\.(x|y){1,2})?", "1");

		BaseReplace( "iMouse", "_iMouse");
		BaseReplace( "mat2", "fixed2x2");
		BaseReplace( "mat3", "fixed3x3");
		BaseReplace( "mat4", "fixed4x4");
		//BaseReplace( @"(m)\*(p)", "mul($1,$2)");
		BaseReplace( "mod", "fmod");
		BaseReplace( @"for\(", "[unroll(100)]\nfor(");
		BaseReplace( "iTime", "_Time.y");
		BaseReplace( @"(tex2Dlod\()([^,]+\,)([^)]+\)?[)]+.+(?=\)))", "$1$2float4($3,0)");
		BaseReplace( @"fixed4\(([^(,]+?)\)", "fixed4($1,$1,$1,$1)");
		BaseReplace( @"fixed3\(([^(,]+?)\)", "fixed3($1,$1,$1)");
		BaseReplace( @"fixed2\(([^(,]+?)\)", "fixed2($1,$1)");
		BaseReplace( @"tex2D\(([^,]+)\,\s*fixed2\(([^,].+)\)\,(.+)\)", "tex2Dlod($1,fixed4($2,fixed2($3,$3)))");//when vec3 col = texture( iChannel0, vec2(uv.x,1.0-uv.y), lod ).xyz; -> https://www.shadertoy.com/view/4slGWn
		//BaseReplace( @"#.+","");
		BaseReplace( @"texelFetch","tex2D");//badan bokonesh texlod
		BaseReplace( @"atan\(([^,]+?)\,([^,]+?)\)","atan2($2,$1)");//badan bokonesh texlod
		//BaseReplace( "([*+\\/-])\\s*(pi|PI)", "$13.14159265359");

		BaseReplace( "gl_FragCoord", "((i.screenCoord.xy/i.screenCoord.w)*_ScreenParams.xy)");
		//BaseReplace( @"(.+\s*)(\*\=)\s*([^ ;*+\/]+)", "$1 = mul($1,$3)");

		if(BaseShader.Contains("_MainTex")){
			Decelaration ("MainTex", types.Texture);
		}
		if(BaseShader.Contains("_SecondTex")){
			Decelaration ("SecondTex", types.Texture);
		}
		if(BaseShader.Contains("_ThirdTex")){
			Decelaration ("ThirdTex", types.Texture);
		}
		if(BaseShader.Contains("_FourthTex")){
			Decelaration ("FourthTex", types.Texture);
		}

		if (BaseShader.Contains ("iMouse")) {
			Decelaration ("iMouse", types.Vector);
		}
		if (BaseShader.Contains ("iDate")) {
			Decelaration ("iDate", types.Vector);
		}


		return BaseShader;
	}


	void Decelaration(string name,types type){

		string VariableType = "";
		string Initialize = "";
		string CorrespondingVariable = "";

		switch (type) {
		case types.Int:
			VariableType = "int";
			CorrespondingVariable = "int";
			Initialize = "0";
			break;
		case types.Float:
			VariableType = "float";
			CorrespondingVariable = "float";
			Initialize = "0";
			break;
		case types.Texture:
			VariableType = "2D";
			CorrespondingVariable = "sampler2D";
			Initialize = @"""white"" {}";

			break;
		case types.Color:
			VariableType = "Color";
			CorrespondingVariable = "float4";
			Initialize = "(0,0,0,0)";
			break;
		case types.Vector:
			VariableType = "Vector";
			CorrespondingVariable = "float4";
			Initialize = "(0,0,0,0)";
			break;
		default:
			VariableType = "int";
			CorrespondingVariable = "int";
			Initialize = "0";
			break;
		}
		CorrespondingVariable += " _" + name + ";";//for example sampler2D _MainTex;

		string Properties = @"_name (""name"", type) = initialize";
		Properties = Regex.Replace (Properties, "name", name);
		Properties = Regex.Replace (Properties, "type", VariableType);
		Properties = Regex.Replace (Properties, "initialize", Initialize);
		BaseReplace ( "//Properties", Properties);
		BaseReplace ( "//Variables", "$0\n"+CorrespondingVariable);
	}



	void BaseReplace(string pattern,string replacement){
		BaseShader = Regex.Replace(BaseShader,pattern,replacement);
	}

	void BaseReplace(string pattern,string replacement,RegexOptions options){
		BaseShader = Regex.Replace(BaseShader,pattern,replacement,options);
	}
}
