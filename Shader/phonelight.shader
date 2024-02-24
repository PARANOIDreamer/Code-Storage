Shader "Ulit/phonelight"
{
	Properties
	{
		_MainTex ("Base Map", 2D) = "white" {}
		_SpecularTex ("Specular Map", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(1, 100)) = 1.0
		_AOTex ("AO Map", 2D) = "white" {}
		_NormalTex ("Normal Map", 2D) = "bump" {}
		_NormalIntensity ("Normal Intensity", Range(0.0, 5)) = 1.0
		_HeightTex ("Height Map", 2D) = "black" {}
		_HeightIntensity ("Height Intensity", float) = 2
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0; 
				float3 worldPos : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 binormalDir : TEXCOORD4;
				SHADOW_COORDS(5)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _SpecularTex;
			sampler2D _AOTex;
			sampler2D _NormalTex;
			sampler2D _HeightTex;
			float4 _LightColor0;
			float _Smoothness;
			float _NormalIntensity;
			float _HeightIntensity;

			float3 ACESFilm(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir)) * v.tangent.w;
				TRANSFER_SHADOW(o)
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half3 normalDir = normalize(i.normalDir);
				half3 tangentDir = normalize(i.tangentDir);
				half3 binormalDir = normalize(i.binormalDir);
				float3x3 TBN = float3x3 (tangentDir, binormalDir, normalDir);
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				half3 viewTangent = normalize(mul(TBN, viewDir));
				half2 uv = i.uv;

				// sample the texture
				for (int k = 0; k < 10; k++)
				{
					half height = tex2D(_HeightTex, uv);
					uv = uv - (0.5 - height) * viewTangent.xy * _HeightIntensity * 0.01f;
				}

				half4 col = tex2D(_MainTex, uv);
				col = pow(col, 2.2);
				half4 aoCol = tex2D(_AOTex, uv);
				half4 specularMask = tex2D(_SpecularTex, uv);
				half4 normalmap = tex2D(_NormalTex, uv);
				half3 normalData = UnpackNormal(normalmap);
				normalData.xy = normalData.xy * _NormalIntensity;
				
				normalDir = normalize(mul(normalData, TBN));
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 halfDir = normalize(lightDir + viewDir);

				half shadow = SHADOW_ATTENUATION(i);
				half3 _AmbientCol = UNITY_LIGHTMODEL_AMBIENT.rgb * col.xyz;
				half intensity = min(max(0.0, dot(normalDir, lightDir)), shadow);
				half3 diffuseCol = intensity * _LightColor0.xyz * col.xyz;
				half3 specularCol = pow(max(0.0, dot(normalDir, halfDir)), _Smoothness) * intensity * _LightColor0.xyz * specularMask.rgb;
				half3 finalCol = (diffuseCol + specularCol + _AmbientCol) * aoCol;
				half3 toneCol = ACESFilm(finalCol);
				toneCol = pow(toneCol, 1.0/2.2);
				return float4(toneCol, 1.0);
			}
			ENDCG
		}
		Pass
		{
			Tags { "LightMode" = "ForwardAdd" }
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdadd
			
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0; 
				float3 worldPos : TEXCOORD1;
				float3 normalDir : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 binormalDir : TEXCOORD4;
				LIGHTING_COORDS(5, 6)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _SpecularTex;
			sampler2D _AOTex;
			sampler2D _NormalTex;
			sampler2D _HeightTex;
			float4 _LightColor0;
			float _Smoothness;
			float _NormalIntensity;
			float _HeightIntensity;

			float3 ACESFilm(float3 x)
			{
				float a = 2.51f;
				float b = 0.03f;
				float c = 2.43f;
				float d = 0.59f;
				float e = 0.14f;
				return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_ObjectToWorld).xyz);
				o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormalDir = normalize(cross(o.normalDir, o.tangentDir)) * v.tangent.w;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half3 normalDir = normalize(i.normalDir);
				half3 tangentDir = normalize(i.tangentDir);
				half3 binormalDir = normalize(i.binormalDir);
				float3x3 TBN = float3x3 (tangentDir, binormalDir, normalDir);
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				half3 viewTangent = normalize(mul(TBN, viewDir));
				half2 uv = i.uv;

				// sample the texture
				for (int k = 0; k < 10; k++)
				{
					half height = tex2D(_HeightTex, uv);
					uv = uv - (0.5 - height) * viewTangent.xy * _HeightIntensity * 0.01f;
				}

				half4 col = tex2D(_MainTex, uv);
				half4 aoCol = tex2D(_AOTex, uv);
				half4 specularMask = tex2D(_SpecularTex, uv);
				half4 normalmap = tex2D(_NormalTex, uv);
				half3 normalData = UnpackNormal(normalmap);
				normalData.xy = normalData.xy * _NormalIntensity;
				
				normalDir = normalize(mul(normalData, TBN));
				half3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				half3 pointlightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
				lightDir = lerp(lightDir, pointlightDir, _WorldSpaceLightPos0.w);
				half3 halfDir = normalize(lightDir + viewDir);

				half attenuation = LIGHT_ATTENUATION(i);
				half intensity = min(max(0.0, dot(normalDir, lightDir)), attenuation);
				half3 diffuseCol = intensity * _LightColor0.xyz * col.xyz;
				half3 specularCol = pow(max(0.0, dot(normalDir, halfDir)), _Smoothness) * intensity * _LightColor0.xyz * specularMask.rgb;
				half3 finalCol = (diffuseCol + specularCol) * aoCol;
				return float4(finalCol, 1.0);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
