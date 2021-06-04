using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ForceDepthNormal : MonoBehaviour
{
    void Start()
    {
        Camera cam = Camera.main;

        cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.DepthNormals;

        this.enabled = false;
    }
}
