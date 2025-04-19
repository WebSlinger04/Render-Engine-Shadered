struct PSInput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR;
};

float4 main(PSInput pin) : SV_TARGET
{
	if (pin.Color.a == 0)
	{
		discard;
	};
	return pin.Color;
}
