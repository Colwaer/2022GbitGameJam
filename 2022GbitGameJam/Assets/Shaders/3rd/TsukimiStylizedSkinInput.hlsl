#ifndef UNIVERSAL_LIT_INPUT_INCLUDED
    #define UNIVERSAL_LIT_INPUT_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
    #include "TsukimiMath.hlsl"

    CBUFFER_START(UnityPerMaterial)
        float4 _BaseMap_ST;
        float4 _BumpMap_ST;
        half4 _BaseColor;
        half4 _SpecColor;
        half4 _EmissionColor;
        half _Cutoff;
        half _Smoothness;
        half _Metallic;
        
        half _BumpScale;

        half _OcclusionStrength;

        //StylizedLit

        // rim
        float _OffsetMul;
        float _Threshold;
        float _RimIntensity;

        // Diffuse
        half _DiffuseRoughness;
        half _WarpValue;
        float4 _PreIntegratedBRDFMap_ST;
        float _PreIntegratedBRDFPercentage;
        
        half4 _SpecularColor;
        float _SpecularRoughness;
        float _SpecularIntensity;
        half4 _ClearcoatColor;
        float _ClearcoatRoughness;
        float _ClearcoatIntensity;

        // SSS
        half4 _SSSColor;
        float _FrontSSSDistortion;
        float _FrontSSSPower;
        float _FrontSSSIntensity;
        float _BackSSSDistortion;
        float _BackSSSPower;
        float _BackSSSIntensity;

        float _GIIntensity;

    CBUFFER_END
    TEXTURE2D(_PreIntegratedBRDFMap);       SAMPLER(sampler_PreIntegratedBRDFMap);
    TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
    TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
    TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);
    TEXTURE2D(_BrushTex);           SAMPLER(sampler_BrushTex);          
    TEXTURE2D(_CameraDepthTexture);           SAMPLER(sampler_CameraDepthTexture);

    #ifdef _SPECULAR_SETUP
        #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
    #else
        #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
    #endif

    // SSS
    half3 SubsurfaceScattering(half3 N, half3 L, half3 V, half sssDistortion, half sssPower, half sssIntensity, half3 sssColor) 
    {
        half3 H = L + N * sssDistortion;
        return pow(saturate(dot(V, -H)), sssPower) * sssIntensity * sssColor;
    }




    struct SkinSurfaceData
    {
        half3 albedo;
        half diffuseRoughness;
        half3 specular;
        half specularRoughness;
        half3 clearcoat;
        half clearcoatRoughness;
        half3 metallic;
        half3 normalTS;
        half3 emission;
    };

    inline void InitializeSkinSurfaceData(float2 uv, out SkinSurfaceData outSkinSurfaceData)
    {
        outSkinSurfaceData = (SkinSurfaceData)0;

        half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
        outSkinSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
        outSkinSurfaceData.diffuseRoughness = _DiffuseRoughness;
        outSkinSurfaceData.specular = _SpecularColor.rgb;
        outSkinSurfaceData.specularRoughness = _SpecularRoughness;
        outSkinSurfaceData.clearcoat = _ClearcoatColor.rgb;
        outSkinSurfaceData.clearcoatRoughness = _ClearcoatRoughness;
        outSkinSurfaceData.metallic = _Metallic;
        #ifdef _NORMALMAP
            outSkinSurfaceData.normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, uv * _BumpMap_ST.xy + _BumpMap_ST.zw), _BumpScale);
        #else
            outSkinSurfaceData.normalTS =  half3(0.0h, 0.0h, 1.0h);
        #endif
    //outSkinSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), 1);
    
}   

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

    #ifdef _METALLICSPECGLOSSMAP
        specGloss = SAMPLE_METALLICSPECULAR(uv);
        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _Smoothness;
        #else
            specGloss.a *= _Smoothness;
        #endif
    #else // _METALLICSPECGLOSSMAP
        #if _SPECULAR_SETUP
            specGloss.rgb = _SpecColor.rgb;
        #else
            specGloss.rgb = _Metallic.rrr;
        #endif

        #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            specGloss.a = albedoAlpha * _Smoothness;
        #else
            specGloss.a = _Smoothness;
        #endif
    #endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
    #ifdef _OCCLUSIONMAP
        // TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
        #if defined(SHADER_API_GLES)
            return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
        #else
            half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
            return LerpWhiteTo(occ, _OcclusionStrength);
        #endif
    #else
        return 1.0;
    #endif
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
    outSurfaceData = (SurfaceData)0;

    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

    #if _SPECULAR_SETUP
        outSurfaceData.metallic = 1.0h;
        outSurfaceData.specular = specGloss.rgb;
    #else
        outSurfaceData.metallic = specGloss.r;
        outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
    #endif

    outSurfaceData.smoothness = specGloss.a;
    outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.occlusion = SampleOcclusion(uv);
    outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
