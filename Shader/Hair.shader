Shader "Unlit/Hair"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_BaseCol ("Base Color", COLOR) = (1.0, 1.0, 1.0, 1.0)
		_NormalTex ("Normal Texture", 2D) = "bump" {}
		_NoiseTex ("Noise Texture", 2D) = "white" {}
		_CubeMap("Cube Map", Cube) = "white"{}
		_Roughness ("Roughness", Range(0.0,1.0)) = 0.5
		_SpecularCol1 ("Soft Specular Color", COLOR) = (1.0, 1.0, 1.0, 1.0)
		_SpecularCol2 ("Hard Specular Color", COLOR) = (1.0, 1.0, 1.0, 1.0)
		_Shininess1 ("Soft Shininess", Range(0.1,1.0)) = 0.1
		_Shininess2 ("Hard Shininess", Range(0.1,1.0)) = 0.1
		_Noise1 ("Soft Noise", float) = 0.0
		_Noise2 ("Hard Noise", float) = 0.0
		_Offset1 ("Soft Offset", float) = 0.0
		_Offset2 ("Hard Offset", float) = 0.0

		[Toggle(_DIFF)] _Diff("Diffuse ON", float) = 1.0
		[Toggle(_SPEC)] _Spec("Specular ON", float) = 1.0
		[Toggle(_ENV)] _Env("Envernment ON", float) = 1.0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#pragma multi_compile _ _DIFF
			#pragma multi_compile _ _SPEC
			#pragma multi_compile _ _ENV

			#include "UnityCG.cginc"
			#include "AutoLIght.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normalDir : TEXCOORD1;
				float3 posWorld : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 binormalDir : TEXCOORD4;
				LIGHTING_COORDS(5, 6)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			sampler2D _NormalTex;
			samplerCUBE _CubeMap;
			float4 _CubeMap_HDR;
			float4 _LightColor0;
			float4 _BaseCol;
			float _Roughness;
			float4 _SpecularCol1;
			float4 _SpecularCol2;
			float _Shininess1;
			float _Shininess2;
			float _Noise1; 
			float _Noise2;
			float _Offset1;
			float _Offset2;

			inline float3 ACES_Tonemapping(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				float3 encode_color = saturate((x*(a*x + b)) / (x*(c*x + d) + e));
				return encode_color;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir)) * v.tangent.w;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				float3 normalDir = normalize(i.normalDir);
				float3 tangentDir = normalize(i.tangentDir);
				float3 binormalDir = normalize(i.binormalDir);
				float3x3 TBN = float3x3(tangentDir, binormalDir, normalDir);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float attenuation = LIGHT_ATTENUATION(i);

				half4 normalMap = tex2D(_NormalTex, i.uv);
				half3 normalData = UnpackNormal(normalMap);
				normalDir = normalize(mul(normalData, TBN));

				half4 mainCol = tex2D(_MainTex, i.uv);
				mainCol = pow(mainCol, 2.2) * _BaseCol;
				half roughness = _Roughness;
				half smoothness = 1.0 - roughness;

				half directDiffDis = max(0.0, dot(normalDir, lightDir));
				half halfLambert = (directDiffDis + 1.0) * 0.5;
				#ifdef _DIFF
				half3 directDiffCol = _LightColor0.xyz * mainCol * halfLambert;// * attenuation;
				#else
				half3 directDiffCol = half3(0.0, 0.0, 0.0);
				#endif

				float2 noiseUV = i.uv * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
				float noise = tex2D(_NoiseTex, noiseUV).r - 0.5;
				float3 halfDir = normalize(lightDir + viewDir);
				float NdotH = dot(normalDir, halfDir);
				float TdotH = dot(tangentDir, halfDir);
				float NdotV = max(0.0, dot(normalDir, viewDir));
				float specAttenuation = saturate(sqrt(max(0.0, halfLambert / NdotV))) * attenuation;

				float3 specCol1 = _SpecularCol1.rgb + mainCol;
				float3 specOffset1 = normalDir * (noise * _Noise1 + _Offset1);
				float3 binormalDir1 = normalize(binormalDir + specOffset1);
				float BdotH1 = dot(binormalDir1, halfDir) /  _Shininess1;
				float specularDis1 = exp(-(TdotH * TdotH + BdotH1 * BdotH1) / (1.0 + NdotH));
				float3 specularCol1 = specularDis1 * _LightColor0.xyz * specCol1 * specAttenuation;

				float3 specCol2 = _SpecularCol2.rgb + mainCol;
				float3 specOffset2 = normalDir * (noise * _Noise2 + _Offset2);
				float3 binormalDir2 = normalize(binormalDir + specOffset2);
				float BdotH2 = dot(binormalDir2, halfDir) /  _Shininess2;
				float specularDis2 = exp(-(TdotH * TdotH + BdotH2 * BdotH2) / (1.0 + NdotH));
				float3 specularCol2 = specularDis2 * _LightColor0.xyz * specCol2 * specAttenuation;
				#ifdef _SPEC
				half3 directSpecCol = specularCol1 + specularCol2;
				#else
				half3 directSpecCol = half3(0.0, 0.0, 0.0);
				#endif

				float mip_level = roughness * (1.7 - 0.7 * roughness) * 6.0;
				half3 reflectDir = reflect(-viewDir, normalDir);
				half4 cubemap = texCUBElod(_CubeMap, float4(reflectDir, mip_level));
				half3 envCol = DecodeHDR(cubemap, _CubeMap_HDR);
				#ifdef _ENV
				half3 envSpecCol = envCol * halfLambert * noise;
				#else
				half3 envSpecCol = half3(0.0, 0.0, 0.0);
				#endif

				half3 finalCol = directDiffCol + directSpecCol + envSpecCol;
				finalCol = ACES_Tonemapping(finalCol);
				finalCol = pow(finalCol, 1.0 / 2.2);
				return half4(finalCol, 1.0);
			}
			ENDCG
		}
	}
		FallBack "Diffuse"
}
