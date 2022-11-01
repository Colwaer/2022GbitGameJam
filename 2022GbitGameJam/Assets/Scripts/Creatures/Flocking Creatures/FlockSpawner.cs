using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class FlockSpawner : MonoBehaviour
{
    public enum GizmoType { Never, SelectedOnly, Always }

    public BoidSettings Settings;

    public Boid prefab;
    public float spawnRadius = 10;
    public int spawnCount = 10;
    public GizmoType showSpawnRegion;

    void Start()
    {
        Spawn();
    }
    public void Spawn()
    {
        BoidManager.Instance.RegisterFlock(this, prefab, spawnRadius, spawnCount, Settings);
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

    void DrawGizmos()
    {
        Gizmos.color = Color.cyan;
        Gizmos.DrawSphere(transform.position, spawnRadius);
    }

}