using UnityEngine;
using UnityEditor;
using System.IO;
using System;

[IODescriptionAttribute("FileSystemWatcherDesc")]
// Simple script that creates a new non-dockable window
public class ShaderConverterEditor : EditorWindow
{
	bool convert;
	public string shaderName = "MyShader";
	string text = "Give Me ShaderToy :D";
	public string path;
	bool Replace;
    TextAsset txtAsset,newTxtAsset;

	//public enum GameEngine {ShaderToy, GameMaker, Construct};
	//public GameEngine gameEngine;
	Vector2 scroll;
	[MenuItem("Window/ShaderMan")]
	static void Initialize()
	{
		if (GameObject.Find ("CodeGenerator") == null) {
			GameObject obj = new GameObject ();
			obj.name = "CodeGenerator";
			obj.AddComponent<CodeGenerator> ();
		}
		ShaderConverterEditor window = (ShaderConverterEditor)EditorWindow.GetWindow (typeof(ShaderConverterEditor), true, "ShaderMan v.2.0");
		window.maxSize = new Vector2 (718, 520);
		window.minSize = new Vector2 (718, 520);

		window.wantsMouseMove = true;
	}

	void OnGUI () {
		GUILayout.BeginArea (new Rect (10,10,700,500)); // you only need to do this once unless you want to show the same window twice
		shaderName = EditorGUILayout.TextField(shaderName);


		scroll = EditorGUILayout.BeginScrollView(scroll);
		
		text = EditorGUILayout.TextArea(text, GUILayout.Height(position.height - 80));
		EditorGUILayout.EndScrollView();

		


		if(GUILayout.Button("Convert"))
		{
			Debug.Log("Build");
			CreateShader ();

		}
		GUI.skin.label.fontSize = 100;
		if(GUILayout.Button("About me"))
		{
			Debug.Log("Created By Seyed Mortaza Kamaly");
			EditorUtility.DisplayDialog ("Converter",
				@"Created By Seyed Mortaza Kamaly"


				, "Ok");

		}

		GUILayout.EndArea ();

		GUILayout.BeginArea (new Rect (800,10,800,600)); // you only need to do this once unless you want to show the same window twice
		//myString = EditorGUILayout.TextField ("Text Field", myString);        
		//EditorGUILayout.EnumPopup (gameEngine);

		//EditorGUILayout.EndToggleGroup ();
		GUILayout.EndArea ();
	}


	void CreateShader(){
		string path = "Assets/ShaderToy/";
		var  fileName = shaderName + ".shader";
		if(!Directory.Exists(path))
			Directory.CreateDirectory(path);



		if (File.Exists (path + fileName)) {
			Debug.Log (fileName + " Already exists.");
			Replace = EditorUtility.DisplayDialog ("What am I doing?",
				               "There is already a file the same name in this location.Do you want to replace?"
				, "Replace", "Do Not Replace");

			if (!Replace) {
				
				return;
			}
		}

		if (CodeGenerator.instance != null || Replace) {
			var sr = File.CreateText (path + fileName);

			sr.WriteLine ("");
			CodeGenerator.instance.ShaderName = shaderName;
			sr.WriteLine (CodeGenerator.instance.Convert (text));
			sr.Close ();
		}

		AssetDatabase.Refresh ();

		// Create a simple material asset
		//string shaderfullpath = path + fileName + shaderName;
		var material = new Material (Shader.Find("ShaderMan/" + shaderName));
		AssetDatabase.CreateAsset(material, path + shaderName + ".mat");
	}
}