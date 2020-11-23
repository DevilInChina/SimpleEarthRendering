

#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

float4 _Tint;
float4 _WaterTint;
sampler2D _MainTex, _DetailTex,_HeatTex;
float4 _MainTex_ST, _DetailTex_ST,_HeatTex_ST;

sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

float _Metallic,_WaterMetallic;
float _Smoothness,_WaterSmoothness;
float4 _Emission;
struct VertexData {
	float4 position : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 uv : TEXCOORD0;
};

struct Interpolators {
	float4 position : SV_POSITION;
	float4 uv : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float2 uvHeat: TEXCOORD7;
	float3 originNormal : TEXCOORD8;
	float3 worldNormal:TEXCOORD9;
	#if defined(BINORMAL_PER_FRAGMENT)
		float4 tangent : TEXCOORD2;
	#else
		float3 tangent : TEXCOORD2;
		float3 binormal : TEXCOORD3;
	#endif

	float3 worldPos : TEXCOORD4;

	#if defined(VERTEXLIGHT_ON)
		float3 vertexLightColor : TEXCOORD5;
	#endif
};

void ComputeVertexLightColor (inout Interpolators i) {
	#if defined(VERTEXLIGHT_ON)
		i.vertexLightColor = Shade4PointLights(
			unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
			unity_LightColor[0].rgb, unity_LightColor[1].rgb,
			unity_LightColor[2].rgb, unity_LightColor[3].rgb,
			unity_4LightAtten0, i.worldPos, i.normal
		);
	#endif
}

float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
	return cross(normal, tangent.xyz) *
		(binormalSign * unity_WorldTransformParams.w);
}

Interpolators MyVertexProgram (VertexData v) {
	Interpolators i;
	i.position = UnityObjectToClipPos(v.position);
	i.worldPos = mul(unity_ObjectToWorld, v.position);
	i.normal = UnityObjectToWorldNormal(v.normal);

	#if defined(BINORMAL_PER_FRAGMENT)
		i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	#else
		i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
		i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
	#endif
		
	i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
	i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
	i.uvHeat.xy =  TRANSFORM_TEX(v.uv, _HeatTex);
	i.originNormal = float3(1,1,1);
	i.worldNormal = i.normal;
	ComputeVertexLightColor(i);
	return i;
}

UnityLight CreateLight (Interpolators i) {
	UnityLight light;

	#if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
		light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
	#else
		light.dir = _WorldSpaceLightPos0.xyz;
	#endif
	
	UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
	light.color = _LightColor0.rgb * attenuation;
	light.ndotl = DotClamped(i.normal, light.dir);
	return light;
}

UnityIndirect CreateIndirectLight (Interpolators i) {
	UnityIndirect indirectLight;
	indirectLight.diffuse = 0;
	indirectLight.specular = 0;

	#if defined(VERTEXLIGHT_ON)
		indirectLight.diffuse = i.vertexLightColor;
	#endif

	#if defined(FORWARD_BASE_PASS)
		indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
	#endif

	return indirectLight;
}

void InitializeFragmentNormal(inout Interpolators i,bool isWater) {
	float3 Normal ;
	if(isWater){
		Normal=UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw+sin(_Time.x)), _DetailBumpScale);
	}else{
		Normal=UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
	}
	i.worldNormal = normalize(i.worldNormal);
	i.originNormal = Normal;
	float3 tangentSpaceNormal = Normal;
	#if defined(BINORMAL_PER_FRAGMENT)
		float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
	#else
		float3 binormal = i.binormal;
	#endif
	
	i.normal = normalize(
		tangentSpaceNormal.x * i.tangent +
		tangentSpaceNormal.y * binormal +
		tangentSpaceNormal.z * i.normal
	);
}



bool isWater(float3 col){
	return (col.r+col.g+col.b<0.4 && col.b>col.r);
}
float4 MyFragmentProgram (Interpolators i) : SV_TARGET {
	
	
	float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
	float3 col = tex2D(_MainTex, i.uv.xy).rgb;
	bool isWaters = isWater(col);
	InitializeFragmentNormal(i,isWaters);
	
	float3 albedo =col.rgb* _Tint.rgb;
	if(isWaters){
		albedo += _WaterTint.rgb;
		albedo *= tex2D(_DetailTex, i.uv.zw*1000) * unity_ColorSpaceDouble;	

		_Metallic = _WaterMetallic;
		_Smoothness = _WaterSmoothness;
	}else{
	}
	
	
	
	float3 specularTint;
	float oneMinusReflectivity;
	albedo = DiffuseAndSpecularFromMetallic(
		albedo, _Metallic, specularTint, oneMinusReflectivity
	);
	UnityLight Li = CreateLight(i);
	UnityIndirect Ili = CreateIndirectLight(i);
	float4 ret = 
	 UNITY_BRDF_PBS(
		albedo, specularTint,
		oneMinusReflectivity, _Smoothness,
		i.normal, viewDir,
		Li,Ili 
	);
	
	if(!isWaters)
	{
		float normal_to_light = distance(i.worldNormal,Li.dir);
		float3 col_heat = tex2D(_HeatTex, i.uvHeat.xy).rgb;
		if(col_heat.g>0.6 )
		{
			float weight1 = FresnelLerp(0,1,(normal_to_light));
			weight1 = clamp(0,1,weight1);
			float weight =  abs(i.originNormal.y)+abs(i.originNormal.x)+abs(i.originNormal.x);
			weight*=weight1;
			weight = abs(0.2-weight);
			weight/=2;
			
			ret +=_Emission*weight;
		}
	}
	return ret;
}

#endif