cbuffer cbPerFrame : register(b0)
{
	float2 screenSize;
	float4x4 matVP;
	float4x4 matProject;
};

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
Texture2D Noise : register(t6);
Texture2D NNoise : register(t7);
SamplerState smp : register(s0);

float gaussian(float x, float sigma)
{
    return exp(-0.5 * (x * x) / (sigma * sigma));
}

float randomNumber(float maxNumber)
{
	return 	frac(sin(dot(maxNumber/15,float2(12.9898,78.233)))*43758.5453123);

}

float4 main(PSInput pin) : SV_TARGET
{
	pin.UV.y = 1-pin.UV.y;
	float4 Position = PositionPass.Sample(smp, pin.UV);
	float4 Normal = NormalPass.Sample(smp, pin.UV);
	float4 Lighting = LightingPass.Sample(smp, pin.UV);
	float4 Translucent = TranslucentPass.Sample(smp, pin.UV);
	float4 TDepth = TranslucentDepth.Sample(smp, pin.UV);
	float4 NoiseMap = Noise.Sample(smp, 6*pin.UV*float2(1,screenSize.y/screenSize.x));
	float4 NNoiseMap = NNoise.Sample(smp, 5*pin.UV*float2(1,screenSize.y/screenSize.x));
	float4 Color = Lighting;
	
	if (Position.a < TDepth.x)
	{
		Color = float4(lerp(Lighting.xyz,Translucent.xyz,Translucent.a),1);
	}
	
	//Anti-aliasing
	
	//Bloom
	float4 Emissive;
	float weightsum;
	int size = 15;
	float blur = 5;
	float2 texelSize = 1/screenSize;
	for (int y = -size ; y < size; y++)
	{
		for (int x = -size ; x < size; x++)
		{
		float2 offset = float2(x,y) * texelSize;
		float circle = length(float2(x,y));
		float weight = gaussian(circle,blur);
		Emissive += (EmissivePass.Sample(smp, pin.UV + offset)) * weight;
		weightsum += weight;
		}
	}

	Emissive = Emissive/weightsum;
	
	//Color Grade
	float exposure = 0;
	float contrast = 1;
	float saturation = 1;
	float3 lift = float3(0.03,0,0.05); 
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
	
	//SSAO
	float ao = 0;
	float aoSamples = 256;
	for (int i = 0; i < aoSamples ; i ++)
	{
		float3 random = float3(randomNumber(i) * 2 - 1,
						randomNumber(i * 3 + 2),
						randomNumber(i * 2 + 1) * 2 - 1);
		random = normalize(random);
		float scale = float(i)/aoSamples;
		random *= lerp(0.1,1, scale * scale);
		
		float3 radius = 0.001 * random;
		float textureOffset =  PositionPass.Sample(smp, pin.UV + radius.xz).a;
		if (distance(textureOffset,Position.a + radius.y) <= 1)
		{
				ao += (textureOffset >= Position.a + radius.y) ? 1 :0;
		}
	}
	
	
	ao =  1 - (ao/aoSamples);
	return ao;
	return (Color * ao) + Emissive * vignette;
}