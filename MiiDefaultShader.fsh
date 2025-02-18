//
//  sample.flg
//  Fragment shader
//  Copyright (c) 2014 Nintendo Co., Ltd. All rights reserved.
//
//

#ifdef GL_ES
precision mediump float;
#else
#   define lowp
#   define mediump
#   define highp
#endif


//
//  定数定義ファイル
//

/// シェーダーモード
#define FFL_SHADER_MODE_UR 0
#define FFL_SHADER_MODE_UB 1

/// 変調処理のマクロ
#define FFL_MODULATE_MODE_CONSTANT        0
#define FFL_MODULATE_MODE_TEXTURE_DIRECT  1
#define FFL_MODULATE_MODE_RGB_LAYERED     2
#define FFL_MODULATE_MODE_ALPHA           3
#define FFL_MODULATE_MODE_LUMINANCE_ALPHA 4
#define FFL_MODULATE_MODE_ALPHA_OPA       5

/// スペキュラのモード
#define FFL_SPECULAR_MODE_BLINN 0
#define FFL_SPECULAR_MODE_ANISO 1

/// ライトのON/OFF
#define FFL_LIGHT_MODE_DISABLE 0
#define FFL_LIGHT_MODE_ENABLE 1

/// フラグメントのディスカードモード
#define FFL_DISCARD_FRAGMENT_DISABLE 0
#define FFL_DISCARD_FRAGMENT_ENABLE  1

/// 座標変換モード
#define FFL_COORDINATE_MODE_NONE   0
#define FFL_COORDINATE_MODE_NORMAL 1

//
//  関数の定義ファイル
//

/**
 * @brief 異方性反射の反射率を計算します。
 * @param[in] light   ライトの向き
 * @param[in] tangent 接線
 * @param[in] eye     視線の向き
 * @param[in] power   鋭さ
 */
mediump float calculateAnisotropicSpecular(mediump vec3 light, mediump vec3 tangent, mediump vec3 eye, mediump float power )
{
	mediump float dotLT = dot(light, tangent);
	mediump float dotVT = dot(eye, tangent);
	mediump float dotLN = sqrt(1.0 - dotLT * dotLT);
	mediump float dotVR = dotLN*sqrt(1.0 - dotVT * dotVT) - dotLT * dotVT;

	return pow(max(0.0, dotVR), power);
}

/**
 * @brief 異方性反射の反射率を計算します。
 * @param[in] light   ライトの向き
 * @param[in] normal  法線
 * @param[in] eye     視線の向き
 * @param[in] power   鋭さ
 */
mediump float calculateBlinnSpecular(mediump vec3 light, mediump vec3 normal, mediump vec3 eye, mediump float power)
{
	return pow(max(dot(reflect(-light, normal), eye), 0.0), power);
}

/**
 * @brief 異方性反射、ブリン反射をブレンドします。
 * @param[in] blend ブレンド率
 * @param[in] blinn ブリンの値
 * @param[in] aniso 異方性の値
 */
mediump float calculateSpecularBlend(mediump float blend, mediump float blinn, mediump float aniso)
{
	return mix(aniso, blinn, blend);
}

/**
 * @brief アンビエントを計算します。
 * @param[in] light    ライト
 * @param[in] material マテリアル
 */
mediump vec3 calculateAmbientColor(mediump vec3 light, mediump vec3 material)
{
	return light * material;
}

/**
 * @brief 拡散を計算します。
 * @param[in] light    ライト
 * @param[in] material マテリアル
 * @param[in] ln       ライトと法線の内積
 */
mediump vec3 calculateDiffuseColor(mediump vec3 light, mediump vec3 material, mediump float ln)
{
	return light * material * ln;
}

/**
 * @brief 鏡面反射を計算します。
 * @param[in] light      ライト
 * @param[in] material   マテリアル
 * @param[in] reflection 反射率
 * @param[in] strength   幅
 */
mediump vec3 calculateSpecularColor(mediump vec3 light, mediump vec3 material, mediump float reflection, mediump float strength)
{
	return light * material * reflection * strength;
}

/**
 * @brief リムを計算します。
 * @param[in] color   リム色
 * @param[in] normalZ 法線のZ方向
 * @param[in] width   リム幅
 * @param[in] power   リムの鋭さ
 */
mediump vec3 calculateRimColor(mediump vec3 color, mediump float normalZ, mediump float width, mediump float power)
{
	return color * pow(width * (1.0 - abs(normalZ)), power);
}

/**
 * @brief ライト方向と法線の内積を求める
 * @note 特殊な実装になっています。
 */
mediump float calculateDot(mediump vec3 light, mediump vec3 normal)
{
	return max(dot(light, normal), 0.1);
}

/**
 * 色相を計算します
 */
mediump vec3 hue(mediump float f)
{
    mediump vec3 rgb = fract(f + vec3(0.0, 0.66666666, 0.33333333));
    rgb = abs(rgb * 2.0 - 1.0);
    return clamp(rgb * 3.0 - 1.0, 0.0, 1.0);
}

/**
 * RGBからHSVに変換します
 */
mediump vec3 RGB2HSV(mediump vec3 rgb)
{
    mediump float fMin = min(min(rgb.r, rgb.g), rgb.b);
    mediump float fMax = max(max(rgb.r, rgb.g), rgb.b);
    mediump float fDelta = fMax - fMin;
    
    if (fDelta == 0.0) { return vec3(0.0, 0.0, fMax); }
    
    mediump float fHue = 0.0;
    if (rgb.r == fMax)
    {
        fHue = (rgb.g - rgb.b) / fDelta;
    }
    else if (rgb.g == fMax)
    {
        fHue = 2.0 + (rgb.b - rgb.r) / fDelta;
    }
    else
    {
        fHue = 4.0 + (rgb.r - rgb.g) / fDelta;
    }
    fHue *= 0.16666666;
    if (fHue < 0.0) { fHue += 1.0; }
    
    return vec3(fHue, fDelta / fMax, fMax);
}

/**
 * HSVからRGBに変換します
 */
mediump vec3 HSV2RGB(mediump vec3 hsv)
{
    return ((hue(hsv.x) - 1.0) * hsv.y + 1.0) * hsv.z;
}

const lowp float levels = 2.0;
const lowp float scaleFactor = 1.0 / levels;
/**
 * トーンのステップを取得する
 */
lowp float toonStep(mediump float f)
{
    return floor((f - 0.0001) * levels);
}
/**
 * トゥーンの色を表現する関数
 */
mediump vec3 toonShade(mediump vec3 color)
{
    color.r = max(0.0, min(1.0, color.r));
    color.g = max(0.0, min(1.0, color.g));
    color.b = max(0.0, min(1.0, color.b));
    
    mediump float r = (toonStep(color.r) + 1.0) * scaleFactor + scaleFactor;
    mediump float g = (toonStep(color.g) + 1.0) * scaleFactor + scaleFactor;
    mediump float b = (toonStep(color.b) + 1.0) * scaleFactor + scaleFactor;
    
    return vec3(r, g, b);
}

/**
 * トゥーンの色を表現する関数
 */
mediump vec3 toonShadeEx(mediump vec3 color, mediump float fDot)
{
    lowp float fToon = toonStep(fDot);
    mediump vec3 vRet;
    
    if (fToon <= 0.0)
    {
//        mediump vec3 hsv = RGB2HSV(color);
//        hsv.y *= 1.1;   // 彩度を上げて
//        hsv.z *= 0.9;  // 明度を下げる
//        vRet = HSV2RGB(hsv);
        vRet = color * 0.8;
    }
    else if (fToon <= 1.0)
    {
//        mediump vec3 hsv = RGB2HSV(color);
//        hsv.y *= 1.1;   // 彩度を上げて
//        hsv.z *= 0.9;   // 明度を下げる
//        vRet = HSV2RGB(hsv);
        vRet = color;
    }
    else
    {
        vRet = color;
    }
    
    return vRet;
    //return color * (1.0 - (levels - toonStep(fDot)) * 0.1);
}

// フラグメントシェーダーに入力される varying 変数
varying mediump vec4 vPosition;       //!< 出力: 位置情報
varying mediump vec3 vNormal;         //!< 出力: 法線ベクトル
varying mediump vec2 vTexCoord;       //!< 出力: テクスチャー座標
varying mediump vec3 vTangent;        //!< 出力: 異方位
varying mediump vec4 vColor;          //!< 出力: 頂点の色

/// 変調設定
uniform int   uMaterialSpecularMode;     ///< スペキュラの反射モード(CharModelに依存する設定のためub_modulateにしている)
uniform int   uMode;   ///< 描画モード
uniform mediump vec3  uConst1; ///< constカラー1
uniform mediump vec3  uConst2; ///< constカラー2
uniform mediump vec3  uConst3; ///< constカラー3

/// ライト設定
uniform bool uLightEnable;
uniform mediump vec3 uLightDir;
uniform mediump vec3 uLightAmbient;  ///< カメラ空間のライト方向
uniform mediump vec3 uLightDiffuse;  ///< 拡散光用ライト
uniform mediump vec3 uLightSpecular; ///< 鏡面反射用ライト強度

/// マテリアル設定
uniform mediump vec3 uMaterialAmbient;         ///< 環境光用マテリアル設定
uniform mediump vec3 uMaterialDiffuse;         ///< 拡散光用マテリアル設定
uniform mediump vec3 uMaterialSpecular;        ///< 鏡面反射用マテリアル設定
uniform mediump float uMaterialSpecularPower; ///< スペキュラの鋭さ(0.0を指定すると頂点カラーの設定が利用される)

/// リム設定
uniform mediump vec3  uRimColor;
uniform mediump float uRimPower;

// サンプラー
uniform sampler2D sTexture;

// -------------------------------------------------------
// メイン文
void main()
{
    mediump vec4 color;

    mediump float specularPower    = uMaterialSpecularPower;
    mediump float rimWidth         = vColor.a;

//#ifdef FFL_MODULATE_MODE_CONSTANT
    if(uMode == FFL_MODULATE_MODE_CONSTANT)
    {
        color = vec4(uConst1, 1.0);
    }
//#elif defined(FFL_MODULATE_MODE_TEXTURE_DIRECT)
    else if(uMode == FFL_MODULATE_MODE_TEXTURE_DIRECT)
    {
        color = texture2D(sTexture, vTexCoord);
    }
//#elif defined(FFL_MODULATE_MODE_RGB_LAYERED)
    else if(uMode == FFL_MODULATE_MODE_RGB_LAYERED)
    {
        color = texture2D(sTexture, vTexCoord);
        color = vec4(color.r * uConst1.rgb + color.g * uConst2.rgb + color.b * uConst3.rgb, color.a);
    }
//#elif defined(FFL_MODULATE_MODE_ALPHA)
    else if(uMode == FFL_MODULATE_MODE_ALPHA)
    {
        color = texture2D(sTexture, vTexCoord);
        color = vec4(uConst1.rgb, color.a);
    }
//#elif defined(FFL_MODULATE_MODE_LUMINANCE_ALPHA)
    else if(uMode == FFL_MODULATE_MODE_LUMINANCE_ALPHA)
    {
        color = texture2D(sTexture, vTexCoord);
        color = vec4(color.a * uConst1.rgb, color.r);
    }
//#elif defined(FFL_MODULATE_MODE_ALPHA_OPA)
    else if(uMode == FFL_MODULATE_MODE_ALPHA_OPA)
    {
        color = texture2D(sTexture, vTexCoord);
        color = vec4(color.a * uConst1.rgb, 1.0);
    }
//#endif
    
//#ifdef FFL_LIGHT_MODE_ENABLE
    if(uLightEnable)
    {
        /// 環境光の計算
        mediump vec3 ambient = calculateAmbientColor(uLightAmbient, uMaterialAmbient);

        /// 法線ベクトルの正規化
        mediump vec3 norm = normalize(vNormal);

        /// 視線ベクトル
        mediump vec3 eye = normalize(vPosition.xyz);
        
        // ライトの向き
        mediump float fDot = calculateDot(uLightDir, norm);

        /// Diffuse計算
        mediump vec3 diffuse = calculateDiffuseColor(uLightDiffuse, uMaterialDiffuse, fDot);
        
        /// Specular計算
        mediump float specularBlinn = calculateBlinnSpecular(uLightDir, norm, eye, uMaterialSpecularPower);
        
        /// Specularの値を確保する変数を宣言
        mediump float reflection;
        mediump float strength = vColor.g;
        if(uMaterialSpecularMode == 0)
        {
            /// Blinnモデルの場合
            strength = 1.0;
            reflection = specularBlinn;
        }
        else
        {
            /// Aisoモデルの場合
            mediump float specularAniso = calculateAnisotropicSpecular(uLightDir, vTangent, eye, uMaterialSpecularPower);
            reflection = calculateSpecularBlend(vColor.r, specularBlinn, specularAniso);
        }
        /// Specularの色を取得
        mediump vec3 specular = calculateSpecularColor(uLightSpecular, uMaterialSpecular, reflection, strength);
        
        // カラーの計算
        color.rgb = (ambient + diffuse) * color.rgb + specular;
    }
//#endif

    gl_FragColor = color;
}
