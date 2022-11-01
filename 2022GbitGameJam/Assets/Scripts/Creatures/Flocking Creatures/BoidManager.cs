using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BoidManager : Singleton<BoidManager>
{
    List<Boid> usedBoid = new List<Boid>();
    List<Boid> unusedBoid = new List<Boid>();



    const int threadGroupSize = 1024;

    public BoidSettings settings;
    public ComputeShader compute;

    Dictionary<FlockSpawner, Boid[]> boidList = new Dictionary<FlockSpawner, Boid[]>();


    void Start()
    {

    }



    void Update()
    {
        foreach (var keyValuePair in boidList)
        {
            var boids = keyValuePair.Value;
            if (boids != null)
            {
                int numBoids = boids.Length;
                var boidData = new BoidData[numBoids];

                for (int i = 0; i < boids.Length; i++)
                {
                    boidData[i].position = boids[i].position;
                    boidData[i].direction = boids[i].forward;
                }

                var boidBuffer = new ComputeBuffer(numBoids, BoidData.Size);
                boidBuffer.SetData(boidData);

                compute.SetBuffer(0, "boids", boidBuffer);
                compute.SetInt("numBoids", boids.Length);
                compute.SetFloat("viewRadius", settings.perceptionRadius);
                compute.SetFloat("avoidRadius", settings.avoidanceRadius);

                int threadGroups = Mathf.CeilToInt(numBoids / (float)threadGroupSize);
                compute.Dispatch(0, threadGroups, 1, 1);
                boidBuffer.GetData(boidData);

                for (int i = 0; i < boids.Length; i++)
                {
                    boids[i].avgFlockHeading = boidData[i].flockHeading;
                    boids[i].centreOfFlockmates = boidData[i].flockCentre;
                    boids[i].avgAvoidanceHeading = boidData[i].avoidanceHeading;
                    boids[i].numPerceivedFlockmates = boidData[i].numFlockmates;

                    boids[i].UpdateBoid();
                }
                boidBuffer.Release();
            }
        }
        
    }

    public Boid[] RegisterFlock(FlockSpawner spawner, Boid prefab, float spawnRadius, int spawnCount, 
        BoidSettings settings)
    {
        Boid[] boids = new Boid[spawnCount];

        for (int i = 0; i < spawnCount; i++)
        {
            Vector3 pos = spawner.transform.position + Random.insideUnitSphere * spawnRadius;
            Boid boid = Get(prefab, pos, Random.insideUnitSphere);
            boid.Initialize(spawner, settings, null, i);
            boids[i] = boid;
            //boid.SetColour(colour);
        }
        boidList[spawner] = boids;
        return boids;
    }






    #region 对象池
    Boid Get(Boid prefab, Vector3 pos, Vector3 forward)
    {
        if (unusedBoid.Count == 0)
        {
            var obj = Instantiate(prefab, pos, Quaternion.identity);
            obj.transform.forward = forward;
            usedBoid.Add(obj);
            return obj;
        }
        else
        {
            var obj = unusedBoid[unusedBoid.Count - 1];
            obj.gameObject.SetActive(true);
            obj.transform.position = pos;
            obj.transform.forward = forward;
            usedBoid.Add(obj);
            unusedBoid.RemoveAt(unusedBoid.Count - 1);
            return obj;
        }
    }
    void ReturnToPool(Boid obj)
    {
        obj.gameObject.SetActive(false);
        unusedBoid.Add(obj);
        usedBoid.Remove(obj);
    }
    #endregion

    public struct BoidData
    {
        public Vector3 position;
        public Vector3 direction;

        public Vector3 flockHeading;
        public Vector3 flockCentre;
        public Vector3 avoidanceHeading;
        public int numFlockmates;
        public static int Size
        {
            get
            {
                return sizeof(float) * 3 * 5 + sizeof(int);
            }
        }
    }


}