Shader "Stylized/Water"
{
    Properties
    {
        [Header(Texture)]
        _MainTexture ("Main Texture", 2D) = "white" { }
        _NoiseTexture ("Noise Texture", 2D) = "white" { }



        [Header(Main)]
        _NoiseIntensity("Noise Intensity", Range(0, 1)) = 0.1
        _WaterHeightThreshold ("Water Height Threshold", Range(0, 1)) = 0.1
        _Color ("Water Color", Color) = (1, 1, 1, 1)
        _WaterRampTexture ("Water Ramp Texture", 2D) = "white" { }

        [Header(Water UV)]
        _WaterWorldUVScale ("Water World UV Scale", Range(0, 10)) = 1
        _WaterUVAnimator ("Water UV Animator", Vector) = (0.5, 1, 1, 0.5)
        _WaterUV1Tiling ("Water UV 1 Tiling", Float) = 0.5
        _WaterUV2Tiling ("Water UV 2 Tiling", Float) = 0.5

        [Header(Water Normal Properties)]
        _BumpMap1 ("Normal Map 1", 2D) = "bump" { }
        _BumpMap2 ("Normal Map 2", 2D) = "bump" { }
        _BumpScale1 ("Bump Scale 1", Range(0.0, 3.0)) = 1.0
        _BumpScale2 ("Bump Scale 2", Range(0.0, 3.0)) = 1.0
        _BumpBlend ("Bump Blend", Range(0.0, 1.0)) = 0.5

        _FlowMap ("Flow Map", 2D) = "white" { }
        _FlowStrength ("Flow Strength", Range(0.0, 10.0)) = 1.0
        _FlowSpeed ("Flow Speed", Range(0.0, 10.0)) = 1.0

        [Header(Water Displacement Properties)]
        _WaveA ("Wave A(amp, len, speed, dir)", Vector) = (0.4, 4, 0.4, 90)
        _WaveB ("Wave B", Vector) = (4, 0.4, 70, 0.4)
        _WaveC ("Wave C", Vector) = (4, 0.4, 70, 0.4)
        _WaveLength ("WaveLength", float) = 4//水波长度，世界空间中波之间的波峰到波峰的距离
        _WaveAmplitude ("WaveAmplitude", float) = 0.4//振幅，从水平面到波峰的高度
        _WindDirection ("WindDirection", Range(0, 360)) = 70//风方向
        _WindSpeed ("WindSpeed", float) = 0.4//风速系数
        _WaveSteepness ("Wave Steepness", Range(0, 10)) = 10
        _DepthMultiplier ("Depth Multiplier", float) = 1
 
        [Header(Debug)]
        [Toggle(_SCREEN_COLOR)] _A ("SCREEN COLOR", Int) = 1
        [Toggle(_REFRACTION_COLOR)] _B ("REFRACTION COLOR", Int) = 1


    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "UniversalRenderPipeline" 
            "Queue" = "Transparent" 
            "IgnoreProjector" = "True" 
            "RenderType" = "Transparent" 
        }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
            #include ".\Water.hlsl"

            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            // Recieve Shadow
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _SCREEN_COLOR
            #pragma shader_feature _REFRACTION_COLOR

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 positionVS : TEXCOORD1;
                float4 screenPosition : TEXCOORD2;
                float2 uv : TEXCOORD3;
                float fogCoord : TEXCOORD4;
                float3 normal : NORMAL;
                float4 shadowCoord : TEXCOORD5;
                float4 tangentWS : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
                
                float4 _Color;
                float _WaterHeightThreshold;
                float _NoiseIntensity;

                TEXTURE2D(_MainTexture);
                SAMPLER(sampler_MainTexture);
                half4 _MainTexture_ST;

                TEXTURE2D(_NoiseTexture);
                SAMPLER(sampler_NoiseTexture);
                half4 _NoiseTexture_ST;

                TEXTURE2D(_CameraOpaqueTexture);
                SAMPLER(sampler_CameraOpaqueTexture);
                half4 _CameraOpaqueTexture_ST;

                TEXTURE2D(_CameraDepthTexture);
                SAMPLER(sampler_CameraDepthTexture);
                half4 _CameraDepthTexture_ST;

                TEXTURE2D(_WaterRampTexture);
                SAMPLER(sampler_WaterRampTexture);
                half4 _WaterRampTexture_ST;
                
                TEXTURE2D(_BumpMap1);
                SAMPLER(sampler_BumpMap1);
                half4 _BumpMap1_ST;

                TEXTURE2D(_BumpMap2);
                SAMPLER(sampler_BumpMap2);
                half4 _BumpMap2_ST;

                TEXTURE2D(_FlowMap);
                SAMPLER(sampler_FlowMap);
                half4 _FlowMap_ST;

                float _WaterWorldUVScale;
                float4 _WaterUVAnimator;
                float _WaterUV1Tiling;
                float _WaterUV2Tiling;

                float _BumpScale1;
                float _BumpScale2;
                float _BumpBlend;

                float4 _WaveA;
                float4 _WaveB;
                float4 _WaveC;
                float _WaveSpeed;
                float _WaveSteepness;
                float _WaveLength;
                float _WaveAmplitude;
                float _WindDirection;
                float _WindSpeed;
                float _DepthMultiplier;
                
                float _FlowSpeed;
                float _FlowStrength;
            CBUFFER_END
            struct Wave
            {
                float3 wavePos;
                float3 waveNormal;
            };
            Wave GerstnerWave(float2 posXZ, float amp, float waveLen, float speed, int dir)

            {
                Wave o;
                float w = 2 * PI / (waveLen * _WaveLength);
                float A = amp;
                float WA = w * A;
                float Q = _WaveSteepness / (WA);
                float dirRad = radians((dir) % 360);
                float2 D = normalize(float2(sin(dirRad), cos(dirRad)));
                float common = dot(w * D, posXZ) + _Time.y * sqrt(9.8 * w) * speed;
                float sinC = sin(common);
                float cosC = cos(common);
                o.wavePos.xz = Q * A * D.xy * cosC;
                o.wavePos.y = A * sinC;
                o.waveNormal.xz = -D.xy * WA * cosC;
                o.waveNormal.y = -Q * WA * sinC;
                return o;
            }

            half3 Scattering(half depth)
            {
                return SAMPLE_TEXTURE2D(_WaterRampTexture, sampler_WaterRampTexture, half2(depth, 0.375h)).rgb;
            }

            half3 Absorption(half depth)
            {
                return SAMPLE_TEXTURE2D(_WaterRampTexture, sampler_WaterRampTexture, half2(depth, 0.0h)).rgb;
            }

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                float waterLevel = _WaterHeightThreshold * 2 - 1;

                //if (input.positionOS.y > waterLevel) {
                    //input.positionOS.y = waterLevel;
                    
                    float3 gridPoint = input.positionOS;
                    float3 binormal = 0;
                    float3 tangent = 0;
                    float3 p = gridPoint;

                    //Wave waveA = GerstnerWave(input.positionOS.xz, _WaveAmplitude, _WaveLength, _WindSpeed, _WindDirection);
                    Wave waveA = GerstnerWave(input.positionOS.xz, _WaveA.x, _WaveA.y, _WaveA.z, _WaveA.w);
                    Wave waveB = GerstnerWave(input.positionOS.xz, _WaveB.x, _WaveB.y, _WaveB.z, _WaveB.w);
                    Wave waveC = GerstnerWave(input.positionOS.xz, _WaveC.x, _WaveC.y, _WaveC.z, _WaveC.w);  

                    input.positionOS += waveA.wavePos;
                    input.normal += waveA.waveNormal;

                    input.positionOS += waveB.wavePos;
                    input.normal += waveB.waveNormal;

                    input.positionOS += waveC.wavePos;
                    input.normal += waveC.waveNormal;
                //}

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.positionVS = vertexInput.positionVS;
                output.screenPosition = ComputeScreenPos(vertexInput.positionCS);
                output.shadowCoord = GetShadowCoord(vertexInput);

                output.uv = TRANSFORM_TEX(input.uv, _MainTexture);
                
                output.fogCoord = ComputeFogFactor(output.positionCS.z);

                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normal, input.tangent);
                output.normal = normalInput.normalWS;
                real sign = input.tangent.w * GetOddNegativeScale();
                output.tangentWS = half4(normalInput.tangentWS.xyz, sign);

                output.normal = TransformObjectToWorldNormal(normalize(input.normal));
                //o.tangentWS = float4(TransformObjectToWorldDir(i.tangentOS.xyz), i.tangentOS.w);
                return output;
            }

            

            half4 frag (Varyings input) : SV_Target
            {
                // Setep
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);
                
                float3 L = mainLight.direction; //_MainLightPosition.xyz;
                float3 N = normalize(input.normal);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float3 H = normalize(L + V);

                float NdotL = saturate(dot(N, L));

                float2 screenUV = input.positionCS.xy / _ScreenParams.xy;
                float2 noise = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, screenUV + _Time.xx).rr * _NoiseIntensity;
                noise = noise * 2 - float2(_NoiseIntensity, _NoiseIntensity);
                
                // 1.Depth
                float4 color = SAMPLE_TEXTURE2D(_MainTexture, sampler_MainTexture, input.uv) * _Color;
                float3 screenColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + noise);

                float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + noise).r;
                float depthValue = clamp(Linear01Depth(depth, _ZBufferParams), 0.01, 0.88);
                depthValue -= 0.01;
                depthValue /= 0.98;
        
                float4 waterRampColor = SAMPLE_TEXTURE2D(_WaterRampTexture, sampler_WaterRampTexture, float2(pow(depthValue, 0.5), 0));
               

                half3 opaueTex = SAMPLE_TEXTURE2D_LOD(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + noise, depthValue * 0.25).rgb;
                float3 albedo = Absorption(depthValue);// + Scattering(depthValue);
                
                //diffuse = MixFog(diffuse, input.fogCoord);

                // 2.Normal

                float2 worldUV = input.positionWS.xz / _WaterWorldUVScale;

                float2 uv1 = _Time.x * _WaterUVAnimator.xy + worldUV * _WaterUV1Tiling;
                float2 uv2 = _Time.x * _WaterUVAnimator.zw + worldUV * _WaterUV2Tiling;

                half3 unpackNormalTS = lerp(
                    UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap1, sampler_BumpMap1, uv1), _BumpScale1),
                    UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap2, sampler_BumpMap2, uv2), _BumpScale2),
                    _BumpBlend
                );

                float sgn = input.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normal.xyz, input.tangentWS.xyz);
                float3 disturbedN = TransformTangentToWorld(normalize(unpackNormalTS), half3x3(input.tangentWS.xyz, bitangent.xyz, input.normal.xyz));
                //#endif

                float fresnelNdotV = dot(N, V);
                float fresnel = (0.0 + 1.0 * pow(1.0 - fresnelNdotV, 1.336));
                
                float3 deepColor = SAMPLE_TEXTURE2D(_WaterRampTexture, sampler_WaterRampTexture, float2(0.9, 0));
                float3 waterColor = lerp(deepColor, _Color, fresnel);

                half3 ambient = SampleSH(N);
                half3 diffuse = saturate(dot(normalize(N + float3(0, 1, 0)), L)) * _MainLightColor.rgb + ambient;
                //* mainLight.shadowAttenuation
                //* mainLight.distanceAttenuation
                // Specular
                half alpha = 1;
                BRDFData brdfData;
                InitializeBRDFData(half3(0, 0, 0), 0, half3(1, 1, 1), 0.9, alpha, brdfData);
                half3 specular = DirectBDRF(brdfData, disturbedN, L, V) * mainLight.shadowAttenuation * mainLight.color;


                // return float4(waterColor, 1);
                // return float4(depthValue, depthValue, depthValue, 1);
                // float4 shadingColor = float4(albedo * diffuse + specular, 1) * (waterRampColor * depthValue);
                
                float3 shadingColor = (albedo * diffuse * waterRampColor.rgb + specular) * depthValue;
                float3 refraction = screenColor * (1 - depthValue);
                float3 finalColor = float3(0, 0, 0);

                #ifdef _SCREEN_COLOR
                    finalColor += shadingColor;
                #endif
                #ifdef _REFRACTION_COLOR
                    finalColor += refraction;
                #endif
                return float4(finalColor, 1);
                

                //return waterRampColor * depthValue + screenColor * (1 - depthValue);
            }
            ENDHLSL
        }
    }
}
