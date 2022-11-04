using System.Collections;
using System.Collections.Generic;
using UnityEngine;



public class PlayerController : MonoBehaviour
{

    [SerializeField]
    private float swimUpSpeed = 10f;
    [SerializeField]
    private float swimAngleResetSpeed = 3f;
    [SerializeField]
    private float swimUpMax = 0.8f;
    [SerializeField]
    private float moveSpeed = 3f;
    [SerializeField]
    private float additionalMovingRotateSpeed = 1.5f;
    [SerializeField]
    private float rotationSpeed = 5f;


    Animator animator;
    Vector3 targetEuler;
    Vector3 moveInput;
    Rigidbody rb;

    float rotationValue;


    private void Awake()
    {
        animator = GetComponent<Animator>();
        rb = GetComponent<Rigidbody>();
    }

    private void Update()
    {
        CheckInput();


        
    }

    private void FixedUpdate()
    {
        SetAnimParameters();

        rb.velocity = transform.forward * moveSpeed * moveInput.x;

    

        transform.rotation = Quaternion.Euler(targetEuler);
        


        
    }

    void CheckInput()
    {
        moveInput.x = Input.GetAxis("Vertical");
        moveInput.z = Input.GetAxis("Horizontal");

        targetEuler = rb.rotation.eulerAngles;

        targetEuler.x = Input.GetAxis("Swim") * swimUpSpeed;


        targetEuler.y += moveInput.z * rotationSpeed * Time.deltaTime;




        if (moveInput.x == 0 && Mathf.Abs(moveInput.z) > 0.3f)
        {
            moveInput.x = 0.2f;
        }
    }
    void SetAnimParameters()
    {

    }

}
