// Texture to write to
RWTexture2D<float> outputTexture : register(u0);
Texture2D shadowMap1 : register(t0);
Texture2D shadowMap2 : register(t1);
Texture2D shadowMap3 : register(t2);
SamplerState smp : register(s0);

cbuffer cbPerFrame : register(b0)
{
	float2 viewSize;
};


// Thread group size (e.g., 16x16 threads per group)
[numthreads(32, 32, 1)]
void main(uint3 dispatchThreadID : SV_DispatchThreadID)
{
	int texels = 2;
	for (int i = 0; i < pow(texels,2) ; i++)
	{
		float2 texSize = float2(1024,1024);
		float2 UV = (dispatchThreadID/texSize);
		float2 selector = dispatchThreadID.xy / texels;
		
		int x = i%texels;
		int y = floor(i/texels);
		selector = selector + ( (texSize/texels) * float2(x,-y) ) + ( (texSize/texels) * float2(0,texels-1) );
		
		switch (i)
		{
			case 0:
				 outputTexture[selector] = shadowMap1.Sample(smp,UV);
				 break;
			case 1:
				outputTexture[selector] = shadowMap2.Sample(smp,UV);
				break;
			case 2:
				outputTexture[selector] = shadowMap3.Sample(smp,UV);
				break;
		
		}
	}

}