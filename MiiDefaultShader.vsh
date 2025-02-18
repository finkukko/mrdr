/******************************************************//**
 * @file    sample.vsh
 * @brief   Vertex Shader
 * Copyright (c) 2014 Nintendo Co., Ltd. All rights reserved.
 **********************************************************/

#ifdef GL_ES
precision highp float;
#else
#   define lowp
#   define mediump
#   define highp
#endif

// 頂点シェーダーに入力される attribute 変数
attribute vec4 aPosition;   //!< 入力: 位置情報
attribute vec2 aTexCoord;   //!< 入力: テクスチャー座標
attribute vec3 aNormal;     //!< 入力: 法線ベクトル
attribute vec3 aTangent;    //!< 入力: 異方位
attribute vec4 aColor;      //!< 入力: 頂点の色

// フラグメントシェーダーへの入力
varying   vec4 vPosition;   //!< 出力: 位置情報
varying   vec3 vNormal;     //!< 出力: 法線ベクトル
varying   vec2 vTexCoord;   //!< 出力: テクスチャー座標
varying   vec3 vTangent;    //!< 出力: 異方位
varying   vec4 vColor;      //!< 出力: 頂点の色

// ユニフォーム
uniform   mat4 uProjection; //!< ユニフォーム: プロジェクション行列
uniform   mat4 uModelView;  //!< ユニフォーム: モデル行列

void main()
{
//#ifdef FFL_COORDINATE_MODE_NORMAL
    // 頂点座標を変換
    gl_Position = aPosition * uModelView * uProjection;
    vPosition = aPosition;

    // 法線も変換
    //vNormal = mat3(inverse(uModelView)) * aNormal;
    vNormal = normalize(aNormal * mat3(uModelView));
//#elif defined(FFL_COORDINATE_MODE_NONE)
//    // 頂点座標を変換
//    gl_Position = vec4(aPosition.x, aPosition.y * -1.0, aPosition.z, aPosition.w);
//    vPosition = aPosition;
//
//    vNormal = aNormal;
//#endif
    
    // その他の情報も書き出す
    vTexCoord = aTexCoord;
    vTangent  = aTangent;
    vColor    = aColor;
}
