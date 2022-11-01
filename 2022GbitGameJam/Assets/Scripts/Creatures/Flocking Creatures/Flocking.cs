using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Flocking : MonoBehaviour
{
    public int numPoints = 50;
    public float turnFraction = 0f;
    public float pow = 0.5f;

    public GameObject point;

    List<GameObject> usedPoints = new List<GameObject>();
    List<GameObject> unusedPoints = new List<GameObject>();



    void Start()
    {
        
    }
    private void Update()
    {
        ReturnToPool();
        CreatePoints();
    }
    void CreatePoints()
    {
        for (int i = 0; i < numPoints; i++)
        {
            float t = i / (float)(numPoints - 1);
            float inclination = Mathf.Acos(1 - 2 * t);
            float azimuth = 2 * Mathf.PI * turnFraction * i;

            float x = Mathf.Sin(inclination) * Mathf.Cos(azimuth);
            float y = Mathf.Sin(inclination) * Mathf.Sin(azimuth);
            float z = Mathf.Cos(inclination);

            Get(new Vector3(x, y, z), Quaternion.identity);
        }
    }
    void Get(Vector3 pos, Quaternion rotation)
    {
        if (unusedPoints.Count == 0)
        {
            usedPoints.Add(Instantiate(point, pos, rotation));
        }    
        else
        {
            var obj = unusedPoints[unusedPoints.Count - 1];
            obj.SetActive(true);
            obj.transform.position = pos;
            obj.transform.rotation = rotation;
            usedPoints.Add(obj);
            unusedPoints.RemoveAt(unusedPoints.Count - 1);           
        }
    }
    void ReturnToPool()
    {
        foreach (var point in usedPoints)
        {
            unusedPoints.Add(point);
            point.SetActive(false);
        }
        usedPoints.Clear();
    }
}
