// Texture to write to
RWTexture2D<float> outputTexture : register(u0);
RWStructuredBuffer<float4> data : register(u1);
Texture2D shadowMap1 : register(t0);
Texture2D shadowMap2 : register(t1);
Texture2D shadowMap3 : register(t2);
Texture2D shadowMap4 : register(t3);
Texture2D shadowMap5 : register(t4);
Texture2D shadowMap6 : register(t5);
Texture2D shadowMap7 : register(t6);
Texture2D shadowMap8 : register(t7);
Texture2D shadowMap9 : register(t8);
Texture2D shadowMap10 : register(t9);
SamplerState smp : register(s0);

cbuffer cbPerFrame : register(b0)
{
	int Frame;
};

int updateShadow = 600;

float Texture(int index, float2 UV) 
{
	switch (index)
	{
		case 0:
			 return shadowMap1.Sample(smp,UV).x;
			 break;
		case 1:
			return shadowMap2.Sample(smp,UV).x;
			break;
		case 2:
			return shadowMap3.Sample(smp,UV).x;
			break;
		case 3:
			return shadowMap4.Sample(smp,UV).x;
			break;
		case 4:
			return shadowMap5.Sample(smp,UV).x;
			break;
		case 5:
			return shadowMap6.Sample(smp,UV).x;
			break;
		case 6:
			return shadowMap7.Sample(smp,UV).x;
			break;
		case 7:
			return shadowMap8.Sample(smp,UV).x;
			break;
		case 8:
			return shadowMap9.Sample(smp,UV).x;
			break;
		default:
			return 0;
			break;
			
				
	}
}

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
			
			outputTexture[selector] =  Texture(i,UV);
	
		}
	}
}