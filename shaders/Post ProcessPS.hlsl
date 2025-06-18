Texture2D Position : register(t0);
Texture2D SceneLighting : register(t1);
Texture2D EmissivePass : register(t2);
Texture2D AoPass: register(t3);
Texture2D SceneTranslucent : register(t4);
Texture2D SceneTranslucentDepth : register(t5);
SamplerState smp : register(s0);

float3 PP_ECS;
float3x3 PP_LGG;
float4 PP_Fog;
float fogStart;

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

float4 ColorGrade(float4 SceneColor)
{
	SceneColor = saturate(SceneColor * pow(2,PP_ECS.x));	
	SceneColor = saturate((SceneColor - 0.5) * (1+(PP_ECS.y*.1)) + 0.5);
	
	float Luminance = (SceneColor.x + SceneColor.y + SceneColor.z)/3;
	SceneColor = saturate(lerp(Luminance,SceneColor,PP_ECS.z));
	SceneColor = saturate(SceneColor + float4(PP_LGG[0],1));
	SceneColor = saturate(SceneColor * float4(PP_LGG[1],1));
	SceneColor = saturate(pow(SceneColor,1/float4(PP_LGG[2],1)));
	return SceneColor;
}

float Vignette(float2 UV)
{
	float vignette = distance(UV,float2(0.5,0.5));
	vignette = saturate(pow(vignette,2)) * 1.25;
	vignette = saturate((1-vignette));
	return vignette;
}

float4 Fog(float Depth)
{
	float4 fogSceneColor = float4(PP_Fog.xyz,1);
	float fogStrength = PP_Fog.a;
	float4 fog = saturate ( (1-Depth) -fogStart);
	fog = fog * fogSceneColor * fogStrength;
	return fog;
}

float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float4 Position = Position.Sample(smp,pin.UV);
	float4 SceneColor = SceneLighting.Sample(smp, pin.UV);
	float4 Emissive = EmissivePass.Sample(smp, pin.UV);
	float AO = AoPass.Sample(smp,pin.UV);
	float4 Translucent = SceneTranslucent.Sample(smp,pin.UV);
	float TranslucentDepth = SceneTranslucentDepth.Sample(smp,pin.UV);
	SceneColor *= AO;
	
	//translucent
	if (Position.a < TranslucentDepth.x)
	{
		SceneColor = float4(lerp(SceneColor.xyz,Translucent.xyz,Translucent.a),1);
	}
	return saturate(ColorGrade(SceneColor) + Fog(Position.a)) * Vignette(pin.UV)  + Emissive ;
}