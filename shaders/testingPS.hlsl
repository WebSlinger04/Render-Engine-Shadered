//tweakables
Texture2D texCA : register(t0);
Texture2D texNormal : register(t1);
Texture2D texORM : register(t2);
SamplerState smp : register(s0);
float2 TextureTile;

struct PSInput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR;
	float2 UV;
	
	float3 wPosition;
};

struct PSOut
{
	float3 Color;
	float4 Position;
	float3 Normal;
};

PSOut main(PSInput pin)
{
	PSOut pout = (PSOut)0;
	
	//sample maps
	float2 uvMap = pin.UV;
	float texels = 3;
	float offset = 0;
	float x = offset%texels * 1/texels;
	float y = -floor(offset/texels) * 1/texels + 1-1/texels;
	float2 clipUv = saturate(pin.UV / texels + float2(x,y));
	clipUv = saturate(clipUv);
	clipUv.x = (clipUv.x < x) ||  (clipUv.x > x + 1/texels) ? 0 : clipUv.x;
	clipUv.y = (clipUv.y < y) ||  (clipUv.y > y + 1/texels) ? 0 : clipUv.y;
	
	
	
	float4 colorMap = texCA.Sample(smp,clipUv);
	pout.Color = colorMap;
	return pout;
}
