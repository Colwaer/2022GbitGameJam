Shader "Tsukimi/Stylized Skin"
{
    Properties
    {
        [Title(_, Main Samples)]

        
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        [Sub(Group1)][Toggle(_NORMALMAP)] _EnableNormal ("Enable Normal", Int) = 1
        [Normal] _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Bump Scale", Range(0.0, 3.0)) = 1.0
        [Toggle(_ENABLE_GI)] _EnableGI ("Enable Global Illumination", Int) = 1
        
        [Main(Group1, _KEYWORD, on)]
        _group1 ("Group - Default Open", float) = 1
        [Sub(Group1)]_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Sub(Group1)]_OffsetMul ("_RimWidth", Range(0, 0.1)) = 0.012
        [Sub(Group1)]_Threshold ("_Threshold", Range(0, 1)) = 0.09
        [Sub(Group1)]_RimIntensity ("Rim Intensity", Range(0, 1)) = 0.09

        
        [Space(30)]
        
        [Header(Diffuse)]
        _DiffuseRoughness("Diffuse Roughness", Range(0.0, 1.0)) = 0.5
        _WarpValue("Warp Value", Range(0.0, 3.0)) = 0


        
        
        [Space(30)]

        [Header(Pre Integrated BRDF)]
        [Toggle(_ENABLE_PRE_INTEGRATED_BRDF)] _EnablePreIntegratedBRDF ("Enable Pre-Integrated BRDF", Int) = 0
        _PreIntegratedBRDFMap("Pre-Integrated BRDF Map", 2D) = "white" {}
        _PreIntegratedBRDFPercentage("Pre-Integrated BRDF Percentage", Range(0.0, 1.0)) = 0.8

        [Header(Skin SSS)]
        [Toggle(_ENABLE_SSS)] _EnableSSS ("Enable SSS", Int) = 1
        [HDR]_SSSColor("SSS Color", Color) = (1, 0.56, 0.56,1)
        _FrontSSSDistortion("Front SSS Distortion", Range(0.0, 1.0)) = 0.3
        _FrontSSSPower("Front SSS Power", Range(0.25, 4)) = 1
        _FrontSSSIntensity("Front SSS Intensity", Range(0.0, 3.0)) = 0.5
        _BackSSSDistortion("Back SSS Distortion", Range(0.0, 1.0)) = 1
        _BackSSSPower("Back SSS Power", Range(0.25, 4)) = 2
        _BackSSSIntensity("Back SSS Intensity", Range(0.0, 3.0)) = 0.15
        
        [Header(Highlight Layer 1 (Specular))]
        [Toggle(_ENABLE_SPECULAR)] _EnableSpecular ("Enable Specular", Int) = 1
        [HDR]_SpecularColor("Specular Color", Color) = (1, 0.49, 0.45, 1)
        _SpecularRoughness("Specular Roughness", Range(0.0, 1.0)) = 0.6
        _SpecularIntensity("Specular Intensity", Range(0.0, 3.0)) = 2
        
        [Header(Highlight Layer 2 (Clearcoat))]
        [Toggle(_ENABLE_CLEARCOAT)] _EnableClearcoat ("Enable Clearcoat", Int) = 1
        [HDR]_ClearcoatColor("Clearcoat Color", Color) = (1,1,1,1)
        _ClearcoatRoughness("Clearcoat Roughness", Range(0.0, 1.0)) = 0.1
        _ClearcoatIntensity("Clearcoat Intensity", Range(0.0, 3.0)) = 2
        
        

        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GIIntensity("GI Intensity", Range(0,2)) = 1
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        [HideInInspector] _Blend("__Blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__AlphaClip", Float) = 0.0
        [HideInInspector] _SrcBlend("__SrcBlend", Float) = 1.0
        [HideInInspector] _DstBlend("__DstBlend", Float) = 0.0
        [HideInInspector] _ZWrite("__ZWrite", Float) = 1.0
        [HideInInspector] _Cull("__Cull", Float) = 2.0
    }

    SubShader
    {

        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}

        Pass
        {
            
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _OCCLUSIONMAP

            #pragma shader_feature _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            #pragma shader_feature _ENABLE_SPECULAR
            #pragma shader_feature _ENABLE_CLEARCOAT
            #pragma shader_feature _ENABLE_SSS
            #pragma shader_feature _ENABLE_PRE_INTEGRATED_BRDF
            #pragma shader_feature _ENABLE_GI
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "TsukimiStylizedSkinInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            //#include "LitInput.hlsl"
            //#include "LitForwardPass.hlsl"


            #pragma multi_compile _ _USEBRUSHTEX_ON

            #ifndef UNIVERSAL_FORWARD_LIT_PASS_INCLUDED
                #define UNIVERSAL_FORWARD_LIT_PASS_INCLUDED


                struct Attributes
                {
                    float4 positionOS   : POSITION;
                    float3 normalOS     : NORMAL;
                    float4 tangentOS    : TANGENT;
                    float2 texcoord     : TEXCOORD0;
                    float2 lightmapUV   : TEXCOORD1;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct Varyings
                {
                    float2 uv                       : TEXCOORD0;
                    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

                    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                        float3 positionWS               : TEXCOORD2;
                    #endif

                    float3 normalWS                 : TEXCOORD3;
                    #ifdef _NORMALMAP
                        float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: sign
                    #endif
                    float3 viewDirWS                : TEXCOORD5;

                    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        float4 shadowCoord              : TEXCOORD7;
                    #endif

                    float4 positionCS               : SV_POSITION;
                    float3 positionVS               :TEXCOORD8;
                    float4 positionNDC              :TEXCOORD9;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                
                void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
                {
                    inputData = (InputData)0;

                    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                        inputData.positionWS = input.positionWS;
                    #endif

                    half3 viewDirWS = SafeNormalize(input.viewDirWS);
                    #ifdef _NORMALMAP 
                        float sgn = input.tangentWS.w;      // should be either +1 or -1
                        float3 bitangent = sgn * cross(input.normalWS.xyz, input.tangentWS.xyz);
                        inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, bitangent.xyz, input.normalWS.xyz));
                    #else
                        inputData.normalWS = input.normalWS;
                    #endif

                    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
                    inputData.viewDirectionWS = viewDirWS;

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        inputData.shadowCoord = input.shadowCoord;
                    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                        inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
                    #else
                        inputData.shadowCoord = float4(0, 0, 0, 0);
                    #endif

                    inputData.fogCoord = input.fogFactorAndVertexLight.x;
                    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
                    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
                    inputData.shadowMask = SAMPLE_SHADOWMASK(input.lightmapUV);
                }

                ///////////////////////////////////////////////////////////////////////////////
                //                  Vertex and Fragment functions                            //
                ///////////////////////////////////////////////////////////////////////////////

                // Used in Standard (Physically Based) shader
                Varyings LitPassVertex(Attributes input)
                {
                    Varyings output = (Varyings)0;

                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_TRANSFER_INSTANCE_ID(input, output);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                    
                    // normalWS and tangentWS already normalize.
                    // this is required to avoid skewing the direction during interpolation
                    // also required for per-vertex lighting and SH evaluation
                    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                    float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
                    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

                    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

                    // already normalized from normal transform to WS.
                    output.normalWS = normalInput.normalWS;
                    output.viewDirWS = viewDirWS;
                    #ifdef _NORMALMAP
                        real sign = input.tangentOS.w * GetOddNegativeScale();
                        output.tangentWS = half4(normalInput.tangentWS.xyz, sign);
                    #endif

                    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
                    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

                    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

                    #if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
                        output.positionWS = vertexInput.positionWS;
                    #endif

                    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                        output.shadowCoord = GetShadowCoord(vertexInput);
                    #endif

                    output.positionCS = vertexInput.positionCS;
                    output.positionVS = vertexInput.positionVS;
                    output.positionNDC = vertexInput.positionNDC;
                    return output;
                }

                float4 TransformHClipToViewPortPos(float4 positionCS)
                {
                    float4 o = positionCS * 0.5f;
                    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
                    o.zw = positionCS.zw;
                    return o / o.w;
                }

                half3 DirectDiffuse(half metallic, half NdotL, half VdotH)
                {
                    half Ks = SchlickFresnel(VdotH, half3(0.04, 0.04, 0.04)).r;
                    half warpNdotL = max(0, (NdotL + _WarpValue) / (1 + _WarpValue));

                    return (1 - Ks) * (1 - metallic) * warpNdotL;
                }

                half3 DirectSpecularBRDF(half3 specularColor, half roughness, half NdotV, half NdotL, half NdotH, half VdotH)
                {
                    half3 F = SchlickFresnel(VdotH, half3(0.04, 0.04, 0.04));
                    half D = TrowbridgeReitzGGX(NdotH, roughness);
                    half V = VisiblityTerm(NdotV, NdotL, roughness);//VisiblityTerm(NdotV, NdotL, roughness);

                    return specularColor * F * D * V;
                }

                half3 IndiretF(half NdotV, half3 F0, half roughness)
                {    
                    half Fre = exp2((-5.55473*NdotV-6.98316)*NdotV);
                    return F0 + Fre * saturate(1-roughness-F0);
                }

                half3 IndirectDiffuse(half roughness, half metallic, half3 normalWS, half NdotV)
                {
                    half3 colorSH = SampleSH(normalWS); // * A0
                    half3 IndirectKs = IndiretF(NdotV, half3(0.04f, 0.04f, 0.04f), roughness);
                    half3 IndirectKd = (1 - IndirectKs) * (1 - metallic);
                    half3 irradianceSH = colorSH * IndirectKd;
                    return irradianceSH;
                }
                
                half3 IndirectSpecularCube(half roughness, half3 normalWS, half3 viewDirectionWS)
                {
                    half3 reflectDirectionWS = reflect(-viewDirectionWS, normalWS);
                    roughness = roughness * (1.7 - 0.7 * roughness);
                    half midLevel = roughness * 7;
                    half4 specularColor = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectDirectionWS, midLevel);
                    #if !defined(UNITY_USE_NATIVE_HDR)
                        return DecodeHDREnvironment(specularColor, unity_SpecCube0_HDR);
                    #endif
                    return specularColor.rgb;
                }

                half3 IndirectSpecularFactor(half roughness, half smoothness, half3 specularBRDF, half3 F0, half3 NdotV)
                {
                    half SurReduction;
                    #ifdef UNITY_COLORSPACE_GAMMA
                        SurReduction = 1 - 0.28 * roughness * roughness;
                    #else
                        SurReduction = 1 / (roughness * roughness + 1 );
                    #endif 

                    half Reflectivity;
                    #if defined(SHADER_API_GLES)
                        Reflectivity = specularBRDF.x;
                    #else
                        Reflectivity = max(max(specularBRDF.x, specularBRDF.y), specularBRDF.z);
                    #endif 

                    half GrazingTerm = saturate(Reflectivity + smoothness);
                    half Fre = Pow5(1 - NdotV);
                    return lerp(F0, GrazingTerm, Fre) * SurReduction;
                }

                half3 IndirectSpecular(half3 albedo, half roughness, half metallic, half3 normalWS, half3 viewDirectionWS, half3 NdotV)
                {
                    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
                    //half3 indirectDiffuse = SampleSH(normalWS);
                    half3 indirectSpecular = IndirectSpecularCube(roughness, normalWS, viewDirectionWS);

                    float surfaceReduction = 1.0 / (roughness * roughness + 1.0);
                    half grazingTerm = saturate(reflectVector + 1.0 - sqrt(roughness));
                    half fresnelTerm = Pow4(1.0 - NdotV);
                    return indirectSpecular * surfaceReduction * lerp(lerp(half3(0.04f, 0.04f, 0.04f), albedo, metallic), grazingTerm, fresnelTerm);
                }
                
                half3 TsukimiStylizedSkin(SkinSurfaceData skinSurfaceData, Light light, half3 normalWS, half3 viewDirectionWS, half3 positionWS)
                {
                    // Initialization
                    half3 H = SafeNormalize(light.direction + viewDirectionWS);
                    half NdotV = saturate(dot(normalWS, viewDirectionWS));
                    half NdotL = saturate(dot(normalWS, light.direction));
                    half NdotH = saturate(dot(normalWS, H));
                    half VdotH = saturate(dot(viewDirectionWS, H));
                    half shadowFactor = light.distanceAttenuation * light.shadowAttenuation;//smoothstep(0.1, 0.9, light.distanceAttenuation * light.shadowAttenuation);
                    NdotL *= shadowFactor;
                    // Direct Diffuse
                    half3 diffuse = DirectDiffuse(skinSurfaceData.metallic, NdotL, VdotH);

                    #ifdef _ENABLE_PRE_INTEGRATED_BRDF 
                        half NdotL_Warp = clamp(NdotL, -0.95, 0.95) * 0.5 + 0.5;
                        half deltaWorldNormal = length(fwidth(normalWS));
                        half deltaWorldPos = length(fwidth(positionWS));
                        half curvature = clamp(deltaWorldNormal / deltaWorldPos, -0.95, 0.95);
                        //return saturate(0.01*(length(fwidth(normalWS))/length(fwidth(positionWS))));
                        half3 preIntegratedBRDF = SAMPLE_TEXTURE2D(_PreIntegratedBRDFMap, sampler_PreIntegratedBRDFMap, float2(NdotL_Warp, 0.01 * curvature)).rgb;
                        diffuse = lerp(diffuse, preIntegratedBRDF, _PreIntegratedBRDFPercentage);  
                    #endif

                    // Indirect Diffuse
                    #ifdef _ENABLE_GI
                        diffuse += IndirectDiffuse(skinSurfaceData.diffuseRoughness, skinSurfaceData.metallic, normalWS, NdotV) * _GIIntensity;
                    #endif
                    
                    half3 color = diffuse * skinSurfaceData.albedo;

                    // Direct Specular
                    #ifdef _ENABLE_SPECULAR
                        half3 specluar = DirectSpecularBRDF(skinSurfaceData.specular, skinSurfaceData.specularRoughness, NdotV, NdotL, NdotH, VdotH) * max(0, _SpecularIntensity);
                        #ifdef _ENABLE_GI
                            half3 IndirectSpecularValue = IndirectSpecular(skinSurfaceData.albedo, skinSurfaceData.diffuseRoughness, skinSurfaceData.metallic, normalWS, viewDirectionWS, NdotV);
                            specluar += IndirectSpecularValue * _GIIntensity;
                        #endif
                        color += specluar;
                    #endif
                    
                    
                    #ifdef _ENABLE_CLEARCOAT
                        half3 clearcoat = DirectSpecularBRDF(skinSurfaceData.clearcoat, skinSurfaceData.clearcoatRoughness, NdotV, NdotL, NdotH, VdotH) * max(0, _ClearcoatIntensity);
                        color += clearcoat;
                    #endif

                    // Experimental SSS
                    #ifdef _ENABLE_SSS
                        half3 sssValue = SubsurfaceScattering(normalWS, -light.direction, viewDirectionWS, _FrontSSSDistortion, _FrontSSSPower, _FrontSSSIntensity, _SSSColor.rgb);
                        sssValue += SubsurfaceScattering(normalWS, light.direction, viewDirectionWS, _BackSSSDistortion, _BackSSSPower, _BackSSSIntensity, _SSSColor.rgb);
                        color += sssValue;
                    #endif

                    

                    return color * light.color;
                    
                }
                half4 UniversalFragmentTsukimiStylizedSkin(InputData inputData, SkinSurfaceData skinSurfaceData, half2 uv)
                {
                    //float shadow = MainLightRealtimeShadow();
                    Light mainLight = GetMainLight(TransformWorldToShadowCoord(inputData.positionWS));

                    half3 color = TsukimiStylizedSkin(skinSurfaceData, mainLight, inputData.normalWS, inputData.viewDirectionWS, inputData.positionWS);



                    return half4(color, 1);
                }

                // Used in Standard (Physically Based) shader
                half4 LitPassFragment(Varyings input) : SV_Target
                {
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                    SkinSurfaceData skinSurfaceData;
                    InitializeSkinSurfaceData(input.uv, skinSurfaceData);

                    InputData inputData;
                    InitializeInputData(input, skinSurfaceData.normalTS, inputData);

                    half4 color = UniversalFragmentTsukimiStylizedSkin(inputData, skinSurfaceData, input.uv);
                    
                    float3 normalVS = TransformWorldToViewDir(inputData.normalWS, true);
                    float3 positionVS = input.positionVS;

                    float3 samplePositionVS = float3(positionVS.xy + normalVS.xy * _OffsetMul, positionVS.z); // 保持z不变（CS.w = -VS.z）
                    float4 samplePositionCS = TransformWViewToHClip(samplePositionVS); // input.positionCS不是真正的CS 而是SV_Position屏幕坐标
                    float4 samplePositionVP = TransformHClipToViewPortPos(samplePositionCS);

                    float depth = input.positionNDC.z / input.positionNDC.w;
                    float linearEyeDepth = LinearEyeDepth(depth, _ZBufferParams); // 离相机越近越小
                    float offsetDepth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, samplePositionVP).r; // _CameraDepthTexture.r = input.positionNDC.z / input.positionNDC.w
                    float linearEyeOffsetDepth = LinearEyeDepth(offsetDepth, _ZBufferParams);
                    float depthDiff = linearEyeOffsetDepth - linearEyeDepth;
                    float rimIntensity = step(_Threshold, depthDiff);
                    //color.rgb += rimIntensity * _RimIntensity * saturate(dot(inputData.normalWS, _MainLightPosition.xyz));
                    color.rgb = MixFog(color.rgb, inputData.fogCoord);
                    color.a = OutputAlpha(color.a);
                    
                    //float3 positionVS = input.positionVS;
                    return color;
                }
            #endif
            
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "TsukimiStylizedSkinInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "TsukimiStylizedSkinInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "TsukimiStylizedSkinInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        /*Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMeta

            #pragma shader_feature _SPECULAR_SETUP
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICSPECGLOSSMAP
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma shader_feature _SPECGLOSSMAP

            #include "TsukimiStylizedSkinInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitMetaPass.hlsl"

            ENDHLSL
        }*/
        Pass
        {
            Name "Universal2D"
            Tags{ "LightMode" = "Universal2D" }

            Blend[_SrcBlend][_DstBlend]
            ZWrite[_ZWrite]
            Cull[_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON

            #include "TsukimiStylizedSkinInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
            ENDHLSL
        }


    }
    CustomEditor "LWGUI.LWGUI"
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
