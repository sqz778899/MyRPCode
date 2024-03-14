using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RayBox : MonoBehaviour
{
    void OnDrawGizmos()
    {
        Gizmos.color = Color.red;
        Gizmos.DrawWireCube(transform.position,transform.localScale);
        Shader.SetGlobalVector("_RayBoxMin",CalBoxMin(transform.position,transform.localScale));
        Shader.SetGlobalVector("_RayBoxMax",CalBoxMax(transform.position,transform.localScale));
    }
    
    Vector3 CalBoxMin(Vector3 pos, Vector3 size)
    {
        return pos - size * 0.5f;
    }
    
    Vector3 CalBoxMax(Vector3 pos, Vector3 size)
    {
        return pos + size * 0.5f;
    }
}
