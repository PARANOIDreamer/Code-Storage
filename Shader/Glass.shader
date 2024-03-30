// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Glass"
{
	Properties
	{
		_MatcapMap("Matcap Map", 2D) = "white" {}
		_RefractMatcapMap("Refract-Matcap Map", 2D) = "white" {}
		_RefractIntensity("Refract Intensity", Float) = 1
		_RefractColor("Refract Color", Color) = (0,0,0,0)
		_DetailTex("Detail Tex", 2D) = "black" {}
		_ThicknessMap("Thickness Map", 2D) = "white" {}
		_Thickrange("Thick range", Float) = 1
		_Thickoffset("Thick offset", Float) = 0
		_ThickMin("Thick Min", Float) = 0
		_ThickMax("Thick Max", Float) = 0
		_DirtyMask("Dirty Mask", 2D) = "black" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Pass
		{
			ColorMask 0
			ZWrite On
		}

		Tags{ "RenderType" = "Custom"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			float2 uv_texcoord;
			float3 viewDir;
		};

		uniform sampler2D _MatcapMap;
		uniform sampler2D _DetailTex;
		uniform float4 _DetailTex_ST;
		uniform float4 _RefractColor;
		uniform sampler2D _RefractMatcapMap;
		uniform float _ThickMin;
		uniform float _ThickMax;
		uniform sampler2D _DirtyMask;
		uniform float4 _DirtyMask_ST;
		uniform sampler2D _ThicknessMap;
		uniform float _Thickoffset;
		uniform float _Thickrange;
		uniform float _RefractIntensity;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float3 objToView10 = mul( UNITY_MATRIX_MV, float4( ase_vertex3Pos, 1 ) ).xyz;
			float3 normalizeResult11 = normalize( objToView10 );
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float3 worldToViewDir7 = normalize( mul( UNITY_MATRIX_V, float4( ase_normWorldNormal, 0 ) ).xyz );
			float3 break13 = cross( normalizeResult11 , worldToViewDir7 );
			float2 appendResult14 = (float2(-break13.y , break13.x));
			float2 MatcapUV8 = (appendResult14*0.5 + 0.5);
			float4 tex2DNode1 = tex2D( _MatcapMap, MatcapUV8 );
			float2 uv_DetailTex = i.uv_texcoord * _DetailTex_ST.xy + _DetailTex_ST.zw;
			float4 tex2DNode56 = tex2D( _DetailTex, uv_DetailTex );
			float4 lerpResult57 = lerp( tex2DNode1 , tex2DNode56 , tex2DNode56.a);
			float dotResult21 = dot( i.viewDir , ase_normWorldNormal );
			float smoothstepResult22 = smoothstep( _ThickMin , _ThickMax , dotResult21);
			float2 uv_DirtyMask = i.uv_texcoord * _DirtyMask_ST.xy + _DirtyMask_ST.zw;
			float3 ase_worldPos = i.worldPos;
			float3 objToWorld40 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float2 appendResult43 = (float2(0.5 , ( ( ( ase_worldPos.y - objToWorld40.y ) - _Thickoffset ) / _Thickrange )));
			float clampResult53 = clamp( ( ( 1.0 - smoothstepResult22 ) + tex2D( _DirtyMask, uv_DirtyMask ).a + tex2D( _ThicknessMap, appendResult43 ).r ) , 0.0 , 1.0 );
			float Thick32 = clampResult53;
			float temp_output_24_0 = ( Thick32 * _RefractIntensity );
			float4 lerpResult37 = lerp( ( _RefractColor * 0.5 ) , ( _RefractColor * tex2D( _RefractMatcapMap, ( temp_output_24_0 + MatcapUV8 ) ) ) , temp_output_24_0);
			o.Emission = ( lerpResult57 + lerpResult37 ).rgb;
			float clampResult30 = clamp( ( tex2DNode56.a + max( tex2DNode1.r , Thick32 ) ) , 0.0 , 1.0 );
			o.Alpha = clampResult30;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows 

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
				float3 worldNormal : TEXCOORD3;
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
				o.worldNormal = worldNormal;
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
				surfIN.viewDir = worldViewDir;
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
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
7;382;1113;523;2219.832;313.4141;2.306075;True;False
Node;AmplifyShaderEditor.CommentaryNode;33;-3758.077,134.8032;Inherit;False;1988.426;700.218;Comment;20;40;39;38;32;23;22;21;20;19;41;42;43;46;47;45;51;44;53;55;54;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;31;-3758.456,-435.9764;Inherit;False;2011.495;541.0831;Comment;11;9;2;10;7;11;12;13;15;14;6;8;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TransformPositionNode;40;-3717.573,677.8754;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;39;-3683.798,535.2682;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;9;-3708.456,-373.4404;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;46;-3466.137,679.1002;Inherit;False;Property;_Thickoffset;Thick offset;8;0;Create;True;0;0;False;0;False;0;-0.01;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;41;-3452.117,578.0763;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;2;-3509.224,-221.1314;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;10;-3477.411,-380.1374;Inherit;False;Object;View;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode;44;-3342.57,589.5549;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;20;-3351.975,175.8026;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;47;-3290.459,679.8925;Inherit;False;Property;_Thickrange;Thick range;7;0;Create;True;0;0;False;0;False;1;0.355;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;19;-3357.905,326.0272;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;11;-3208.164,-376.9529;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-3130.37,422.0964;Inherit;False;Property;_ThickMax;Thick Max;10;0;Create;True;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;54;-3148.574,348.0631;Inherit;False;Property;_ThickMin;Thick Min;9;0;Create;True;0;0;False;0;False;0;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;21;-3108.849,246.9616;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;45;-3101.968,580.2462;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;7;-3255.183,-225.4052;Inherit;False;World;View;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CrossProductOpNode;12;-3027.97,-337.2087;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;22;-2966.531,246.9617;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;43;-2948.325,559.1243;Inherit;False;FLOAT2;4;0;FLOAT;0.5;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;23;-2770.844,244.9851;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;38;-2802.989,534.758;Inherit;True;Property;_ThicknessMap;Thickness Map;6;0;Create;True;0;0;False;0;False;-1;None;49c7ae4d7067d57419c6a7c6f807873d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;13;-2831.607,-334.5157;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SamplerNode;51;-2805.524,336.5425;Inherit;True;Property;_DirtyMask;Dirty Mask;11;0;Create;True;0;0;False;0;False;-1;72c1b9a0024691a4296590b9a6d29acb;72c1b9a0024691a4296590b9a6d29acb;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;42;-2388.025,351.056;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;15;-2572.948,-385.9764;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;53;-2213.066,347.8804;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;14;-2431.43,-358.2144;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;32;-1970.762,340.2673;Inherit;False;Thick;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;6;-2246.209,-250.5069;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;8;-1989.961,-253.1702;Inherit;False;MatcapUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-1644.601,379.1889;Inherit;False;Property;_RefractIntensity;Refract Intensity;3;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;34;-1615.319,301.4001;Inherit;False;32;Thick;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-1418.524,326.5364;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;18;-1462.052,451.7532;Inherit;False;8;MatcapUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-1246.245,417.2246;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;16;-953.5685,11.28981;Inherit;False;8;MatcapUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;50;-915.1177,311.024;Inherit;False;Constant;_Float0;Float 0;7;0;Create;True;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;35;-603.3891,188.0136;Inherit;False;32;Thick;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;36;-1108.273,223.9732;Inherit;False;Property;_RefractColor;Refract Color;4;0;Create;True;0;0;False;0;False;0,0,0,0;0.4044118,0.4044118,0.4044118,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;1;-737.9976,-12.95082;Inherit;True;Property;_MatcapMap;Matcap Map;1;0;Create;True;0;0;False;0;False;-1;None;df6658d1078ac9a42bb65de11d8e3bde;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;17;-1112.831,394.1655;Inherit;True;Property;_RefractMatcapMap;Refract-Matcap Map;2;0;Create;True;0;0;False;0;False;-1;None;9541f5c4f8b50ec4bb83bef355f841be;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;56;-739.593,-217.341;Inherit;True;Property;_DetailTex;Detail Tex;5;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMaxOpNode;29;-381.6364,151.0628;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-727.2564,238.7697;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-727.1392,373.219;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;58;-238.7832,101.7919;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;37;-531.4017,273.7935;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;57;-311.278,-110.8766;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;30;-81.00623,180.0457;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;-108.1996,39.67748;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;83,-5;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;Glass;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;True;0;Custom;0.5;True;True;0;True;Custom;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;41;0;39;2
WireConnection;41;1;40;2
WireConnection;10;0;9;0
WireConnection;44;0;41;0
WireConnection;44;1;46;0
WireConnection;11;0;10;0
WireConnection;21;0;20;0
WireConnection;21;1;19;0
WireConnection;45;0;44;0
WireConnection;45;1;47;0
WireConnection;7;0;2;0
WireConnection;12;0;11;0
WireConnection;12;1;7;0
WireConnection;22;0;21;0
WireConnection;22;1;54;0
WireConnection;22;2;55;0
WireConnection;43;1;45;0
WireConnection;23;0;22;0
WireConnection;38;1;43;0
WireConnection;13;0;12;0
WireConnection;42;0;23;0
WireConnection;42;1;51;4
WireConnection;42;2;38;1
WireConnection;15;0;13;1
WireConnection;53;0;42;0
WireConnection;14;0;15;0
WireConnection;14;1;13;0
WireConnection;32;0;53;0
WireConnection;6;0;14;0
WireConnection;8;0;6;0
WireConnection;24;0;34;0
WireConnection;24;1;25;0
WireConnection;26;0;24;0
WireConnection;26;1;18;0
WireConnection;1;1;16;0
WireConnection;17;1;26;0
WireConnection;29;0;1;1
WireConnection;29;1;35;0
WireConnection;49;0;36;0
WireConnection;49;1;50;0
WireConnection;48;0;36;0
WireConnection;48;1;17;0
WireConnection;58;0;56;4
WireConnection;58;1;29;0
WireConnection;37;0;49;0
WireConnection;37;1;48;0
WireConnection;37;2;24;0
WireConnection;57;0;1;0
WireConnection;57;1;56;0
WireConnection;57;2;56;4
WireConnection;30;0;58;0
WireConnection;27;0;57;0
WireConnection;27;1;37;0
WireConnection;0;2;27;0
WireConnection;0;9;30;0
ASEEND*/
//CHKSM=DC6E116D8A2B987BDDDCBE1D92217A9303AE8655