Shader "Unlit/Body"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_MixTex ("Mixed Texture", 2D) = "white" {}
		_NormalTex ("Normal Texture", 2D) = "bump" {}
		_CubeMap("Cube Map", Cube) = "white"{}
		_SkinMap("Skin Map", 2D) = "white" {}
		_Shininess ("Shininess", Range(1.0,100)) = 10
		_SkinShadow ("Skin Shadow", Range(-1, 1)) = 0.0
		_SkinShadowCol ("Skin Color", Range(0, 1)) = 1.0

		[HideInInspector]custom_SHAr("Custom SHAr", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHAg("Custom SHAg", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHAb("Custom SHAb", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHBr("Custom SHBr", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHBg("Custom SHBg", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHBb("Custom SHBb", Vector) = (0, 0, 0, 0)
		[HideInInspector]custom_SHC("Custom SHC", Vector) = (0, 0, 0, 1)
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
			sampler2D _MixTex;
			sampler2D _NormalTex;
			samplerCUBE _CubeMap;
			float4 _CubeMap_HDR;
			sampler2D _SkinMap;
			float4 _LightColor0;
			float _Shininess;
			float _SkinShadow;
			float _SkinShadowCol;

			half4 custom_SHAr;
			half4 custom_SHAg;
			half4 custom_SHAb;
			half4 custom_SHBr;
			half4 custom_SHBg;
			half4 custom_SHBb;
			half4 custom_SHC;

			float3  CustomSH(float3 normalDir)
			{
				float4 normalForSH = float4(normalDir, 1.0);
				//SHEvalLinearL0L1
				half3 x;
				x.r = dot(custom_SHAr, normalForSH);
				x.g = dot(custom_SHAg, normalForSH);
				x.b = dot(custom_SHAb, normalForSH);

				//SHEvalLinearL2
				half3 x1, x2;
				// 4 of the quadratic (L2) polynomials
				half4 vB = normalForSH.xyzz * normalForSH.yzzx;
				x1.r = dot(custom_SHBr, vB);
				x1.g = dot(custom_SHBg, vB);
				x1.b = dot(custom_SHBb, vB);

				// Final (5th) quadratic (L2) polynomial
				half vC = normalForSH.x*normalForSH.x - normalForSH.y*normalForSH.y;
				x2 = custom_SHC.rgb * vC;

				float3 sh = max(float3(0.0, 0.0, 0.0), (x + x1 + x2));
				sh = pow(sh, 1.0 / 2.2);

				return sh;
			}

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
				half3 normalDir = normalize(i.normalDir);
				half3 tangentDir = normalize(i.tangentDir);
				half3 binormalDir = normalize(i.binormalDir);
				float3x3 TBN = float3x3(tangentDir, binormalDir, normalDir);
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half attenuation = LIGHT_ATTENUATION(i);

				half4 normalMap = tex2D(_NormalTex, i.uv);
				half3 normalData = UnpackNormal(normalMap);
				normalDir = normalize(mul(normalData, TBN));

				half4 mainCol = tex2D(_MainTex, i.uv);
				half a = mainCol.a;
				mainCol = pow(mainCol, 2.2);
				half4 mixCol = tex2D(_MixTex, i.uv);
				half metal = mixCol.g;
				half roughness = mixCol.r;
				half skin = 1.0 - mixCol.b;
				half smoothness = 1.0 - roughness;
				half3 baseCol = mainCol.rgb * (1.0 - metal);
				half3 specularCol = lerp(0.01, mainCol.rgb, metal);

				half directDiffDis = max(0.0, dot(normalDir, lightDir));
				half halfLambert = (directDiffDis + 1.0) * 0.5;
				half3 directDiffCol = directDiffDis * _LightColor0.xyz * baseCol * attenuation;
				
				half skinX =saturate(directDiffDis * attenuation +_SkinShadow);
				skinX = max(0.0, skinX);
				//skinX = min(0.9, skinX);
				half2 skinUV = half2(skinX, _SkinShadowCol);
				half3 skinCol = tex2D(_SkinMap, skinUV);
				skinCol = pow(skinCol, 2.2);
				half3 skinDiffCol = skinCol * _LightColor0.xyz * baseCol;
				directDiffCol = lerp(directDiffCol, skinDiffCol, skin);

				half3 halfDir = normalize(lightDir + viewDir);
				half3 reflectDir = reflect(-viewDir, normalDir);
				half shininess = lerp(1.0, _Shininess, smoothness);
				half directSpecDis = pow(max(0.0, dot(normalDir, halfDir)), shininess * smoothness);
				half3 directSpecCol = directSpecDis * specularCol * _LightColor0 * attenuation;

				half3 envDiffCol = CustomSH(normalDir) * baseCol * halfLambert;
				envDiffCol = lerp(envDiffCol * 0.5, envDiffCol * 0.8, skin);

				float mip_level = roughness * (1.7 - 0.7 * roughness) * 6.0;
				half4 cubemap = texCUBElod(_CubeMap, float4(reflectDir, mip_level));
				half3 envCol = DecodeHDR(cubemap, _CubeMap_HDR);
				half3 envSpecCol = envCol * specularCol* halfLambert;

				half3 finalCol = directDiffCol + directSpecCol + envDiffCol +envSpecCol;
				finalCol = ACES_Tonemapping(finalCol);
				finalCol = pow(finalCol, 1.0 / 2.2);
				return half4(finalCol, a);
			}
			ENDCG
		}
	}
		FallBack "Diffuse"
}
