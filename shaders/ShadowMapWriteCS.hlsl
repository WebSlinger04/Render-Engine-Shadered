// Compute Shader

// A read/write texture
RWTexture2D<float4> OutputTexture : register(u0);

[numthreads(8, 8, 1)]
void CSMain(uint3 DTid : SV_DispatchThreadID)
{
    // Write a solid color to the texture
    float2 uv = DTid.xy;
    OutputTexture[uv] = float4(1.0, 0.0, 0.0, 1.0); // Red
}