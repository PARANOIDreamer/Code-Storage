// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "fire"
{
	Properties
	{
		_ClipMin("ClipMin", Range( 0 , 1)) = 0.1
		_Shape("Shape", 2D) = "white" {}
		_FadeMap("Fade Map", 2D) = "white" {}
		_Nosie("Nosie", 2D) = "white" {}
		_Speed("Speed", Vector) = (0,0,0,0)
		_BaseColor("BaseColor", Color) = (0,0,0,0)
		_FireColor("FireColor", Range( 0 , 1)) = 0
		_Bightness("Bightness", Range( 1 , 5)) = 1
		_ColorRange("ColorRange", Range( 0 , 5)) = 1
		_Offset("Offset", Range( 0 , 0.5)) = 0
		_ShapePow("ShapePow", Range( 1 , 3)) = 1
		_ShapeInensity("ShapeInensity", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform float4 _BaseColor;
		uniform float _Bightness;
		uniform float _FireColor;
		uniform sampler2D _FadeMap;
		uniform float4 _FadeMap_ST;
		uniform float _ColorRange;
		uniform sampler2D _Nosie;
		uniform float2 _Speed;
		uniform float4 _Nosie_ST;
		uniform float _ClipMin;
		uniform float _ShapeInensity;
		uniform sampler2D _Shape;
		uniform float _Offset;
		uniform float4 _Shape_ST;
		uniform float _ShapePow;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float4 break22 = ( _BaseColor * _Bightness );
			float2 uv_FadeMap = i.uv_texcoord * _FadeMap_ST.xy + _FadeMap_ST.zw;
			float4 tex2DNode9 = tex2D( _FadeMap, uv_FadeMap );
			float temp_output_29_0 = ( ( 1.0 - tex2DNode9.r ) * _ColorRange );
			float2 uv_Nosie = i.uv_texcoord * _Nosie_ST.xy + _Nosie_ST.zw;
			float2 panner7 = ( 1.0 * _Time.y * _Speed + uv_Nosie);
			float4 tex2DNode5 = tex2D( _Nosie, panner7 );
			float4 appendResult23 = (float4(break22.r , ( break22.g + ( _FireColor * temp_output_29_0 * tex2DNode5.r ) ) , break22.b , 0.0));
			o.Emission = appendResult23.xyz;
			float clampResult15 = clamp( ( tex2DNode5.r - _ClipMin ) , 0.0 , 1.0 );
			float smoothstepResult10 = smoothstep( clampResult15 , tex2DNode5.r , tex2DNode9.r);
			float2 uv_Shape = i.uv_texcoord * _Shape_ST.xy + _Shape_ST.zw;
			float2 appendResult38 = (float2(( ( temp_output_29_0 * (tex2DNode5.r*2.0 + -1.0) * _Offset ) + uv_Shape ).x , uv_Shape.y));
			o.Alpha = ( smoothstepResult10 * ( _ShapeInensity * pow( tex2D( _Shape, appendResult38 ).r , _ShapePow ) ) );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit alpha:fade keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				SurfaceOutput o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutput, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18500
298;233;1039;546;1254.775;320.5536;1.366346;True;False
Node;AmplifyShaderEditor.TextureCoordinatesNode;28;-1956.669,175.8012;Inherit;False;0;9;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;6;-1933.178,487.5495;Inherit;False;0;5;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;8;-1863.405,609.4044;Inherit;False;Property;_Speed;Speed;4;0;Create;True;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;9;-1621.098,153.707;Inherit;True;Property;_FadeMap;Fade Map;2;0;Create;True;0;0;False;0;False;-1;2b089ed9a4c06924f9d3b087adc575fb;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;7;-1645.975,491.4818;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;27;-1142.13,151.0737;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;30;-1266.306,246.2996;Inherit;False;Property;_ColorRange;ColorRange;8;0;Create;True;0;0;False;0;False;1;0;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;5;-1442.056,455.1693;Inherit;True;Property;_Nosie;Nosie;3;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;39;-1055.553,613.4468;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-1203.936,733.065;Inherit;False;Property;_Offset;Offset;9;0;Create;True;0;0;False;0;False;0;0;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-929.2827,147.2383;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-770.4588,587.5804;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;34;-824.7539,713.563;Inherit;False;0;32;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;35;-579.28,598.4396;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;38;-421.1634,600.6018;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-1539.391,69.40502;Inherit;False;Property;_Bightness;Bightness;7;0;Create;True;0;0;False;0;False;1;0;1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;-1461.083,644.9555;Inherit;False;Property;_ClipMin;ClipMin;0;0;Create;True;0;0;False;0;False;0.1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;11;-1460.747,-97.33072;Inherit;False;Property;_BaseColor;BaseColor;5;0;Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;32;-265.4523,566.0689;Inherit;True;Property;_Shape;Shape;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;25;-1072.229,78.15833;Inherit;False;Property;_FireColor;FireColor;6;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;19;-1136.095,-90.76292;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;41;-244.3622,760.7842;Inherit;False;Property;_ShapePow;ShapePow;10;0;Create;True;0;0;False;0;False;1;1;1;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;12;-960.3356,478.7332;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;22;-928.1108,-85.97204;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-720.4785,114.566;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;15;-718.7952,467.3348;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;-3.082642,346.449;Inherit;False;Property;_ShapeInensity;ShapeInensity;11;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;42;90.63197,588.1923;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-507.2162,11.5064;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;10;-354.7679,190.7566;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;40;279.3747,354.3747;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;492.4546,134.2913;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;23;-255.1761,-85.33737;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;2;749.104,-63.07082;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;fire;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;9;1;28;0
WireConnection;7;0;6;0
WireConnection;7;2;8;0
WireConnection;27;0;9;1
WireConnection;5;1;7;0
WireConnection;39;0;5;1
WireConnection;29;0;27;0
WireConnection;29;1;30;0
WireConnection;36;0;29;0
WireConnection;36;1;39;0
WireConnection;36;2;37;0
WireConnection;35;0;36;0
WireConnection;35;1;34;0
WireConnection;38;0;35;0
WireConnection;38;1;34;2
WireConnection;32;1;38;0
WireConnection;19;0;11;0
WireConnection;19;1;20;0
WireConnection;12;0;5;1
WireConnection;12;1;13;0
WireConnection;22;0;19;0
WireConnection;26;0;25;0
WireConnection;26;1;29;0
WireConnection;26;2;5;1
WireConnection;15;0;12;0
WireConnection;42;0;32;1
WireConnection;42;1;41;0
WireConnection;24;0;22;1
WireConnection;24;1;26;0
WireConnection;10;0;9;1
WireConnection;10;1;15;0
WireConnection;10;2;5;1
WireConnection;40;0;43;0
WireConnection;40;1;42;0
WireConnection;33;0;10;0
WireConnection;33;1;40;0
WireConnection;23;0;22;0
WireConnection;23;1;24;0
WireConnection;23;2;22;2
WireConnection;2;2;23;0
WireConnection;2;9;33;0
ASEEND*/
//CHKSM=F5B0919AF8DF454B0A0A4932C0170EF7ED5BB9AA