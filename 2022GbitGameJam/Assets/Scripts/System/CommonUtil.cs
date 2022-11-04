using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CommonUtil
{
    public static float ValueBetween(float value, float min, float max)
    {
        return Mathf.Max(min, Mathf.Min(max, value));
    }

}
