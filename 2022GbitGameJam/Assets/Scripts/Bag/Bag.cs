using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public enum BagItemType
{
    Gear,
    Fuel,
    Null
}
public class Bag : MonoBehaviour
{
    Dictionary<BagItemType, BagItem> bagItems = new Dictionary<BagItemType, BagItem>();


    public void AddToBag(BagItem item)
    {
        bagItems.Add(item.type, item);
    }
}

public class BagItem
{
    public string name;
    public string description;
    public string icon;
    public BagItemType type;
    private int sortPriority;
    public int count;
    public BagItem(string name, string description, string icon, BagItemType type, int sortPriority, int count)
    {
        this.name = name;
        this.description = description;
        this.icon = icon;
        this.type = type;
        this.sortPriority = sortPriority;
        this.count = count;
    }
}
