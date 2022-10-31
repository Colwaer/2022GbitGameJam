using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : Singleton<GameManager>
{
    CharacterController characterController;
    public CharacterController Player => characterController;
    protected override void Awake()
    {
        base.Awake();
        DontDestroyOnLoad(gameObject);


        GetReference();

    }
    void GetReference()
    {
        characterController = GameObject.FindGameObjectWithTag("Player").GetComponent<CharacterController>();
    }
}
