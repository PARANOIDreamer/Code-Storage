Shader "Unlit/Toon"
{
	Properties
	{
		_MainTex ("Base Texture", 2D) = "white" {}
		_SssTex ("SSS Texture", 2D) = "black" {}
		_IlmTex ("ILM Texture", 2D) = "gray" {}
		_DetailTex ("Detail Texture", 2D) = "white" {}
		_ToonShadow ("Toon Shadow", Range(0, 1)) = 0.5
		_ToonHardness ("Shadow Hardness", Float) = 20.0
		_ToonSpecular ("Specular Range", Range(0, 1)) = 0.1
		_SpecularCol ("Specular Color", COLOR) = (1, 1, 1, 1)
		_RimDir ("RimLight Dirtectoin", Vector) = (0, 0, 0, 0)
		_RimColor ("RimLight Color", COLOR) = (1, 1, 1, 1)
		_OutLine ("Outline Width", Range(0, 0.1)) = 0.05
		_OutlineCol ("Outline Color", COLOR) = (0, 0, 0, 0)
	}
	SubShader
	{
		Tags { "LightMode"="ForwardBase" }
		LOD 100

		Pass
		{
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float _OutLine;
			float4 _OutlineCol;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.uv = v.uv;
				float3 viewPos = UnityObjectToViewPos(v.vertex);
				float3 viewNormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, v.normal));
				viewPos += viewNormal * 0.1 * _OutLine * v.color.a;
				o.vertex = mul(UNITY_MATRIX_P, float4(viewPos, 1.0));
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				// sample the texture
				half4 baseMap = tex2D(_MainTex, i.uv);
				half3 baseCol = baseMap.rgb;

				half3 finalCol = (baseCol * 0.5 + _OutlineCol * 0.5) * 0.3;

				return half4(finalCol, 1.0);
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv1 : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 normal : NORMAL;
				float4 color : COLOR;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				float4 vertexColor : TEXCOORD3;
			};

			sampler2D _MainTex;
			sampler2D _SssTex;
			sampler2D _IlmTex;
			sampler2D _DetailTex;
			float _ToonShadow;
			float _ToonHardness;
			float _ToonSpecular;
			float4 _SpecularCol;
			float4 _RimDir;
			float4 _RimColor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = float4(v.uv1, v.uv2);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.vertexColor = v.color;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				// sample the texture
				half2 uv1 = i.uv.xy;
				half2 uv2 = i.uv.zw;
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 normalDir = normalize(i.worldNormal);

				half NdotL = dot(normalDir, lightDir);
				half NdotV = dot(normalDir, viewDir);
				half halfLambert = (NdotL + 1.0) * 0.5;

				half4 baseMap = tex2D(_MainTex, uv1);
				half3 baseCol = baseMap.rgb;
				half baseMask = baseMap.a;

				half4 sssMap = tex2D(_SssTex, uv1);
				half3 sssColor = sssMap.rgb;
				half sssMask = sssMap.a;

				half4 ilmMap = tex2D(_IlmTex, uv1);
				half specularIntensity = ilmMap.r;
				half labmertOffset = ilmMap.g * 2.0 -1.0;
				half specularSize = ilmMap.b;
				half innerLine = ilmMap.a;

				half3 detailCol = tex2D(_DetailTex, uv2).rgb;

				float ao = i.vertexColor.r;

				half diffuseShadow = saturate((halfLambert * ao + labmertOffset - _ToonShadow) * _ToonHardness);
				half3 toonDiffuse = lerp(sssColor, baseCol, diffuseShadow);

				half specularShadow = (NdotV + 1.0) * 0.5 * ao + labmertOffset;
				specularShadow = specularShadow * 0.1 + halfLambert * 0.9;
				specularShadow = saturate((specularShadow - (1.0 - specularSize * _ToonSpecular)) * 500) * specularIntensity;
				half3 toonSpecular = (baseCol + _SpecularCol.rgb) * 0.5 * specularShadow;

				half3 rimlightDir = normalize(mul((float3x3)UNITY_MATRIX_I_V, _RimDir.xyz));
				half rimTerm = (dot(rimlightDir, normalDir) + 1.0) * 0.5;
				rimTerm = saturate((rimTerm + labmertOffset - _ToonShadow) * 20);
				half3 toonRim = (baseCol + _RimColor.rgb) * 0.5 * rimTerm * baseMask * diffuseShadow * sssMask;


				half3 lineCol = lerp(baseCol * 0.2, half3(1.0, 1.0, 1.0), innerLine);
				detailCol = lerp(baseCol * 0.2, half3(1.0, 1.0, 1.0), detailCol);
				lineCol = lineCol * lineCol * detailCol;

				half3 finalCol = (toonDiffuse + toonSpecular + toonRim) * lineCol;
				finalCol = sqrt(max(0.0, exp2(log2(max(0.0, finalCol)) * 2.2)));

				return half4(finalCol, 1.0);
			}
			ENDCG
		}
	}
}
