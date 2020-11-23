using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EarthMove : MonoBehaviour
{
    // Start is called before the first frame update
    public Transform earth;
    public Transform lightSun;
    public Camera mainCamera;
    private Vector3 axis_v = new Vector3(0,1,0) ;
    public Vector3 axis_h = new Vector3(1,0,0) ;
    

    private Vector3 cameraLocation;
    void Start()
    {
        cameraLocation = mainCamera.transform.position;
    }

    void transformSelf()
    {
        float hors = Input.GetAxis("Horizontal");
        float vecs = Input.GetAxis("Vertical");
        if (hors != 0)
        {
            Quaternion rotU = Quaternion.AngleAxis(-hors, Vector3.up);
            //earth.transform.Rotate(axis_v,hors);
            earth.transform.rotation = earth.transform.rotation * rotU;
            //earth.transform.localRotation = rotU*earth.transform.localRotation ;
        }

        if (vecs != 0)
        {
            Quaternion rotU = Quaternion.AngleAxis(vecs, Vector3.left);
            earth.transform.rotation = earth.transform.rotation * rotU;
        }
    }
    
    void transformWorld()
    {
        if (Input.GetAxis("Fire2") != 0)
        {
            float hors = Input.GetAxis("Mouse X");
            float vecs = Input.GetAxis("Mouse Y");
            if (hors != 0)
            {
                Quaternion rotU = Quaternion.AngleAxis(-hors, Vector3.up);
                //earth.transform.Rotate(axis_v,hors);
                //earth.transform.rotation = earth.transform.rotation * rotU;
                earth.transform.rotation = rotU*earth.transform.rotation ;
                lightSun.transform.rotation = rotU*lightSun.transform.rotation ;
            }

            if (vecs != 0)
            {
                Quaternion rotU = Quaternion.AngleAxis(-vecs, Vector3.left);
                earth.transform.rotation = rotU*earth.transform.rotation ;
                lightSun.transform.rotation = rotU*lightSun.transform.rotation ;
            }
        }
    }

    void transformLight()
    {
        if (Input.GetAxis("Fire1") != 0)
        {
            float hors = Input.GetAxis("Mouse X");
            float vecs = Input.GetAxis("Mouse Y");
            if (hors != 0)
            {
                Quaternion rotU = Quaternion.AngleAxis(-hors, Vector3.up);
                //earth.transform.Rotate(axis_v,hors);
                //earth.transform.rotation = earth.transform.rotation * rotU;
                lightSun.transform.rotation = rotU*lightSun.transform.rotation ;
            }

            if (vecs != 0)
            {
                Quaternion rotU = Quaternion.AngleAxis(-vecs, Vector3.left);
                lightSun.transform.rotation = rotU*lightSun.transform.rotation ;
            }
        }
    }
    void transformCamera()
    {
        float d = Input.GetAxis("Mouse ScrollWheel");
        if (d != 0)
        {
            Vector3 dir;
            if (d > 0)
            {
                dir = Vector3.Lerp(mainCamera.transform.position, earth.position, d);
            }
            else
            {
                dir = Vector3.LerpUnclamped( earth.position, mainCamera.transform.position,1-d);
            }
            if (Vector3.Distance(dir, earth.position) > 0.65 * (Mathf.Max(earth.localScale.x, Mathf.Max(earth.localScale.z, earth.localScale.y))))
            {
                cameraLocation = dir;
            }
        }
        mainCamera.transform.LookAt(earth);
    }

    void moveCamera()
    {
       
        mainCamera.transform.localPosition = Vector3.Lerp(mainCamera.transform.position, cameraLocation, 10 * Time.deltaTime);
    }

    
    // Update is called once per frame
    void Update()
    {
        transformSelf();
        transformWorld();
        transformLight();
        transformCamera();
        moveCamera();
        if (Input.GetKeyDown(KeyCode.Space))
        {
            Application.Quit();
        }
    }
}
