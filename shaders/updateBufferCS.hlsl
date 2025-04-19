RWStructuredBuffer<float4> data : register(u0);
	
[numthreads(8, 1, 1)]
void main(uint3 id : SV_DispatchThreadID)
{
		for (uint i = 0; i < 72; i++)
    {
        data[i] = 0;
    }
}