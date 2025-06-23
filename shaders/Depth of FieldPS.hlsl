struct PSInput
{
	float4 Position : SV_POSITION;
	float2 UV : TEXCOORD;
};

cbuffer cbPerFrame : register(b0)
{
	float4x4 matVP;
	float2 screenSize;
};


Texture2D Position : register(t0);
Texture2D FinalPass : register(t1);
SamplerState smp : register(s0);

float gaussian(float x, float sigma)
{
    return exp(-0.5 * (x * x) / (sigma * sigma));
}

float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	
	float4 blurFinal;
	float4 Final = FinalPass.Sample(smp,pin.UV);
	
	//return Final;
	
	float Depth = mul(Position.Sample(smp,pin.UV),matVP).z / 3;
	Depth += 1;
	
	float weightsum;
	int size = 4;
	float2 texelSize = 1/screenSize;

	//blur
	for (int y = -size ; y < size; y++)
	{
		for (int x = -size ; x < size; x++)
		{
		float2 offset = float2(x,y) * texelSize;
		float circle = length(float2(x,y));
		float weight = gaussian(circle,size);
		blurFinal += (FinalPass.Sample(smp, pin.UV + offset)) * weight;
		weightsum += weight;
		}
	}

	blurFinal = blurFinal/weightsum;
	
	return lerp(Final,blurFinal,saturate(Depth));

}