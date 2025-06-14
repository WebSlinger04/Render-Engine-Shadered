cbuffer cbPerFrame : register(b0)
{
	float2 screenSize;
	float4x4 matVP;
	float4x4 matView;
};

struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

Texture2D SceneLighting : register(t0);
Texture2D EmissivePass : register(t1);
SamplerState smp : register(s0);

float gaussian(float x, float sigma)
{
    return exp(-0.5 * (x * x) / (sigma * sigma));
}

float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;

	//Bloom
	float4 Emissive;
	float4 EmissiveLighting;

	float weightsum;
	int Sample = 3;
	float size = 2;
	float2 texelSize = 1/screenSize;
	float threshold = 0.7;

	//blur
	for (int y = -Sample ; y < Sample; y++)
	{
		for (int x = -Sample ; x < Sample; x++)
		{
		float2 offset = float2(x,y) * texelSize * size;
		float circle = length(float2(x,y));
		float weight = gaussian(circle,size);

		if (offset.x+pin.UV.x < 0 || offset.x+pin.UV.x > 1 || offset.y+pin.UV.y < 0 || offset.y+pin.UV.y > 1)
		{
			continue;
		}

		//Bloom due to emissive
		Emissive += (EmissivePass.Sample(smp, saturate(pin.UV + offset))) * weight;


		/* //Bloom due to screen luminosity
		EmissiveLighting = SceneLighting.Sample(smp,pin.UV + offset) * weight;
		float Luminosity = (EmissiveLighting.x + EmissiveLighting.y + EmissiveLighting.z )/3;
		Luminosity = Luminosity > threshold ? Luminosity : 0;
		Emissive += EmissiveLighting * Luminosity * .2; */
		weightsum += weight;
		}
	}
	float4 Result =  EmissivePass.Sample(smp,pin.UV) + saturate(Emissive/weightsum-EmissivePass.Sample(smp,pin.UV)); 
	return Result;
}