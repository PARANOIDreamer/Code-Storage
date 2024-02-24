Shader "Unlit/M-Dragon"
{
	Properties
	{
		_DiffuseCol("Diffuse Color",COLOR) = (1,1,1,1)
		_AddCol("Add Color",COLOR) = (1,1,1,1)
		_CubeTex("Cube Map",Cube) = "white"{}
		_ThicknessMap("Thickness Map",2D) = "white"{}
		_Opacity("Opacity",Range(0,1)) = 0.0
		_RefractDissociation("Refract Dissociation",Range(0.0, 1.0)) = 0.0
		_Contrast("Contrast",float) = 1.0
		_Bightness("Bightness",float) = 1.0
		_Rotate("Rotate",Range(0.0, 360)) = 0.0
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
			#include "AutoLight.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normalDir : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
			};

			float4 _DiffuseCol;
			float4 _AddCol;
			samplerCUBE _CubeTex;
			float4 _CubeTex_HDR;
			sampler2D _ThicknessMap;
			float4 _LightColor0;
			float _Opacity;
			float _RefractDissociation;
			float _Contrast;
			float _Bightness;
			float _Rotate;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject)).xyz;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				float3 normalDir = normalize(i.normalDir);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				float3 refractDir = -normalize(lightDir + normalDir * _RefractDissociation);
				float refractDis = pow(max(0.0, dot(viewDir, refractDir)), _Contrast) * _Bightness;	
				float thickness = 1.0 - tex2D(_ThicknessMap, i.uv).r;
				half3 refractCol = refractDis * _LightColor0.xyz * thickness;

				half3 baseCol = _DiffuseCol.xyz;
				half3 sykCol =  (dot(normalDir, float3(0, 1, 0)) + 1.0) * 0.5 * baseCol;
				float diffuseDis = max(0.0, dot(normalDir, lightDir));
				half3 diffuseCol = diffuseDis * baseCol * _LightColor0 + _AddCol.xyz + sykCol * _Opacity;

				float3 reflectDir = reflect(-viewDir, normalDir);
				float radian = _Rotate * UNITY_PI / 180;
				float2x2 rotationM = float2x2(cos(radian), -sin(radian), sin(radian), cos(radian));
				float2 rotateReflect = mul(rotationM, reflectDir.xz);
				reflectDir = float3(rotateReflect.x, reflectDir.y, rotateReflect.y);
				float fresnel = 1.0 - max(0.0, dot(normalDir, viewDir));
				float4 hdrCol = texCUBE(_CubeTex, reflectDir);
				float3 cubeCol = DecodeHDR(hdrCol, _CubeTex_HDR) * fresnel;

				half3 finalCol= diffuseCol + refractCol + cubeCol;
				return half4(finalCol, 1.0);
			}
			ENDCG
		}
		Pass
		{
			Tags { "LightMode"="ForwardAdd" }
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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 normalDir : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				LIGHTING_COORDS(3, 4)
			};

			float4 _DiffuseCol;
			float4 _AddCol;
			samplerCUBE _CubeTex;
			float4 _CubeTex_HDR;
			sampler2D _ThicknessMap;
			float4 _LightColor0;
			float _RefractDissociation;
			float _Contrast;
			float _Bightness;
			float _Rotate;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject)).xyz;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				TRANSFER_VERTEX_TO_FRAGMENT(o)
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				float3 normalDir = normalize(i.normalDir);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				float3 otherlightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
				lightDir = lerp(lightDir, otherlightDir, _WorldSpaceLightPos0.w);
				float attenuation = LIGHT_ATTENUATION(i);
				
				float3 refractDir = -normalize(lightDir + normalDir * _RefractDissociation);
				float refractDis = pow(max(0.0, dot(viewDir, refractDir)), _Contrast) * _Bightness;	
				float thickness = 1.0 - tex2D(_ThicknessMap, i.uv).r;
				half3 refractCol = refractDis * _LightColor0.xyz * thickness * attenuation;
				return half4(refractCol, 1.0);
			}
			ENDCG
		}
	}
}
