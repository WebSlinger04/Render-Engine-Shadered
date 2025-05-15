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
	
	if (Position.a < TDepth.x)
	{
		Color = float4(lerp(Lighting.xyz,Translucent.xyz,Translucent.a),1);
	}
	
	//Color Grade
	float exposure = 0;
	float contrast = 1;
	float saturation = 1;
	float3 lift = float3(0.03,0.0,0.07); 
	float3 gain = float3(1,1,1);
	float3 gamma = float3(1,1,1);
	
	Color = saturate(Color * pow(2,exposure));
	Color = saturate((Color - 0.5) * contrast + 0.5);
	float Luminance = (Color.x + Color.y + Color.z)/3;
	Color = saturate(lerp(Luminance,Color,saturation));
	Color = saturate(Color + float4(lift,1));
	Color = saturate(Color * float4(gain,1));
	Color = saturate(pow(Color,1/float4(gamma,1)));
	
	//Vignette
	float vignette = distance(pin.UV,float2(0.5,0.5));
	vignette = saturate(pow(vignette,2));
	vignette = saturate((1-vignette)+.1);
	
	//fog
	float4 fogColor = float4(0,150,200,255);
	float fogStrength = .004;
	float4 fog = saturate ( (1-Position.a) -.88);
	fog = fog * fogColor * fogStrength;
	
	Color *= AO;
	return (Color + Emissive + fog) * vignette;
}