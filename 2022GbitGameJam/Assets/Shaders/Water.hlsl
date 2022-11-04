#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal, float speed) {
    float steepness = wave.z;
    float wavelength = wave.w;
    float k = 2 * PI / wavelength;
    float c = sqrt(9.8 / k) * speed;                // _WaveSpeed
    float2 d = normalize(wave.xy);
    float f = k * (dot(d, p.xz) - c * _Time.y);
    float a = steepness / k;                // _Amplitude

    tangent += float3(
    -d.x * d.x * (steepness * sin(f)),
    d.x * (steepness * cos(f)),
    -d.x * d.y * (steepness * sin(f))
    );
    binormal += float3(
    -d.x * d.y * (steepness * sin(f)),
    d.y * (steepness * cos(f)),
    -d.y * d.y * (steepness * sin(f))
    );
    return float3(      // 输出顶点偏移量
    d.x * (a * cos(f)),
    a * sin(f),
    d.y * (a * cos(f))
    );
}

float3 GerstnerWaveOld(float4 waveParam, float time, float3 positionOS, inout float3 tangent, inout float3 bitangent)
{
    float3 position = 0;

    float2 direction = normalize(waveParam.xy);
    
    float waveLength = waveParam.w;
    
    float k = 2 * PI / max(1, waveLength);

    // 这里限制一下z让z永远不超过1
    // waveParam.z = abs(waveParam.z) / (abs(waveParam.z) + 1);
    float amplitude = waveParam.z;

    float speed = sqrt(9.8 / k);
    
    float f = k * (dot(direction, positionOS.xz) - speed * time);
    
    position.y = amplitude * sin(f);
    position.x = amplitude * cos(f) * direction.x;
    position.z = amplitude * cos(f) * direction.y;

    // 2022.4.27  更正偏导计算
    float yy = amplitude * k * cos(f);
    tangent +=   float3(-amplitude * k * sin(f) * direction.x * direction.x, yy * direction.x, -amplitude * k * sin(f) * direction.y * direction.x);
    
    bitangent += float3(-amplitude * k * sin(f) * direction.x * direction.y, yy * direction.y, -amplitude * k * sin(f) * direction.y * direction.y);
    
    return position;
}