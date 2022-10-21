// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// PointCloud Shader for DX11 Viewer with PointSize and ColorTint

Shader "UnityCoder/PointCloud/DX11/ColorSizeV2-manipulate2" {
    Properties {
        _Size ("Size", Float) = 0.01
        _Position("Position", Vector) = (0,0,0,0)
        _Scale("Scale", Vector) = (1,1,1,1)
        _Rotation("Rotation", Vector) = (0,0,0,0)
    }

    SubShader {
        Pass {
            Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
            LOD 200

            CGPROGRAM

            #pragma target 5.0
            #pragma vertex VS_Main
            #pragma fragment FS_Main
            #pragma geometry GS_Main
            #include "UnityCG.cginc"

            StructuredBuffer<half3> buf_Points;
            StructuredBuffer<fixed3> buf_Colors;

            struct GS_INPUT {
                uint id : VERTEXID;
            };

            struct FS_INPUT {
                half4 pos : POSITION;
                fixed3 color : COLOR;
            };

            float _Size;
            float4 _Position;
            float4 _Scale;
            float4 _Rotation;

            GS_INPUT VS_Main(uint id : SV_VertexID) {
                GS_INPUT o;
                o.id = id;
                return o;
            }

            [maxvertexcount(4)]
            void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream) {
                uint id = p[0].id;
                float4 pos = float4(buf_Points[id],1);

				float4x4 scaleMatrix 	= float4x4(_Scale.x,	0,	0,	0,
											 		0,	_Scale.y,0,	0,
								  					0,	0,	_Scale.z,0,
								  					0,	0,	0,	1);

				float angleX = radians(-_Rotation.x);
				float c = cos(angleX);
				float s = sin(angleX);
				float4x4 rotateXMatrix	= float4x4(	1,	0,	0,	0,
											 		0,	c,	-s,	0,
								  					0,	s,	c,	0,
								  					0,	0,	0,	1);

				float angleY = radians(-_Rotation.y-180);
				c = cos(angleY);
				s = sin(angleY);
				float4x4 rotateYMatrix	= float4x4(	c,	0,	s,	0,
											 		0,	1,	0,	0,
								  					-s,	0,	c,	0,
								  					0,	0,	0,	1);

				float angleZ = radians(-_Rotation.z);
				c = cos(angleZ);
				s = sin(angleZ);
				float4x4 rotateZMatrix	= float4x4(	c,	-s,	0,	0,
											 		s,	c,	0,	0,
								  					0,	0,	1,	0,
								  					0,	0,	0,	1);


  				//float4 localTranslated = mul(translateMatrix,pos);
  				float4 localScaledTranslated = mul(pos,scaleMatrix);
  				float4 localScaledTranslatedRotX = mul(localScaledTranslated,rotateXMatrix);
  				float4 localScaledTranslatedRotXY = mul(localScaledTranslatedRotX,rotateYMatrix);
  				float4 localScaledTranslatedRotXYZ = mul(localScaledTranslatedRotXY,rotateZMatrix);

                localScaledTranslatedRotXYZ = mul(unity_ObjectToWorld, localScaledTranslatedRotXYZ);

                float3 cameraUp = UNITY_MATRIX_IT_MV[1].xyz;
                float3 offset = float3(_Position.x,_Position.y,_Position.z);
                float3 cameraForward = _WorldSpaceCameraPos - mul(unity_ObjectToWorld,  localScaledTranslatedRotXYZ+offset);
                float3 rightSize = normalize(cross(cameraUp, cameraForward)) * _Size;
                float3 cameraSize = _Size * cameraUp;

                fixed3 col = buf_Colors[id];
                #if !UNITY_COLORSPACE_GAMMA
                    col = col * col; // linear
                #endif

                float4 spos = UnityObjectToClipPos(localScaledTranslatedRotXYZ+offset);
                half4 quad = half4(_Size, -_Size,0,0);

				FS_INPUT newVert;
				newVert.pos = spos+ quad.xxww;
				newVert.color = col;
				triStream.Append(newVert);
				newVert.pos = spos + quad.xyww;
				triStream.Append(newVert);
				newVert.pos = spos + quad.yxww;
				triStream.Append(newVert);
				newVert.pos = spos + quad.yyww;
				triStream.Append(newVert);
            }

            fixed3 FS_Main(FS_INPUT input) : COLOR {
                return input.color;
            }
            ENDCG

        }
    }
}