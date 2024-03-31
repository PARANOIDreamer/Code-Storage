// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Slime"
{
	Properties
	{
		_MainTex("Main Tex", 2D) = "black" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		_MatcapMap("Matcap Map", 2D) = "white" {}
		_EmssionMap("Emssion Map", 2D) = "black" {}
		_EmissionColor("Emission Color", Color) = (0,0,0,0)
		_EmissionPower("Emission Power", Float) = 1
		_EmissionScale("Emission Scale", Float) = 1
		_EmissionBais("Emission Bais", Float) = 0
		_NoiseMap("Noise Map", 2D) = "white" {}
		_NosieFalloff("Nosie Falloff", Float) = 5
		_NoiseTilling("Noise Tilling", Vector) = (1,1,1,0)
		_NoiseSpeed("Noise Speed", Vector) = (0,0,0,0)
		_VertexOffset("Vertex Offset", 2D) = "black" {}
		_OffsetFalloff("Offset Falloff", Float) = 5
		_OffsetTilling("Offset Tilling", Vector) = (1,1,1,0)
		_OffsetSpeed("Offset Speed", Vector) = (0,0,0,0)
		_OffsetDir("Offset Dir", Vector) = (0,0,0,0)
		_OffsetIntensity("Offset Intensity", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
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
			float2 uv_texcoord;
			float3 worldNormal;
			INTERNAL_DATA
		};

		uniform sampler2D _VertexOffset;
		uniform float _OffsetFalloff;
		uniform float3 _OffsetTilling;
		uniform float3 _OffsetSpeed;
		uniform sampler2D _NormalMap;
		uniform float4 _NormalMap_ST;
		uniform float3 _OffsetDir;
		uniform float _OffsetIntensity;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform sampler2D _MatcapMap;
		uniform sampler2D _NoiseMap;
		uniform float _NosieFalloff;
		uniform float3 _NoiseTilling;
		uniform float3 _NoiseSpeed;
		uniform float _EmissionBais;
		uniform float _EmissionScale;
		uniform float _EmissionPower;
		uniform float4 _EmissionColor;
		uniform sampler2D _EmssionMap;
		uniform float4 _EmssionMap_ST;


		inline float4 TriplanarSampling71( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2Dlod( topTexMap, float4(tiling * worldPos.zy * float2(  nsign.x, 1.0 ), 0, 0) );
			yNorm = tex2Dlod( topTexMap, float4(tiling * worldPos.xz * float2(  nsign.y, 1.0 ), 0, 0) );
			zNorm = tex2Dlod( topTexMap, float4(tiling * worldPos.xy * float2( -nsign.z, 1.0 ), 0, 0) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		inline float3 TriplanarSampling50( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			xNorm.xyz  = half3( UnpackNormal( xNorm ).xy * float2(  nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz  = half3( UnpackNormal( yNorm ).xy * float2(  nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz  = half3( UnpackNormal( zNorm ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
			return normalize( xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 ase_worldNormal = UnityObjectToWorldNormal( v.normal );
			float3 objToWorld60 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float4 triplanar71 = TriplanarSampling71( _VertexOffset, ( ( ( ase_worldPos - objToWorld60 ) * _OffsetTilling ) + ( _Time.y * _OffsetSpeed ) ), ase_worldNormal, _OffsetFalloff, float2( 1,1 ), 1.0, 0 );
			float2 uv_NormalMap = v.texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float3 ase_worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
			float3x3 tangentToWorld = CreateTangentToWorldPerVertex( ase_worldNormal, ase_worldTangent, v.tangent.w );
			float3 tangentNormal1 = UnpackNormal( tex2Dlod( _NormalMap, float4( uv_NormalMap, 0, 0.0) ) );
			float3 modWorldNormal1 = normalize( (tangentToWorld[0] * tangentNormal1.x + tangentToWorld[1] * tangentNormal1.y + tangentToWorld[2] * tangentNormal1.z) );
			float3 Normal_world12 = modWorldNormal1;
			float dotResult86 = dot( Normal_world12 , _OffsetDir );
			float clampResult87 = clamp( dotResult86 , 0.0 , 1.0 );
			float3 worldToObj82 = mul( unity_WorldToObject, float4( ( ( ( triplanar71 * float4( ( Normal_world12 + _OffsetDir ) , 0.0 ) * ( clampResult87 + 1.0 ) ) * v.color.r * ( _OffsetIntensity * 0.05 ) ) + float4( ase_worldPos , 0.0 ) ).xyz, 1 ) ).xyz;
			float3 VertexOffset77 = worldToObj82;
			v.vertex.xyz = VertexOffset77;
			v.vertex.w = 1;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			o.Normal = float3(0,0,1);
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 objToWorld39 = mul( unity_ObjectToWorld, float4( float3( 0,0,0 ), 1 ) ).xyz;
			float3 triplanar50 = TriplanarSampling50( _NoiseMap, ( ( ( ase_worldPos - objToWorld39 ) * _NoiseTilling ) + ( _Time.y * _NoiseSpeed ) ), ase_worldNormal, _NosieFalloff, float2( 1,1 ), 1.0, 0 );
			float3 worldToViewDir2 = normalize( mul( UNITY_MATRIX_V, float4( triplanar50, 0 ) ).xyz );
			float4 Matcap24 = tex2D( _MatcapMap, ((worldToViewDir2).xy*0.5 + 0.5) );
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			float3 Normal_world12 = normalize( (WorldNormalVector( i , UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) ) )) );
			float fresnelNdotV16 = dot( Normal_world12, ase_worldViewDir );
			float fresnelNode16 = ( _EmissionBais + _EmissionScale * pow( max( 1.0 - fresnelNdotV16 , 0.0001 ), _EmissionPower ) );
			float2 uv_EmssionMap = i.uv_texcoord * _EmssionMap_ST.xy + _EmssionMap_ST.zw;
			float4 Emission22 = ( ( fresnelNode16 * _EmissionColor ) * tex2D( _EmssionMap, uv_EmssionMap ) );
			o.Emission = ( ( tex2D( _MainTex, uv_MainTex ) * Matcap24 ) + Emission22 ).rgb;
			o.Alpha = 1;
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
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
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
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
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
-1;395;1113;523;9227.623;-949.8176;8.538982;True;False
Node;AmplifyShaderEditor.CommentaryNode;59;-4582.832,67.09041;Inherit;False;2768.866;649.8913;Comment;17;2;3;5;6;24;47;55;50;53;39;38;54;40;57;58;56;52;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;13;-2708.574,-242.6638;Inherit;False;893.8127;280.0883;Comment;3;11;1;12;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode;38;-4515.623,117.0904;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;11;-2658.574,-192.5755;Inherit;True;Property;_NormalMap;Normal Map;1;0;Create;True;0;0;False;0;False;-1;None;46a7841bc33c7864ebbeb2522194875c;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode;39;-4532.832,263.1547;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode;40;-4277.95,190.9146;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;1;-2300.25,-193.7835;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;56;-4287.644,532.9816;Inherit;False;Property;_NoiseSpeed;Noise Speed;11;0;Create;True;0;0;False;0;False;0,0,0;0,0.2,-0.2;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector3Node;54;-4287.981,295.4332;Inherit;False;Property;_NoiseTilling;Noise Tilling;10;0;Create;True;0;0;False;0;False;1,1,1;1,1,1.5;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;58;-4288.009,440.6791;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;89;-4576.142,1412.023;Inherit;False;2775.685;852.4952;Comment;27;61;60;64;63;62;65;66;67;68;70;69;71;73;84;83;86;87;88;72;76;79;75;74;80;77;81;82;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;12;-2058.761,-192.6638;Inherit;False;Normal_world;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;61;-4508.933,1462.023;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformPositionNode;60;-4526.142,1608.088;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;53;-4068.158,278.9354;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-4072.845,440.4438;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;63;-4280.953,1876.915;Inherit;False;Property;_OffsetSpeed;Offset Speed;15;0;Create;True;0;0;False;0;False;0,0,0;0,0.2,-0.2;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;62;-4281.318,1785.612;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;65;-4271.259,1535.848;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;84;-3582.209,1970.275;Inherit;False;Property;_OffsetDir;Offset Dir;16;0;Create;True;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;73;-3624.159,1854.542;Inherit;False;12;Normal_world;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Vector3Node;64;-4281.29,1640.366;Inherit;False;Property;_OffsetTilling;Offset Tilling;14;0;Create;True;0;0;False;0;False;1,1,1;1,1,1.5;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;47;-3916.53,136.8326;Inherit;True;Property;_NoiseMap;Noise Map;8;0;Create;True;0;0;False;0;False;None;58da167f94fa09b40a88c19b6eee75cc;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleAddOpNode;55;-3845.525,343.1917;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;52;-3871.91,456.7502;Inherit;False;Property;_NosieFalloff;Nosie Falloff;9;0;Create;True;0;0;False;0;False;5;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;50;-3611.346,316.2697;Inherit;True;Spherical;World;True;Top Texture 0;_TopTexture0;white;-1;None;Mid Texture 0;_MidTexture0;white;-1;None;Bot Texture 0;_BotTexture0;white;-1;None;Triplanar Sampler;World;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;86;-3367.808,1954.796;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-4066.155,1785.377;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;-4061.468,1623.869;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;69;-3909.84,1481.765;Inherit;True;Property;_VertexOffset;Vertex Offset;12;0;Create;True;0;0;False;0;False;None;f3c21028647e98a44a8799301e9b6584;False;black;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;70;-3865.22,1801.684;Inherit;False;Property;_OffsetFalloff;Offset Falloff;13;0;Create;True;0;0;False;0;False;5;5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;27;-3257.018,760.9724;Inherit;False;1447.032;600.2501;Comment;10;22;17;18;19;20;16;8;15;21;14;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TransformDirectionNode;2;-3174.126,313.7257;Inherit;False;World;View;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;68;-3838.835,1688.125;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;87;-3242.008,1953.536;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-3265.08,2126.519;Inherit;False;Property;_OffsetIntensity;Offset Intensity;17;0;Create;True;0;0;False;0;False;0;0.678;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;88;-3098.44,1947.162;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;3;-2897.527,312.4185;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;14;-3185.093,872.6904;Inherit;False;12;Normal_world;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-3158.23,1020.706;Inherit;False;Property;_EmissionScale;Emission Scale;6;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;83;-3365.471,1863.473;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TriplanarNode;71;-3604.656,1661.203;Inherit;True;Spherical;World;False;Top Texture 1;_TopTexture1;white;-1;None;Mid Texture 1;_MidTexture1;white;-1;None;Bot Texture 1;_BotTexture1;white;-1;None;Triplanar Sampler;World;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;17;-3158.23,954.4661;Inherit;False;Property;_EmissionBais;Emission Bais;7;0;Create;True;0;0;False;0;False;0;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-3157.145,1092.376;Inherit;False;Property;_EmissionPower;Emission Power;5;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;5;-2705.921,313.9984;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;76;-2914.081,2131.52;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;79;-2939.617,1965.563;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;72;-2909.583,1781.644;Inherit;False;3;3;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;20;-2829.377,1127.412;Inherit;False;Property;_EmissionColor;Emission Color;4;0;Create;True;0;0;False;0;False;0,0,0,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FresnelNode;16;-2842.019,960.3411;Inherit;False;Standard;WorldNormal;ViewDir;False;True;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;8;-2557.552,1131.222;Inherit;True;Property;_EmssionMap;Emssion Map;3;0;Create;True;0;0;False;0;False;-1;None;cc2fe3b87b1ef2e4585a78dc455b22c0;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;-2556.411,1030.629;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;6;-2415.573,283.9823;Inherit;True;Property;_MatcapMap;Matcap Map;2;0;Create;True;0;0;False;0;False;-1;None;ad4d5a8fec0ebad40a0486b72e277d27;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;-2676.265,1884.829;Inherit;False;3;3;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldPosInputsNode;80;-2695.796,2030.144;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;24;-2056.965,284.8394;Inherit;False;Matcap;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;81;-2479.632,1937.682;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-2242.815,1032.701;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TransformPositionNode;82;-2329.999,1934.243;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;7;-888.0561,-151.7266;Inherit;True;Property;_MainTex;Main Tex;0;0;Create;True;0;0;False;0;False;-1;None;495f339ba5a4a1e46af08dc0d6ac8edf;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;22;-2052.985,1027.571;Inherit;False;Emission;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;25;-798.9233,58.54942;Inherit;False;24;Matcap;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;77;-2043.457,1933.104;Inherit;False;VertexOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;23;-541.2441,124.203;Inherit;False;22;Emission;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;-500.5632,-36.63522;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;78;-301.6421,323.7365;Inherit;False;77;VertexOffset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;9;-238.8398,46.6916;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;0,-1;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;Slime;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Absolute;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;40;0;38;0
WireConnection;40;1;39;0
WireConnection;1;0;11;0
WireConnection;12;0;1;0
WireConnection;53;0;40;0
WireConnection;53;1;54;0
WireConnection;57;0;58;0
WireConnection;57;1;56;0
WireConnection;65;0;61;0
WireConnection;65;1;60;0
WireConnection;55;0;53;0
WireConnection;55;1;57;0
WireConnection;50;0;47;0
WireConnection;50;9;55;0
WireConnection;50;4;52;0
WireConnection;86;0;73;0
WireConnection;86;1;84;0
WireConnection;67;0;62;0
WireConnection;67;1;63;0
WireConnection;66;0;65;0
WireConnection;66;1;64;0
WireConnection;2;0;50;0
WireConnection;68;0;66;0
WireConnection;68;1;67;0
WireConnection;87;0;86;0
WireConnection;88;0;87;0
WireConnection;3;0;2;0
WireConnection;83;0;73;0
WireConnection;83;1;84;0
WireConnection;71;0;69;0
WireConnection;71;9;68;0
WireConnection;71;4;70;0
WireConnection;5;0;3;0
WireConnection;76;0;75;0
WireConnection;72;0;71;0
WireConnection;72;1;83;0
WireConnection;72;2;88;0
WireConnection;16;0;14;0
WireConnection;16;1;17;0
WireConnection;16;2;18;0
WireConnection;16;3;19;0
WireConnection;15;0;16;0
WireConnection;15;1;20;0
WireConnection;6;1;5;0
WireConnection;74;0;72;0
WireConnection;74;1;79;1
WireConnection;74;2;76;0
WireConnection;24;0;6;0
WireConnection;81;0;74;0
WireConnection;81;1;80;0
WireConnection;21;0;15;0
WireConnection;21;1;8;0
WireConnection;82;0;81;0
WireConnection;22;0;21;0
WireConnection;77;0;82;0
WireConnection;10;0;7;0
WireConnection;10;1;25;0
WireConnection;9;0;10;0
WireConnection;9;1;23;0
WireConnection;0;2;9;0
WireConnection;0;11;78;0
ASEEND*/
//CHKSM=29627E07C4ED5F1D6DFED8B8216E585B56AD16D8