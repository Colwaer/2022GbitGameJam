using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SceneCameraFollow : MonoBehaviour
{
    Transform playerTransform;

    private void Start()
    {
        playerTransform = GameManager.Instance.Player.transform;
    }

    private void Update()
    {
        var originPos = transform.position;
        originPos.x = playerTransform.position.x;

        transform.position = originPos;
    }
}
