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
        [Header(Water Properties)]
        _Color ("Water Color", Color) = (1, 1, 1, 1)
        _WaterRampTexture ("Water Ramp Texture", 2D) = "white" { }
        _WaveA ("Wave A (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
        _WaveB ("Wave B (dir, steepness, wavelength)", Vector) = (1, 0, 0.5, 10)
        _WaveSpeed ("Wave Speed", Range(0, 1)) = 0.01
        _WaveScale ("Wave Scale", Range(0, 10)) = 10

        _WaveLength ("WaveLength", float) = 4//水波长度，世界空间中波之间的波峰到波峰的距离
        _WaveAmplitude ("WaveAmplitude", float) = 0.4//振幅，从水平面到波峰的高度
        _WindDirection ("WindDirection", Range(0, 360)) = 70//风方向
        _WindSpeed ("WindSpeed", float) = 0.4//风速系数

        _DepthMultiplier ("Depth Multiplier", float) = 1
 

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

            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile_fog

            // Recieve Shadow
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
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
                
                float4 _WaveA;
                float4 _WaveB;
                float _WaveSpeed;
                float _WaveScale;
                float _WaveLength;
                float _WaveAmplitude;
                float _WindDirection;
                float _WindSpeed;
                float _DepthMultiplier;
            CBUFFER_END

            struct Wave
            {
                float3 vertex;
                float3 normal;
            };

            Wave GerstnerWave(half2 pos, float waveCount, half waveLen, half amplitude, half direction, half windSpeed)
            {
                //方向（D）：垂直于波峰传播的波阵面的水平矢量。
                //波长（L）：世界空间中波之间的波峰到波峰的距离。
                //振幅（A）：从水平面到波峰的高度。
                //速度（S）：波峰每秒向前移动的距离。
                //陡度 (Q) : 控制水波的陡度。
                Wave waveOut;
                float time = _Time.y;
                direction = radians(direction);
                half2 D = normalize(half2(sin(direction), cos(direction)));
                half w = 6.28318 / waveLen;
                half L = waveLen;
                half A = amplitude;
                half S = windSpeed * sqrt(9.8 * w);
                half Q = 1 / (A * w * waveCount);

                half commonCalc = w * dot(D, pos) + time * S;
                
                half cosC = cos(commonCalc);
                half sinC = sin(commonCalc);
                waveOut.vertex.xz = Q * A * D.xy * cosC;
                waveOut.vertex.y = (A * sinC) / waveCount;
                half WA = w * A;
                waveOut.normal = half3( - (D.xy * WA * cosC), 1 - (Q * WA * sinC));
                waveOut.normal = waveOut.normal / waveCount;
                return waveOut;
            }

            Wave GenWave(float3 vertex)
            {
                half2 pos = vertex.xz;
                Wave waveOut;
                uint count = 4;
                for (uint i = 0; i < count; i++)
                {
                    Wave wave = GerstnerWave(pos, count, _WaveLength, _WaveAmplitude, _WindDirection, _WindSpeed);
                    waveOut.vertex += wave.vertex;
                    waveOut.normal += wave.normal;
                }
                return waveOut;

            } 
            
            float3 GerstnerWave(
                float4 wave, float3 position, inout float3 tangent, inout float3 binormal
                , float waveSpeed, float scale)
            {

                float steepness = wave.z / scale;
                float wavelength = wave.w / scale;
                
                float k = 2 * 3.14 / wavelength;
                float c = sqrt(9.8 / k);
                float2 d = normalize(wave.xy);
                float f = k * (dot(d, position.xz) - (waveSpeed / scale) * _Time.y);
                float a = steepness / k;
                
                tangent += float3(1 - d.x * d.x * (steepness * sin(f)),
                d.x * (steepness * cos(f)),
                - d.x * d.y * (steepness * sin(f)));

                binormal += float3(
                    - d.x * d.y * (steepness * sin(f)),
                    d.y * (steepness * cos(f)),
                    1 - d.y * d.y * (steepness * sin(f))
                );

                
                return float3(d.x * (a * cos(f)), a * sin(f), d.y * (a * cos(f))
                );
            }

            float UnderwaterDepthDistance(float2 screenPos, float3 positionVS)
            {
                float depthTex = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos);
                float depthCamera2End = LinearEyeDepth(depthTex, _ZBufferParams);
                return depthCamera2End + positionVS.z;
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
                    float3 tangent = float3(1, 0, 0);
                    float3 binormal = float3(0, 0, 1);
                    float3 p = gridPoint;
                    p += GerstnerWave(_WaveA, gridPoint, tangent, binormal, _WaveSpeed, _WaveScale);
                    //p += GerstnerWave(_WaveB, gridPoint, tangent, binormal, _WaveSpeed, _WaveScale);
                    input.positionOS = p;
                    input.normal = normalize(cross(binormal, tangent));
                    /*Wave wave = GenWave(input.positionOS);
                    input.positionOS += wave.vertex;
                    input.normal += wave.normal;*/
                //}

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
                output.positionCS = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.positionVS = vertexInput.positionVS;
                output.screenPosition = ComputeScreenPos(vertexInput.positionCS);
                output.shadowCoord = GetShadowCoord(vertexInput);

                output.uv = TRANSFORM_TEX(input.uv, _MainTexture);
                output.normal = TransformObjectToWorldNormal(input.normal);
                output.fogCoord = ComputeFogFactor(output.positionCS.z);
                
                return output;
            }

            

            half4 frag(Varyings input) : SV_Target
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
                
                // Texture
                float4 color = SAMPLE_TEXTURE2D(_MainTexture, sampler_MainTexture, input.uv) * _Color;
                float4 screenColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + noise);
                
                float2 screenPos = input.screenPosition.xy / input.screenPosition.w;
                float depth = SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenPos).r;
                float depthValue = clamp(Linear01Depth(depth, _ZBufferParams), 0.01, 0.99);
                depthValue -= 0.01;
                depthValue /= 0.98;
                

                float4 waterRampColor = SAMPLE_TEXTURE2D(_WaterRampTexture, sampler_WaterRampTexture, float2(pow(depthValue, 0.5), 0));
                

                float depthDistance = clamp(UnderwaterDepthDistance(screenPos, input.positionVS) * _DepthMultiplier, 0.01, 0.99);
                half3 opaueTex = SAMPLE_TEXTURE2D_LOD(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV + noise, depthDistance * 0.25).rgb;
                float3 albedo = opaueTex * Absorption(depthValue) + Scattering(depthValue);
                
                //diffuse = MixFog(diffuse, input.fogCoord);


                screenColor.a = 1;
                //return float4(depthValue, depthValue, depthValue, 1);
                //if (N.y > 0.1f) return color;
                //#ifdef _NORMALMAP
                /*
                float2 flowUV = input.uv;
                
                half4 flowMap = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flowUV) * 2 - 1;


                float2 flowUV1 = input.uv * _BumpMap1_ST.xy + _BumpMap1_ST.zw;
                float2 flowUV2 = flowUV1;
                float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap1, sampler_BumpMap1, flowUV1), _BumpScale1);
                 + UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap1, sampler_BumpMap1, flowUV2), _BumpScale2);

                flowMap.xy *= _FlowStrength;
                float flowTime = _Time.y * _FlowSpeed + flowMap.a;
                float3 uv0 = FlowUV(bumpUV, flowMap.xy, flowTime);
                float3 uv1 = FlowUV(bumpUV, flowMap.xy, flowTime, 0.5);*/

                float2 bumpUV1 = input.uv * _BumpMap1_ST.xy + _BumpMap1_ST.zw;
                float2 bumpUV2 = input.uv * _BumpMap2_ST.xy + _BumpMap2_ST.zw;

                half3 unpackNormalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap1, sampler_BumpMap1, bumpUV1.xy), _BumpScale1);
                unpackNormalTS += UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap2, sampler_BumpMap2, bumpUV2.xy), _BumpScale2);
                //+ UnpackNormalScale(SAMPLE_TEXTURE2D(_BumpMap1, sampler_BumpMap1, uv1.xy), _BumpScale2) * uv1.z;

                float sgn = input.tangentWS.w;      // should be either +1 or -1
                float3 bitangent = sgn * cross(input.normal.xyz, input.tangentWS.xyz);

                N = TransformTangentToWorld(normalize(unpackNormalTS), half3x3(input.tangentWS.xyz, bitangent.xyz, input.normal.xyz));
                //#endif

                // Shading!

                // Diffuse
                half3 ambient = SampleSH(N);
                half3 diffuse = NdotL * _MainLightColor.rgb
                * mainLight.shadowAttenuation
                * mainLight.distanceAttenuation
                + ambient;
                // Specular
                half alpha = 1;
                BRDFData brdfData;
                InitializeBRDFData(half3(0, 0, 0), 0, half3(1, 1, 1), 0.9, alpha, brdfData);
                half3 specular = DirectBDRF(brdfData, N, L, V) * mainLight.shadowAttenuation * mainLight.color;


                //return float4(N, 1);
                //return float4(depthValue, depthValue, depthValue, 1);
                return float4(albedo + specular, 1) * (waterRampColor * depthValue) + screenColor * (1 - depthValue);


                return waterRampColor * depthValue + screenColor * (1 - depthValue);
            }
            ENDHLSL
        }
    }
}
