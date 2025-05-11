struct PSInput
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR;
};

bool DebugLights;
	
float4 main(PSInput pin) : SV_TARGET
{
	if (DebugLights)
	{
		discard;
	};
	
	if (pin.Color.x == 0 && pin.Color.y == 0 && pin.Color.z == 0 && pin.Color.a == 0)
	{
		discard;
	};
	
	return pin.Color;
	
}
