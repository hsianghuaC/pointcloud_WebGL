// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// PointCloud Shader for DX11 Viewer with PointSize and ColorTint

Shader "UnityCoder/PointCloud/DX11/ColorSizeV2-manipulate" {
    Properties {
        _Size ("Size", Float) = 0.01
        _tX ("TranslateX", float) = 0
        _tY ("TranslateY", float) = 0
        _tZ ("TranslateZ", float) = 0
        _sX ("ScaleX", float) = 1
        _sY ("ScaleY", float) = 1
        _sZ ("ScaleZ", float) = 1
        // TODO add pivot point
        _rX ("RotateX", float) = 0
        _rY ("RotateY", float) = 0
        _rZ ("RotateZ", float) = 0
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
   			float _tX,_tY,_tZ; 
			float _sX,_sY,_sZ;
			float _rX,_rY,_rZ;

            GS_INPUT VS_Main(uint id : SV_VertexID) {
                GS_INPUT o;
                o.id = id;
                return o;
            }

            [maxvertexcount(4)]
            void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream) {
                uint id = p[0].id;
                float4 pos = float4(buf_Points[id],1);

				float4x4 scaleMatrix 	= float4x4(_sX,	0,	0,	0,
											 		0,	_sY,0,	0,
								  					0,	0,	_sZ,0,
								  					0,	0,	0,	1);

				float angleX = radians(_rX);
				float c = cos(angleX);
				float s = sin(angleX);
				float4x4 rotateXMatrix	= float4x4(	1,	0,	0,	0,
											 		0,	c,	-s,	0,
								  					0,	s,	c,	0,
								  					0,	0,	0,	1);

				float angleY = radians(_rY);
				c = cos(angleY);
				s = sin(angleY);
				float4x4 rotateYMatrix	= float4x4(	c,	0,	s,	0,
											 		0,	1,	0,	0,
								  					-s,	0,	c,	0,
								  					0,	0,	0,	1);

				float angleZ = radians(_rZ);
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

                float3 cameraUp = UNITY_MATRIX_IT_MV[1].xyz;
                float3 cameraForward = _WorldSpaceCameraPos - mul(unity_ObjectToWorld,  localScaledTranslatedRotXYZ+float3(_tX,_tY,_tZ));
                float3 rightSize = normalize(cross(cameraUp, cameraForward)) * _Size;
                float3 cameraSize = _Size * cameraUp;

                fixed3 col = buf_Colors[id];
                #if !UNITY_COLORSPACE_GAMMA
                    col = col * col; // linear
                #endif

                float4 spos = UnityObjectToClipPos(localScaledTranslatedRotXYZ+float3(_tX,_tY,_tZ));
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