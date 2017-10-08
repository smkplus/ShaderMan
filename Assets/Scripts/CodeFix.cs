using System.Collections;
using UnityEngine;
using System.Text.RegularExpressions;

[ExecuteInEditMode]
public class CodeFix : MonoBehaviour {
	public static CodeFix instance;

//	public static string Translate(string code){
//		Convert_Click ();
//		return Result;
		
//	}

	void Update(){
		instance = this;
	}

	public string[] lines;
	private string MainImage, Functions;

	private string Properties;
	[TextArea]
	public string ShaderInput,Result;
	public string ShaderName;


	public string Convert(string input)
	{
		ShaderInput = input;
		// int lines = Script.Lines.awdwadawda;
		//string mainImage = @".*void mainImage.*(\n)?{";
		//string mainImage = @".+(void\smainImage\b.+)";
		string iResolution = @".*iResolution.*|.*fragCoord.*";


		//string.Join("", functions);

		string[] lines = Regex.Split(ShaderInput, iResolution);
		string PureInput = string.Join("\n", lines);

		// MainImage = Regex.Replace(ShaderInput, @".*(?=^void\smainImage.+)","", RegexOptions.Singleline | RegexOptions.Multiline);
		Functions = Regex.Replace(ShaderInput, @"^void\smainImage.*$","",RegexOptions.Singleline | RegexOptions.Multiline);

		var mainImage = Regex.Replace(ShaderInput, @".*(?=void mainImage)", "", RegexOptions.Singleline | RegexOptions.Multiline);

		MainImage = Regex.Replace(mainImage, @"void\smainImage.*(\n\{[^\}]*\})", m => m.Groups[1].Value, RegexOptions.Singleline | RegexOptions.Multiline);
		if(!MainImage.Contains("vec2 uv")){
			MainImage = Regex.Replace(MainImage, @"(?<!vec\s|vec2\s|vec3\s|vec4\s)\buv\b", "i.uv");
			MainImage = Regex.Replace(MainImage, "fragCoord", "i.uv");
		}else{
			MainImage = Regex.Replace (MainImage, "(vec2\\s+uv\\s+=)([^;]+)", "$1 i.uv");
			MainImage = Regex.Replace(MainImage, "fragCoord", "uv");
		}

		defineProperty (ShaderInput);



		Replacing();
		return Result;
	}

	void Reset()
	{
		MainImage = "";
		Functions = "";
	}




	void Replacing()
	{
		Result = "";
		string Func = Translator(Functions);
		string Frag = Translator(MainImage);
		string Properties = defineProperty(ShaderInput);
		string Variables = defineVariable(Properties);

		string code = @"Shader" + "\"ShaderMan" + "/" + ShaderName  + "\"" + "{" + "\n" +

			"Properties{" + "\n" +
			Properties + "\n" +

			"}" + "\n" +
			"SubShader{" + "\n" +

			"Pass{" + "\n" +
			"CGPROGRAM" + "\n" +
			"#pragma vertex vert" + "\n" +
			"#pragma fragment frag" + "\n" +
			"#pragma fragmentoption ARB_precision_hint_fastest" + "\n" +


			"#include " + "\"UnityCG.cginc\"" + "\n" +

			"struct appdata" +
			"{" + "\n" +
			"float4 vertex : POSITION;" + "\n" +
			"float2 uv : TEXCOORD0;" + "\n" +
			"};" + "\n" +

			"uniform fixed4     fragColor;" + "\n" +
			"uniform fixed      iChannelTime[4];" + "// channel playback time (in seconds)" + "\n" +
			"uniform fixed3     iChannelResolution[4];" + "// channel resolution (in pixels)" + "\n" +
			"uniform fixed4     iMouse;" +  "// mouse pixel coords. xy: current (if MLB down), zw: click" + "\n" +
			"uniform fixed4     iDate;"  +  "// (year, month, day, time in seconds)" + "\n" +
			"uniform fixed      iSampleRate;" + "// sound sample rate (i.e., 44100)" + "\n" +
			Variables + "\n" +

			"struct v2f" + "\n" +
			"{" + "\n" +
			"float2 uv : TEXCOORD0;" + "\n" +
			"float4 vertex : SV_POSITION;" + "\n" +
			"float4 screenCoord : TEXCOORD1;" + "\n" +
			"};" + "\n" + "\n" +

			"v2f vert(appdata v)" + "\n" +
			"{" + "\n" +
			"v2f o;" + "\n" +
			"o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);" + "\n" +
			"o.uv = v.uv;" + "\n" +
			"o.screenCoord.xy = ComputeScreenPos(o.vertex);" + "\n" +
			"return o;" + "\n" + "}" + "\n" +

			Func +


			"fixed4 frag(v2f i) : SV_Target{" + "\n" +
			Frag + "\n" + "}" +
			"ENDCG" + "\n" +
			"}" + "\n" +
			"}" + "\n" +
			"}" + "\n"
			;


		Result = code;



		//Result.AppendText("\n" + "}");

		Reset();
	}

	private string defineProperty(string input)
	{
		string Properties = "";
		if (input.Contains("iChannel0"))
		{
			Properties += @"_MainTex" + "(" + "\"_MainTex\"" + ", 2D) = " + "\"white\"" + "{}";
			Properties += "\n";
			print (Properties);
		}

		if (input.Contains("iChannel1"))
		{
			Properties += @"_SecondTex" + "(" + "\"SecondTex\"" + ", 2D) = " + "\"white\"" + "{}";
			Properties += "\n";
			print (Properties);
		}

		if (input.Contains("iChannel2"))
		{
			Properties += @"_ThirdTex" + "(" + "\"ThirdTex\"" + ", 2D) = " + "\"white\"" + "{}";
			Properties += "\n";
		}

		if (input.Contains("iMouse"))
		{
			Properties += @"_iMouse" + "(" + "\"iMouse\"" + ", Vector) = (0,0,0,0)";
		}
		if (input.Contains("iFrame"))
		{
			Properties += @"iFrame" + "(" + "\"iFrame\"" + ", Range(0,100)) = 1";
		}


		return Properties;
	}


	private string defineVariable(string frag)
	{
		string Properties = "";

		if (frag.Contains("_MainTex"))
		{
			Properties += "sampler2D _MainTex;" + "\n";
		}
		if (frag.Contains("_SecondTex"))
		{
			Properties += "sampler2D _SecondTex;" + "\n";
		}
		if (frag.Contains("_ThirdTex"))
		{
			Properties += "sampler2D _ThirdTex;" + "\n";
		}
		if (frag.Contains("iMouse"))
		{
			Properties += "float4 _iMouse;" + "\n";
		}
		if (frag.Contains("iFrame"))
		{
			Properties += "fixed iFrame;" + "\n";
		}

		return Properties;
	}

	string Translator(string Input)
	{

		// output += @"Shader" + "ShaderToyConverter / MyShader{";
		Input = Regex.Replace(Input, "vec|half|float", "fixed");
		Input = Regex.Replace(Input, "mix", "lerp");
		Input = Regex.Replace(Input, "iGlobalTime", "_Time.y");
		Input = Regex.Replace(Input, @"fragColor\s*=", "return ");
		Input = Regex.Replace(Input, "fract", "frac");
		Input = Regex.Replace(Input, "texture(2D)?", "tex2D");
		Input = Regex.Replace(Input, "tex2DLod", "tex2Dlod");
		Input = Regex.Replace(Input, "iChannel0", "_MainTex");
		Input = Regex.Replace(Input, "iChannel1", "_SecondTex");
		Input = Regex.Replace(Input, "iChannel2", "_ThirdTex");
		Input = Regex.Replace(Input, "iChannel3", "_FourthTex");
		//Input = Regex.Replace(Input, "fragCoord", "i.vertex");

		Input = Regex.Replace(Input, @"iResolution(\.(x|y){1,2})?", "1");
		//Input = Regex.Replace(Input, "iResolution", "_ScreenParams"); Hey you can use this


		Input = Regex.Replace(Input, "iMouse", "_iMouse");
		Input = Regex.Replace(Input, "mat2", "fixed2x2");
		Input = Regex.Replace(Input, "mat3", "fixed3x3");
		Input = Regex.Replace(Input, "mat4", "fixed4x4");


		//Input = Regex.Replace(Input, @"(m)\*(p)", "mul($1,$2)");
		Input = Regex.Replace(Input, "mod", "fmod");
		Input = Regex.Replace(Input, @"for\(", "[unroll(100)]\nfor(");
		Input = Regex.Replace(Input, "iTime", "_Time.y");

		//Input = Regex.Replace(Input, @"(tex2Dlod\()([^,]+\,)([^)]+(?=\)))", "$1$2float4($3,0)");
		Input = Regex.Replace(Input, @"(tex2Dlod\()([^,]+\,)([^)]+\)?[)]+.+(?=\)))", "$1$2float4($3,0)");
		Input = Regex.Replace(Input, @"fixed4\(([^(,]+?)\)", "fixed4($1,$1,$1,$1)");
		Input = Regex.Replace(Input, @"fixed3\(([^(,]+?)\)", "fixed3($1,$1,$1)");
		Input = Regex.Replace(Input, @"fixed2\(([^(,]+?)\)", "fixed2($1,$1)");

		//Input = Regex.Replace(Input, @"(tex2D\([^,]+\,)([^,]+)(.+)(\))", "$1$2$4)");

		//Input = Regex.Replace(Input, @"fixed3\(([^,()]+)\,([^,)]+)\)", "fixed3($1,$2,0");//if have two fix it

		//Input = Regex.Replace(Input, @"#.+",""); //Prevent #if endif
		Input = Regex.Replace(Input, @"texelFetch","tex2D");//badan bokonesh texlod
		Input = Regex.Replace(Input, @"atan\(([^,]+?)\,([^,]+?)\)","atan2($2,$1)");//badan bokonesh texlod
		Input = Regex.Replace(Input, @"(void\s+mainImage[^{]+\{)((.+?)(\}))?","$2",RegexOptions.Singleline | RegexOptions.Multiline);
		Input = Regex.Replace(Input, "([*+\\/-])\\s*(pi|PI)", "$13.14159265359");

		Input = Regex.Replace(Input, "gl_FragCoord", "((i.screenCoord.xy/i.screenCoord.w)*_ScreenParams.xy)");
		Input = Regex.Replace(Input, @"(m)\*(p[^, *]+)", "mul($1,$2)",RegexOptions.Multiline);//v*mat3
		//Input = Regex.Replace(Input, @"([^=;\n]+)(\*=)\s*([^;]+)", "$1 = mul($1,$3)",RegexOptions.Multiline);//mul for *=
		Input = Regex.Replace(Input, @"([^ ])\*(fixed[0-9]x[0-9][^;]+)(?=\))", "mul($1,$2)");//v*mat3


		Input = Regex.Replace(Input, "varying", "uniform");



		Input = Regex.Replace(Input, "dFdx", "ddx");
		Input = Regex.Replace(Input, "dFdxCoarse", "ddx_coarse");
		Input = Regex.Replace(Input, "dFdy", "ddy");
		Input = Regex.Replace(Input, "dFdyCoarse", "ddy_coarse");
		Input = Regex.Replace(Input, "dFdxFine", "ddx_fine");
		Input = Regex.Replace(Input, "dFdyFine", "ddy_fine");
		Input = Regex.Replace(Input, "dFdxFine", "ddx_fine");
		Input = Regex.Replace(Input, "fma", "mad");







		//Input = Regex.Replace(Input, @"textureLod.+(?=\,).+(\,.+)\)",@"$0");



		return Input;
	}

	
}
