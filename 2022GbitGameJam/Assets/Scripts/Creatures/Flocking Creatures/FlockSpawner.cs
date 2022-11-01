using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class FlockSpawner : MonoBehaviour
{
    static int spawnerCount = 0;

    public enum GizmoType { Never, SelectedOnly, Always }

    public BoidSettings Settings;

    public Boid prefab;
    public float spawnRadius = 10;
    public int spawnCount = 10;
    public GizmoType showSpawnRegion;

    // state
    private int spawnerIndex;
    private int aliveCount;

    Boid[] boids;

    void Start()
    {
        spawnerIndex = spawnerCount++;
        Spawn();
    }
    public void Spawn()
    {
        boids = BoidManager.Instance.RegisterFlock(this, prefab, spawnRadius, spawnCount, Settings);
        aliveCount = boids.Length;
    }
    private void OnDrawGizmos()
    {
        if (showSpawnRegion == GizmoType.Always)
        {
            DrawGizmos();
        }
    }

    void OnDrawGizmosSelected()
    {
        if (showSpawnRegion == GizmoType.SelectedOnly)
        {
            DrawGizmos();
        }
    }
    public void OnBoidDie()
    {
        aliveCount--;
    }
    void DrawGizmos()
    {
        Gizmos.color = Color.cyan;
        Gizmos.DrawSphere(transform.position, spawnRadius);
    }
    private void OnTriggerExit(Collider collision)
    {
        if (collision.CompareTag("FlockBoid"))
        {
            var boid = collision.GetComponent<Boid>();
            if (boid != null && boid.spawner == this)
            {
                boid.Die();
            }
        }
    }
}