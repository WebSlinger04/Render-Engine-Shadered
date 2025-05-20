struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

Texture2D PositionPass : register(t0);
Texture2D NormalPass : register(t1);
Texture2D LightingPass : register(t2);
Texture2D EmissivePass : register(t3);
Texture2D TranslucentPass : register(t4);
Texture2D TranslucentDepth : register(t5);
Texture2D AoPass: register(t6);
SamplerState smp : register(s0);


float3 PP_ECS;
float3x3 PP_LGG;
float4 PP_Fog;
float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float4 Position = PositionPass.Sample(smp, pin.UV);
	float3 Normal = NormalPass.Sample(smp, pin.UV);
	float4 Lighting = LightingPass.Sample(smp, pin.UV);
	float4 Emissive = EmissivePass.Sample(smp, pin.UV);
	float4 Translucent = TranslucentPass.Sample(smp, pin.UV);
	float4 TDepth = TranslucentDepth.Sample(smp, pin.UV);
	float AO = AoPass.Sample(smp,pin.UV);
	float4 Color = Lighting;
	
	//Color Grade
	float contrast = 1;
	
		if (Position.a < TDepth.x)
	{
		Color = float4(lerp(Lighting.xyz,Translucent.xyz,Translucent.a),1);
	}
	
	Color = saturate(Color * pow(2,PP_ECS.x));	
	Color = saturate((Color - 0.5) * (1+(PP_ECS.y*.1)) + 0.5);
	
	float Luminance = (Color.x + Color.y + Color.z)/3;
	Color = saturate(lerp(Luminance,Color,PP_ECS.z));
	Color = saturate(Color + float4(PP_LGG[0],1));
	Color = saturate(Color * float4(PP_LGG[1],1));
	Color = saturate(pow(Color,1/float4(PP_LGG[2],1)));
	
	//Vignette
	float vignette = distance(pin.UV,float2(0.5,0.5));
	vignette = saturate(pow(vignette,2.5));
	vignette = saturate((1-vignette));
	
	//fog
	float4 fogColor = float4(PP_Fog.xyz,1);
	float fogStrength = PP_Fog.a;
	float4 fog = saturate ( (1-Position.a) -.85);
	fog = fog * fogColor * fogStrength;
	
	Color *= AO;
	return (Color + Emissive + fog) * vignette;
}