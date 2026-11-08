set(OPENGL_SHADER_FILES
    2DLayerPreVS.glsl
    2DLayerPreFS.glsl
    2DSpritePreVS.glsl
    2DSpritePreFS.glsl
    2DSpriteVS.glsl
    2DSpriteFS.glsl
    2DCompositorVS.glsl
    2DCompositorFS.glsl

    FinalPassVS.glsl
    FinalPassFS.glsl
    CaptureVS.glsl
    CaptureFS.glsl
    CaptureDownscaleVS.glsl
    CaptureDownscaleFS.glsl

    3DClearVS.glsl
    3DClearFS.glsl
    3DClearBitmapVS.glsl
    3DClearBitmapFS.glsl
    3DRenderVS.glsl
    3DRenderFS.glsl
    3DFinalPassVS.glsl
    3DFinalPassEdgeFS.glsl
    3DFinalPassFogFS.glsl

    HybridCompositorVS.glsl
    HybridCompositorFS.glsl
)

# 游典 (Android, OpenGL ES 3.2): the same shaders as GLSL ES 3.20, from es/ (tools/convert_gles.py),
# and 3DRender's W-buffer variant as its own pair (ES can't take the #define after the fact).
# MELONDS_GLES: set by the frontend (melonDS DS for Android, -DMELONDS_GLES=ON).
if (MELONDS_GLES OR HAVE_OPENGLES)
    list(TRANSFORM OPENGL_SHADER_FILES PREPEND "es/")
    list(APPEND OPENGL_SHADER_FILES es/3DRenderVS_W.glsl es/3DRenderFS_W.glsl)
endif()

foreach(SH_INPUT ${OPENGL_SHADER_FILES})
    get_filename_component(SH_NAME ${SH_INPUT} NAME_WE)
    set(SH_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${SH_NAME}.h")
    add_custom_command(
        OUTPUT ${SH_OUTPUT}
        DEPENDS ${SH_INPUT}
        COMMAND
            ${CMAKE_COMMAND}
            -D INPUT_FILE=${SH_INPUT}
            -D OUTPUT_FILE=${SH_OUTPUT}
            -D VAR_NAME=${SH_NAME}
            -P "${CMAKE_CURRENT_LIST_DIR}/../../cmake/MakeEmbed.cmake"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )
    list(APPEND OPENGL_SHADER_OUT ${SH_OUTPUT})
endforeach()

add_custom_target(OpenGL_shaders ALL DEPENDS ${OPENGL_SHADER_OUT})
add_dependencies(core OpenGL_shaders)
