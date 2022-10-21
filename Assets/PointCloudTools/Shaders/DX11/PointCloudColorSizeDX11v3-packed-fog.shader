// use with packed color data in v3 tiles viewer

Shader "UnityCoder/PointCloud/DX11/ColorSizeV3-packed-fog"
{
	Properties
	{
		_Size("Size", Float) = 0.01
		_Offset("Offset", Vector) = (0,0,0,0)
	}

	SubShader
	{
		Pass
		{
			Tags { "Queue" = "Geometry" "RenderType" = "Opaque" }
			ZWrite On
			LOD 200
			Cull Off

			CGPROGRAM
			#pragma target 5.0
			#pragma vertex VS_Main
			#pragma fragment FS_Main
			#pragma geometry GS_Main
			#pragma multi_compile_fog
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"

			StructuredBuffer<half3> buf_Points;

			struct appdata
			{
				fixed3 color : COLOR;
			};

			struct GS_INPUT
			{
				uint id : VERTEXID;
				//float3 fogCoord : TEXCOORD0;
			};

			struct FS_INPUT
			{
				half4 pos : POSITION;
				fixed3 color : COLOR;
				float3 fogCoord : TEXCOORD0;
			};

			float _Size;
			float _GridSizeAndPackMagic;
			float4 _Offset;

			float2 SuperUnpacker(float f)
			{
				return float2(f - floor(f), floor(f) / _GridSizeAndPackMagic);
			}

			GS_INPUT VS_Main(uint id : SV_VertexID, uint inst : SV_InstanceID)
			{
				GS_INPUT o;
				o.id = id;
				//o.fogCoord = 0; // TODO not needed here?
				return o;
			}

			[maxvertexcount(4)]
			void GS_Main(point GS_INPUT p[1], inout TriangleStream<FS_INPUT> triStream)
			{
				uint id = p[0].id;
				float3 rawpos = buf_Points[id];
				float2 xr = SuperUnpacker(rawpos.x);
				float2 yg = SuperUnpacker(rawpos.y);
				float2 zb = SuperUnpacker(rawpos.z);

				float4 pos = UnityObjectToClipPos(float3(xr.y + _Offset.x, yg.y + _Offset.y, zb.y + _Offset.z));

				fixed3 col = fixed3(saturate(xr.x), saturate(yg.x), saturate(zb.x)) * 1.02; // restore colors a bit
				#if !UNITY_COLORSPACE_GAMMA
				col = col * col; // linear
				#endif

				// TODO fix aspect ratio
				half4 s = half4(_Size, -_Size,0,0);

				FS_INPUT newVert;
				newVert.pos = pos + s.xxww;
				newVert.color = col;
				newVert.fogCoord = 0;
				UNITY_TRANSFER_FOG(newVert,pos);

				triStream.Append(newVert);

				newVert.pos = pos + s.xyww;
				triStream.Append(newVert);

				newVert.pos = pos + s.yxww;
				triStream.Append(newVert);

				newVert.pos = pos + s.yyww;
				triStream.Append(newVert);
			}

			fixed3 FS_Main(FS_INPUT input) : SV_Target
			{
				fixed3 col = input.color;
				UNITY_APPLY_FOG(input.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}