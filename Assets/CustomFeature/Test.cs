using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

[ExecuteAlways]
public class Test : MonoBehaviour
{
    private Camera _camera;
    void ppp()
    {
        _camera = GetComponent<Camera>();
        //世界空间转化为摄像机空间的矩阵
        Matrix4x4 worldToCameraMatrix = _camera.worldToCameraMatrix;
        //投影矩阵
        Matrix4x4 projectionMatrix = _camera.projectionMatrix;
        Debug.Log(worldToCameraMatrix);
    }
    
    void Update()
    {
        ppp();
        Debug.Log("ssss");
    }
}
