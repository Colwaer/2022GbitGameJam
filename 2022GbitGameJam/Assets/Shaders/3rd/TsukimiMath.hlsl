


half3 Pow5(half3 a)
{
    half3 a2 = a * a;
    return a2 * a2 * a;
}

half Pow5(half a)
{
    half a2 = a * a;
    return a2 * a2 * a;
}

// PBR Function

float3 DisneyBurleyDiffuse(float3 diffuseColor, float roughness, float NdotV, float NdotL, float VdotH)
{
    float FD90 = 0.5 + 2 * VdotH * VdotH * roughness;
    float FdV = 1 + (FD90 - 1) * Pow5(1 - NdotV);
    float FdL = 1 + (FD90 - 1) * Pow5(1 - NdotL);
    return diffuseColor * ((1 / PI) * FdV * FdL);
}

// F
half3 SchlickFresnel(float VoH, float3 F0)
{
    return F0 + (1 - F0) * Pow5(1 - VoH);
}

// D
half TrowbridgeReitzGGX(half NdotH, half roughness)
{
    half a = roughness * roughness;
    half a2 = a * a;
    half nom = a2;
    half denom = (NdotH * NdotH * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom + 0.00001f;
    return nom / denom;
}

// G and V
// direct : k = (roughness + 1) * (roughness + 1) * 0.25
// IBL    : k = roughness * roughness * 0.5
half GeometrySchlickGGX(half NdotV, half k)
{
    half nom = NdotV;
    half denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}

half UE4GeometrySmith(half NdotV, half NdotL, half k)
{
    half ggx1 = GeometrySchlickGGX(NdotV, k);
    half ggx2 = GeometrySchlickGGX(NdotL, k);
    return ggx1 * ggx2;
}

half GeometrySmithGGX(half NdotV, half a)
{
    half a2 = a * a;
    half NdotV2 = NdotV * NdotV;
    return 2 * NdotV / (NdotV + sqrt(a2 + NdotV2 - a2 * NdotV2));
}

half VisiblityTerm(half NdotV, half NdotL, half roughness)
{
    half a = (0.5 + roughness * 0.5) * (0.5 + roughness * 0.5);
    return GeometrySmithGGX(NdotV, a) * GeometrySmithGGX(NdotL, a);
}

half3 DirectSpecularBRDF(half roughness, half NdotV, half NdotL, half NdotH, half VdotH)
{
    half3 F = SchlickFresnel(VdotH, half3(0.04, 0.04, 0.04));
    half D = TrowbridgeReitzGGX(NdotH, roughness);
    half V = VisiblityTerm(NdotV, NdotL, roughness);//VisiblityTerm(NdotV, NdotL, roughness);

    return F * D * V;
}