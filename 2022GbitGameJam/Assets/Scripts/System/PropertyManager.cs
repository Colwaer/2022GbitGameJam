using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using UnityEngine.UI;


public class PropertyManager : Singleton<PropertyManager>
{

    private float health;
    private float oxygen;
    private float hotvalue;

    private float s_health;
    private float s_oxygen;
    private float s_hotvalue;
    
    public Slider healthSlider;
    public Slider oxygenSlider;
    public Slider hotvalueSlider;

    public float Health
    {
        get => health;
        set
        {
            health = value;



            if (healthSlider != null)
                healthSlider.value = health / 100f;
        }
    }
    public float Oxygen
    {
        get => oxygen;
        set
        {
            oxygen = value;


            if (oxygenSlider != null)
                oxygenSlider.value = oxygen / 100f;
        }
    }
    public float Hotvalue
    {
        get => hotvalue;
        set
        {
            hotvalue = value;


            if (hotvalueSlider != null)
                hotvalueSlider.value = hotvalue / 100f;
        }
    }


    protected override void Awake()
    {
        base.Awake();

        InitProperty();
    }

    void InitProperty()
    {
        InitPlayerProperty(100f, 100f, 0f, -0.3f, -0.5f, 0.3f);
    }

    void InitPlayerProperty(float health, float oxygen, float hotvalue, float s_health, float s_oxygen, float s_hotvalue)
    {
        this.Health = health;
        this.Oxygen = oxygen;
        this.Hotvalue = hotvalue;

        this.s_health = s_health;
        this.s_oxygen = s_oxygen;
        this.s_hotvalue = s_hotvalue;
    }
    void UpdatePlayerProperty()
    {
        Health = Mathf.Max(0f, Mathf.Min(health + s_health * Time.deltaTime, 100f));
        Oxygen = Mathf.Max(0f, Mathf.Min(oxygen + s_oxygen * Time.deltaTime, 100f));
        Hotvalue = Mathf.Max(0f, Mathf.Min(hotvalue + s_hotvalue * Time.deltaTime, 100f));
    }

    private void Update()
    {
        UpdatePlayerProperty();
    }



}