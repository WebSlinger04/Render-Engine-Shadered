cbuffer cbPerFrame : register(b0)
{
    float2 screenSize;
    float4x4 matVP;

};

struct PSInput
{
	float4 Position : SV_POSITION;
    float2 UV : TEXCOORD;
};

Texture2D Color : register(t0);
Texture2D Depth : register(t1);
Texture2D Normal : register(t2);
Texture2D HT : register(t3);
SamplerState smp : register(s0);

float4 HalfTone(float2 UV,float4 Color,float4 ColorResult)
{
    float screenRatio = screenSize.x/screenSize.y;
    float4 HalfToneTex = HT.Sample(smp,UV*float2(screenRatio,1)*200)*20;
    float3 Color2 = normalize(Color);
    float Mask = Color2.x + Color2.y*(0.5)+Color2.z*(0.25);
    Mask = pow(Mask,3);
    Mask = saturate(Mask*HalfToneTex);
    float4 HT = lerp(Color,ColorResult,Mask*ColorResult.a);
    return HT;
}

float4 Outline(float2 UV,float4 Color)
{  
    float result;
    int range = 2;
    float strength = 0.75;
    float4 lineColor  = float4(0,0,0,1);
    float2 offset = 1 / screenSize;
    float gDepth = Depth.Sample(smp,UV).a;
    float3 gNormal = Normal.Sample(smp,UV);
    for(int x = -range; x < range; x++)
    {
        for(int y = -range; y < range; y++)
        {
            float D = Depth.Sample(smp,UV + offset*float2(x,y)).a;
            float3 N = Normal.Sample(smp,UV + offset*float2(x,y));

            result += (abs(gDepth-D) > .005) ? 1 : 0;
            result += (abs(dot(gNormal,N)) < .6) ? 1 : 0;
        }

    }
    result =  1 - saturate(result/ pow(range*2 + 1,2) )*strength;
    return lerp(lineColor,Color,result);
}


float4 main(PSInput pin)
{
    pin.UV.y = 1-pin.UV.y;
    float4 result;
    float4 Col = Color.Sample(smp,pin.UV);

    result = Outline(pin.UV,Col);
    //result = HalfTone(pin.UV,result,float4(1,0.5,0.25,0.2));
    return result;
}