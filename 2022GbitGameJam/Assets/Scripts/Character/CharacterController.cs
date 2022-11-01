using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterController : MonoBehaviour
{
    [SerializeField]
    private float additionalMoveSpeed = 3f;
    [SerializeField]
    private float additionalMovingRotateSpeed = 1.5f;
    [SerializeField]
    private float rotationSpeed = 5f;

    Animator animator;
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

        rb.velocity += transform.forward * additionalMoveSpeed * moveInput.x;
        rb.MoveRotation(rb.rotation * Quaternion.Euler(0, rotationValue * rotationSpeed, 0));
    }
    void CheckInput()
    {
        moveInput.x = Input.GetAxis("Vertical");
        moveInput.z = Input.GetAxis("Horizontal");
        if (moveInput.x < 0)
            rotationValue = 0;
        else if (moveInput.x < 0.3)
            rotationValue = Mathf.Atan2(moveInput.z, moveInput.x);
        else
            rotationValue = Mathf.Atan2(moveInput.z, moveInput.x) * additionalMovingRotateSpeed;
    }
    void SetAnimParameters()
    {
        animator.SetFloat("ForwardMoveValue", moveInput.x);
        animator.SetFloat("RotationValue", moveInput.z);
    }

}
