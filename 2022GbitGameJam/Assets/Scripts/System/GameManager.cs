using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : Singleton<GameManager>
{
    PlayerController characterController;
    public PlayerController Player => characterController;
    protected override void Awake()
    {
        base.Awake();
        DontDestroyOnLoad(gameObject);


        GetReference();

    }
    void GetReference()
    {
        characterController = GameObject.FindGameObjectWithTag("Player").GetComponent<PlayerController>();
    }
}
