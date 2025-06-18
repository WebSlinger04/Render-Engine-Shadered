// Texture to write to
RWTexture2D<float> outputTexture : register(u0);
RWStructuredBuffer<float4> data : register(u1);
Texture2D shadowMap1 : register(t0);
SamplerState smp : register(s0);

cbuffer cbPerFrame : register(b0)
{
	int Frame;
};

int updateShadow = 600;

// Thread group size (e.g., 16x16 threads per group)
[numthreads(16, 16, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
	
	int texels = 3;
	if (Frame % updateShadow == 1)
	{
		for (int i = 0; i < pow(texels,2); i++)
		{
			float2 texSize = float2(4096,4096);
			float2 UV = (dispatchThreadID/texSize);
			float2 selector = dispatchThreadID.xy / texels;
			
			int x = i%texels;
			int y = floor(i/texels);
			selector = selector + ( (texSize/texels) * float2(x,-y) ) + ( (texSize/texels) * float2(0,texels-1) );
			
			if (Frame/10%pow(texels,2) == i)
			{
				outputTexture[selector] = shadowMap1.Sample(smp,UV).x;
			}
	
	
		}
	}
}