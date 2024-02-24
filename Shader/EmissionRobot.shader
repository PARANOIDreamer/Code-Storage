// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "EmissionRobot"
{
	Properties
	{
		[HDR]_MainColor("MainColor", Color) = (0,0,0,0)
		_NormalMap("Normal Map", 2D) = "bump" {}
		_OffsetTilling("OffsetTilling", Float) = 3
		_Line("Line", 2D) = "white" {}
		_LineIntensity("Line Intensity", Float) = 1
		_Flash("Flash", Range( 0 , 1)) = 0.5
		_RimPower("Rim Power", Float) = 2
		_RamScale("Ram Scale", Float) = 1
		_RimBias("Rim Bias", Float) = 0
		_Scan("Scan", 2D) = "white" {}
		_ScanAdd("ScanAdd", 2D) = "white" {}
		[HDR]_ScanColor("Scan Color", Color) = (0.07843137,1.529412,5,0)
		_ScanFreq("ScanFreq", Float) = 2
		_ScanSpeed("ScanSpeed", Float) = 1
		_ScanHardness("ScanHardness", Float) = 1
		_ScanWidth("ScanWidth", Float) = 0
		_ScanAphla("ScanAphla", Float) = 1
		_ScanFreqAdd("ScanFreqAdd", Float) = 2
		_ScanSpeedAdd("ScanSpeedAdd", Float) = 1
		_ScanHardnessAdd("ScanHardnessAdd", Float) = 1
		_ScanAphlaAdd("ScanAphlaAdd", Float) = 1
		_ScanVertexOffset("ScanVertexOffset", Vector) = (0,0,0,0)
		_VertexOffset("VertexOffset", Vector) = (0,0,0,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha
		
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldPos;
			float vertexToFrag98;
			float3 worldNormal;
			INTERNAL_DATA
			float2 uv_texcoord;
		};

		uniform float3 _ScanVertexOffset;
		uniform sampler2D _Scan;
		uniform float _ScanFreq;
		uniform float _ScanSpeed;
		uniform float _ScanWidth;
		uniform float _ScanHardness;
		uniform float3 _VertexOffset;
		uniform float _OffsetTilling;
		uniform float _Flash;
		uniform float4 _MainColor;
		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform float _RimBias;
		uniform float _RamScale;
		uniform float _RimPower;
		uniform sampler2D _ScanAdd;
		uniform float _ScanFreqAdd;
		uniform float _ScanSpeedAdd;
		uniform float _ScanHardnessAdd;
		uniform float4 _ScanColor;
		uniform float _ScanAphla;
		uniform float _ScanAphlaAdd;
		uniform sampler2D _Line;
		uniform float4 _Line_ST;
		uniform float _LineIntensity;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 viewToObjDir95 = mul( UNITY_MATRIX_T_MV, float4( _ScanVertexOffset, 0 ) ).xyz;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 objToWorld2_g3 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime7_g3 = _Time.y * _ScanSpeed;
			float2 appendResult9_g3 = (float2(0.5 , (( ase_worldPos.y - objToWorld2_g3.y )*_ScanFreq + mulTime7_g3)));
			float clampResult23_g3 = clamp( ( ( tex2Dlod( _Scan, float4( appendResult9_g3, 0, 0.0) ).r - _ScanWidth ) * _ScanHardness ) , 0.0 , 1.0 );
			float temp_output_33_0 = clampResult23_g3;
			float3 viewToObjDir74 = mul( UNITY_MATRIX_T_MV, float4( _VertexOffset, 0 ) ).xyz;
			float3 ase_worldNormal = UnityObjectToWorldNormal( v.normal );
			float mulTime69 = _Time.y * -2.5;
			float mulTime66 = _Time.y * -2.0;
			float2 appendResult65 = (float2((ase_worldNormal.y*_OffsetTilling + mulTime69) , mulTime66));
			float simplePerlin2D64 = snoise( appendResult65 );
			simplePerlin2D64 = simplePerlin2D64*0.5 + 0.5;
			float3 objToWorld79 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime80 = _Time.y * -5.0;
			float mulTime84 = _Time.y * -1.0;
			float2 appendResult85 = (float2((( objToWorld79.x + objToWorld79.y + objToWorld79.z )*200.0 + mulTime80) , mulTime84));
			float simplePerlin2D86 = snoise( appendResult85 );
			simplePerlin2D86 = simplePerlin2D86*0.5 + 0.5;
			float clampResult90 = clamp( (simplePerlin2D86*2.0 + -1.0) , 0.0 , 1.0 );
			float3 VertexOffset77 = ( ( ( viewToObjDir95 * 0.01 ) * temp_output_33_0 ) + ( ( viewToObjDir74 * 0.01 ) * ( (simplePerlin2D64*2.0 + -1.0) * clampResult90 ) ) );
			v.vertex.xyz += VertexOffset77;
			v.vertex.w = 1;
			float3 objToWorld14 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime9 = _Time.y * 10.0;
			float mulTime11 = _Time.y * 0.5;
			float2 appendResult10 = (float2((( objToWorld14.x + objToWorld14.y + objToWorld14.z )*200.0 + mulTime9) , mulTime11));
			float simplePerlin2D3 = snoise( appendResult10 );
			simplePerlin2D3 = simplePerlin2D3*0.5 + 0.5;
			float lerpResult15 = lerp( 1.0 , simplePerlin2D3 , _Flash);
			o.vertexToFrag98 = lerpResult15;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			o.Normal = float3(0,0,1);
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float fresnelNdotV17 = dot( (WorldNormalVector( i , UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) ) )), ase_worldViewDir );
			float fresnelNode17 = ( _RimBias + _RamScale * pow( 1.0 - fresnelNdotV17, _RimPower ) );
			float temp_output_32_0 = max( fresnelNode17 , 0.0 );
			float3 objToWorld2_g3 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime7_g3 = _Time.y * _ScanSpeed;
			float2 appendResult9_g3 = (float2(0.5 , (( ase_worldPos.y - objToWorld2_g3.y )*_ScanFreq + mulTime7_g3)));
			float clampResult23_g3 = clamp( ( ( tex2D( _Scan, appendResult9_g3 ).r - _ScanWidth ) * _ScanHardness ) , 0.0 , 1.0 );
			float temp_output_33_0 = clampResult23_g3;
			float3 objToWorld2_g4 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float mulTime7_g4 = _Time.y * _ScanSpeedAdd;
			float2 appendResult9_g4 = (float2(0.5 , (( ase_worldPos.y - objToWorld2_g4.y )*_ScanFreqAdd + mulTime7_g4)));
			float clampResult23_g4 = clamp( ( ( tex2D( _ScanAdd, appendResult9_g4 ).r - 0.0 ) * _ScanHardnessAdd ) , 0.0 , 1.0 );
			float temp_output_46_0 = clampResult23_g4;
			float4 ScanColor56 = ( ( temp_output_33_0 * temp_output_46_0 ) * _ScanColor );
			o.Emission = ( i.vertexToFrag98 * ( _MainColor + ( _MainColor * temp_output_32_0 ) + max( ScanColor56 , float4( 0,0,0,0 ) ) ) ).rgb;
			float temp_output_44_0 = ( temp_output_46_0 * _ScanAphlaAdd );
			float ScanAphla55 = ( ( ( temp_output_33_0 * _ScanAphla ) * temp_output_44_0 ) + temp_output_44_0 );
			float clampResult27 = clamp( ( _MainColor.a + temp_output_32_0 + ScanAphla55 ) , 0.0 , 1.0 );
			float2 uv_Line = i.uv_texcoord * _Line_ST.xy + _Line_ST.zw;
			o.Alpha = ( clampResult27 * ( tex2D( _Line, uv_Line ).r * _LineIntensity ) );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Unlit keepalpha fullforwardshadows vertex:vertexDataFunc 

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
				float3 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
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
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.x = customInputData.vertexToFrag98;
				o.customPack1.yz = customInputData.uv_texcoord;
				o.customPack1.yz = v.texcoord;
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
				surfIN.vertexToFrag98 = IN.customPack1.x;
				surfIN.uv_texcoord = IN.customPack1.yz;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
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
-122;425;1693;812;1329.468;171.8552;1.184111;True;False
Node;AmplifyShaderEditor.TransformPositionNode;79;-2922.682,1199.498;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;82;-2682.682,1343.498;Inherit;False;Constant;_Tilling1;Tilling;1;0;Create;True;0;0;False;0;False;200;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;81;-2650.682,1231.498;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;80;-2682.682,1423.498;Inherit;False;1;0;FLOAT;-5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;83;-2458.682,1263.498;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;84;-2426.682,1391.498;Inherit;False;1;0;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;35;-3074.515,-57.87432;Inherit;True;Property;_Scan;Scan;10;0;Create;True;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleTimeNode;69;-2513.388,1181.126;Inherit;False;1;0;FLOAT;-2.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;70;-2529.388,973.1255;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;39;-3043.315,352.1427;Inherit;False;Property;_ScanHardness;ScanHardness;15;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;68;-2513.388,1101.126;Inherit;False;Property;_OffsetTilling;OffsetTilling;3;0;Create;True;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;37;-3010.315,204.1427;Inherit;False;Property;_ScanSpeed;ScanSpeed;14;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-3011.542,699.0748;Inherit;False;Property;_ScanSpeedAdd;ScanSpeedAdd;19;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-3014.542,627.075;Inherit;False;Property;_ScanFreqAdd;ScanFreqAdd;18;0;Create;True;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-3044.542,846.0752;Inherit;False;Property;_ScanHardnessAdd;ScanHardnessAdd;20;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;38;-3016.315,279.1426;Inherit;False;Property;_ScanWidth;ScanWidth;16;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;49;-3017.542,775.0752;Inherit;False;Constant;_ScanWidthAdd;ScanWidthAdd;18;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;51;-3075.742,438.475;Inherit;True;Property;_ScanAdd;ScanAdd;11;0;Create;True;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;36;-3013.315,131.1427;Inherit;False;Property;_ScanFreq;ScanFreq;13;0;Create;True;0;0;False;0;False;2;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;85;-2234.682,1263.498;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode;66;-2257.388,1149.126;Inherit;False;1;0;FLOAT;-2;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;67;-2273.388,1021.126;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-2625.069,314.4823;Inherit;False;Property;_ScanAphla;ScanAphla;17;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;33;-2771.137,51.65179;Inherit;False;Scanline;-1;;3;f2c2adcdf9e91844b9fbbfc2c3f5bafb;0;6;20;SAMPLER2D;0;False;16;FLOAT;0;False;18;FLOAT;2;False;19;FLOAT;1;False;21;FLOAT;0;False;22;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;46;-2772.364,547.5842;Inherit;False;Scanline;-1;;4;f2c2adcdf9e91844b9fbbfc2c3f5bafb;0;6;20;SAMPLER2D;0;False;16;FLOAT;0;False;18;FLOAT;2;False;19;FLOAT;1;False;21;FLOAT;0;False;22;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;50;-2636.242,765.1736;Inherit;False;Property;_ScanAphlaAdd;ScanAphlaAdd;21;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;86;-2090.682,1263.498;Inherit;False;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;14;-1522.363,-189.0901;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;65;-2065.389,1037.126;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;-2367.215,602.777;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-2342.488,309.6799;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;40;-2182.914,131.5427;Inherit;False;Property;_ScanColor;Scan Color;12;1;[HDR];Create;True;0;0;False;0;False;0.07843137,1.529412,5,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;9;-1292.261,30.85132;Inherit;False;1;0;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;8;-1278.548,-49.35237;Inherit;False;Constant;_Tilling;Tilling;1;0;Create;True;0;0;False;0;False;200;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;12;-1251.463,-160.8901;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;52;-2325.725,31.44121;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-2136.988,476.0375;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;19;-1631.96,248.9884;Inherit;True;Property;_NormalMap;Normal Map;2;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NoiseGeneratorNode;64;-1905.389,1037.126;Inherit;False;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;72;-1824.45,885.8407;Inherit;False;Property;_VertexOffset;VertexOffset;23;0;Create;True;0;0;False;0;False;0,0,0;-2.5,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;94;-2342.379,706.2437;Inherit;False;Property;_ScanVertexOffset;ScanVertexOffset;22;0;Create;True;0;0;False;0;False;0,0,0;-2.5,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ScaleAndOffsetNode;89;-1850.683,1263.498;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;18;-1309.602,263.9722;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;11;-1033.563,-1.490004;Inherit;False;1;0;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-1933.313,33.0429;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;6;-1059.214,-119.3001;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;71;-1665.389,1101.126;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;90;-1610.682,1263.498;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;74;-1648.389,879.1255;Inherit;False;View;Object;False;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;73;-1600.389,1023.126;Inherit;False;Constant;_Float1;Float 0;26;0;Create;True;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;93;-2015.107,848.5869;Inherit;False;Constant;_Float2;Float 0;26;0;Create;True;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;95;-2068.997,705.3335;Inherit;False;View;Object;False;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;21;-1308.39,503.4708;Inherit;False;Property;_RamScale;Ram Scale;8;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;54;-1968.833,555.2095;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-1306.082,430.5614;Inherit;False;Property;_RimBias;Rim Bias;9;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-1310.217,578.5535;Inherit;False;Property;_RimPower;Rim Power;7;0;Create;True;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;10;-841.463,-116.19;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;55;-1772.284,553.7618;Inherit;False;ScanAphla;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-1384.451,945.8407;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;56;-1753.033,20.90925;Inherit;False;ScanColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;91;-1377.389,1181.126;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-1782.512,719.1482;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FresnelNode;17;-1060.52,279.2901;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;3;-693.1581,-124.6001;Inherit;False;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;-1533.35,725.4525;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;59;-1049.262,194.553;Inherit;False;56;ScanColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-786.0212,-18.27063;Inherit;False;Property;_Flash;Flash;6;0;Create;True;0;0;False;0;False;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;1;-862.5,57;Inherit;False;Property;_MainColor;MainColor;1;1;[HDR];Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;60;-766.2625,403.553;Inherit;False;55;ScanAphla;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;32;-757.8157,299.2438;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;76;-1196.39,1035.126;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;29;-1028.793,472.4434;Inherit;True;Property;_Line;Line;4;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;97;-1019.237,915.6617;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;63;-420.1182,154.4087;Inherit;False;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;26;-486.7927,243.4434;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-595.7927,109.4434;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;15;-478.9313,-128.7252;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;-952.8157,662.2438;Inherit;False;Property;_LineIntensity;Line Intensity;5;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;25;-289.7927,33.44336;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexToFragmentNode;98;-314.4377,-58.80487;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;77;-824.3903,909.1256;Inherit;False;VertexOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;27;-332.7927,242.4434;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-696.8157,536.2438;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;78;-169.3174,379.2372;Inherit;False;77;VertexOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-91.8697,9.205536;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;28;-118.7927,252.4434;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;86,-17;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;EmissionRobot;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;1;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;81;0;79;1
WireConnection;81;1;79;2
WireConnection;81;2;79;3
WireConnection;83;0;81;0
WireConnection;83;1;82;0
WireConnection;83;2;80;0
WireConnection;85;0;83;0
WireConnection;85;1;84;0
WireConnection;67;0;70;2
WireConnection;67;1;68;0
WireConnection;67;2;69;0
WireConnection;33;20;35;0
WireConnection;33;18;36;0
WireConnection;33;19;37;0
WireConnection;33;21;38;0
WireConnection;33;22;39;0
WireConnection;46;20;51;0
WireConnection;46;18;47;0
WireConnection;46;19;48;0
WireConnection;46;21;49;0
WireConnection;46;22;45;0
WireConnection;86;0;85;0
WireConnection;65;0;67;0
WireConnection;65;1;66;0
WireConnection;44;0;46;0
WireConnection;44;1;50;0
WireConnection;43;0;33;0
WireConnection;43;1;42;0
WireConnection;12;0;14;1
WireConnection;12;1;14;2
WireConnection;12;2;14;3
WireConnection;52;0;33;0
WireConnection;52;1;46;0
WireConnection;53;0;43;0
WireConnection;53;1;44;0
WireConnection;64;0;65;0
WireConnection;89;0;86;0
WireConnection;18;0;19;0
WireConnection;41;0;52;0
WireConnection;41;1;40;0
WireConnection;6;0;12;0
WireConnection;6;1;8;0
WireConnection;6;2;9;0
WireConnection;71;0;64;0
WireConnection;90;0;89;0
WireConnection;74;0;72;0
WireConnection;95;0;94;0
WireConnection;54;0;53;0
WireConnection;54;1;44;0
WireConnection;10;0;6;0
WireConnection;10;1;11;0
WireConnection;55;0;54;0
WireConnection;75;0;74;0
WireConnection;75;1;73;0
WireConnection;56;0;41;0
WireConnection;91;0;71;0
WireConnection;91;1;90;0
WireConnection;92;0;95;0
WireConnection;92;1;93;0
WireConnection;17;0;18;0
WireConnection;17;1;20;0
WireConnection;17;2;21;0
WireConnection;17;3;22;0
WireConnection;3;0;10;0
WireConnection;96;0;92;0
WireConnection;96;1;33;0
WireConnection;32;0;17;0
WireConnection;76;0;75;0
WireConnection;76;1;91;0
WireConnection;97;0;96;0
WireConnection;97;1;76;0
WireConnection;63;0;59;0
WireConnection;26;0;1;4
WireConnection;26;1;32;0
WireConnection;26;2;60;0
WireConnection;24;0;1;0
WireConnection;24;1;32;0
WireConnection;15;1;3;0
WireConnection;15;2;16;0
WireConnection;25;0;1;0
WireConnection;25;1;24;0
WireConnection;25;2;63;0
WireConnection;98;0;15;0
WireConnection;77;0;97;0
WireConnection;27;0;26;0
WireConnection;30;0;29;1
WireConnection;30;1;31;0
WireConnection;5;0;98;0
WireConnection;5;1;25;0
WireConnection;28;0;27;0
WireConnection;28;1;30;0
WireConnection;0;2;5;0
WireConnection;0;9;28;0
WireConnection;0;11;78;0
ASEEND*/
//CHKSM=A31C76EEE7F5B330247E9A825C8C9DCF55902883