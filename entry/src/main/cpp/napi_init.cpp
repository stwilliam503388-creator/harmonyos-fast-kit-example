#include <algorithm>
#include <dlfcn.h>
#include <string>
#include <vector>

#include "FASTKit/fast_ads_segment_map.h"
#include "FASTKit/fast_solver_rect_partition.h"
#include "napi/native_api.h"

namespace {

using SegmentCreateConfigFn = FAST_ErrorCode (*)(FAST_SegmentMapConfig**);
using SegmentDestroyConfigFn = void (*)(FAST_SegmentMapConfig*);
using SegmentSetQueryTypeFn = FAST_ErrorCode (*)(FAST_SegmentMapConfig*, FAST_SegmentMapQueryType);
using SegmentSetUpdateTypeFn = FAST_ErrorCode (*)(FAST_SegmentMapConfig*, FAST_SegmentMapUpdateType);
using SegmentCreateFn = FAST_ErrorCode (*)(FAST_SegmentMapHandle*, size_t, const int32_t*, FAST_SegmentMapConfig*);
using SegmentDestroyFn = void (*)(FAST_SegmentMapHandle);
using SegmentUpdateFn = FAST_ErrorCode (*)(FAST_SegmentMapHandle, size_t, size_t, int32_t);
using SegmentQueryFn = FAST_ErrorCode (*)(FAST_SegmentMapHandle, size_t, size_t, int32_t*);

using RectCreateConfigFn = FAST_ErrorCode (*)(FAST_RectPartitionConfig**);
using RectDestroyConfigFn = void (*)(FAST_RectPartitionConfig*);
using RectSetAlgoFn = FAST_ErrorCode (*)(FAST_RectPartitionConfig*, const char*);
using RectSolveFn = FAST_ErrorCode (*)(FAST_RectPartitionConfig*, size_t, const FAST_Rect*, FAST_Rect*, size_t*);

struct SegmentApi {
    void* lib = nullptr;
    SegmentCreateConfigFn createConfig = nullptr;
    SegmentDestroyConfigFn destroyConfig = nullptr;
    SegmentSetQueryTypeFn setQueryType = nullptr;
    SegmentSetUpdateTypeFn setUpdateType = nullptr;
    SegmentCreateFn create = nullptr;
    SegmentDestroyFn destroy = nullptr;
    SegmentUpdateFn update = nullptr;
    SegmentQueryFn query = nullptr;
    std::string error;
};

struct RectApi {
    void* lib = nullptr;
    RectCreateConfigFn createConfig = nullptr;
    RectDestroyConfigFn destroyConfig = nullptr;
    RectSetAlgoFn setAlgo = nullptr;
    RectSolveFn solve = nullptr;
    std::string error;
};

std::string DlErrorString()
{
    const char* error = dlerror();
    return error == nullptr ? "unknown runtime loader error" : error;
}

template<typename T>
bool LoadSymbol(void* lib, const char* name, T& symbol, std::string& error)
{
    dlerror();
    symbol = reinterpret_cast<T>(dlsym(lib, name));
    if (symbol == nullptr) {
        error = std::string("Missing symbol: ") + name + " - " + DlErrorString();
        return false;
    }
    return true;
}

SegmentApi LoadSegmentApi()
{
    SegmentApi api;
    dlerror();
    api.lib = dlopen("libfast_ads.so", RTLD_LAZY);
    if (api.lib == nullptr) {
        api.error = std::string("dlopen libfast_ads.so failed: ") + DlErrorString();
        return api;
    }

    bool ok = true;
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_CreateConfig", api.createConfig, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_DestroyConfig", api.destroyConfig, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_SetQueryType", api.setQueryType, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_SetUpdateType", api.setUpdateType, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_Create", api.create, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_Destroy", api.destroy, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_Update", api.update, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_SegmentMap_Query", api.query, api.error);

    if (!ok) {
        dlclose(api.lib);
        api.lib = nullptr;
    }
    return api;
}

RectApi LoadRectApi()
{
    RectApi api;
    dlerror();
    api.lib = dlopen("libfast_solver.so", RTLD_LAZY);
    if (api.lib == nullptr) {
        api.error = std::string("dlopen libfast_solver.so failed: ") + DlErrorString();
        return api;
    }

    bool ok = true;
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_RectPartition_CreateConfig", api.createConfig, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_RectPartition_DestroyConfig", api.destroyConfig, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_RectPartition_SetAlgo", api.setAlgo, api.error);
    ok = ok && LoadSymbol(api.lib, "HMS_FAST_RectPartition_Solve", api.solve, api.error);

    if (!ok) {
        dlclose(api.lib);
        api.lib = nullptr;
    }
    return api;
}

napi_value CreateString(napi_env env, const std::string& value)
{
    napi_value result = nullptr;
    napi_create_string_utf8(env, value.c_str(), value.length(), &result);
    return result;
}

napi_value CreateBool(napi_env env, bool value)
{
    napi_value result = nullptr;
    napi_get_boolean(env, value, &result);
    return result;
}

napi_value CreateInt(napi_env env, int32_t value)
{
    napi_value result = nullptr;
    napi_create_int32(env, value, &result);
    return result;
}

void SetNamedValue(napi_env env, napi_value object, const char* key, napi_value value)
{
    napi_set_named_property(env, object, key, value);
}

napi_value CreateEnvironmentStatus(napi_env env)
{
    SegmentApi segmentApi = LoadSegmentApi();
    RectApi rectApi = LoadRectApi();

    napi_value result = nullptr;
    napi_create_object(env, &result);
    SetNamedValue(env, result, "segmentMapAvailable", CreateBool(env, segmentApi.lib != nullptr));
    SetNamedValue(env, result, "segmentMapMessage",
        CreateString(env, segmentApi.lib != nullptr ? "FAST SegmentMap symbols loaded." : segmentApi.error));
    SetNamedValue(env, result, "rectPartitionAvailable", CreateBool(env, rectApi.lib != nullptr));
    SetNamedValue(env, result, "rectPartitionMessage",
        CreateString(env, rectApi.lib != nullptr ? "FAST RectPartition symbols loaded." : rectApi.error));
    SetNamedValue(env, result, "dspAvailable", CreateBool(env, false));
    SetNamedValue(env, result, "dspMessage",
        CreateString(env, "Current SDK does not expose FAST DSP headers or symbols."));

    if (segmentApi.lib != nullptr) {
        dlclose(segmentApi.lib);
    }
    if (rectApi.lib != nullptr) {
        dlclose(rectApi.lib);
    }
    return result;
}

bool GetIntArray(napi_env env, napi_value value, std::vector<int32_t>& output, std::string& error)
{
    bool isArray = false;
    napi_is_array(env, value, &isArray);
    if (!isArray) {
        error = "Expected an array of integers.";
        return false;
    }

    uint32_t length = 0;
    napi_get_array_length(env, value, &length);
    output.reserve(length);
    for (uint32_t index = 0; index < length; index++) {
        napi_value item = nullptr;
        napi_get_element(env, value, index, &item);
        int32_t number = 0;
        if (napi_get_value_int32(env, item, &number) != napi_ok) {
            error = "Array contains a non-integer value.";
            return false;
        }
        output.push_back(number);
    }
    return true;
}

bool GetRectArray(napi_env env, napi_value value, std::vector<FAST_Rect>& output, std::string& error)
{
    bool isArray = false;
    napi_is_array(env, value, &isArray);
    if (!isArray) {
        error = "Expected an array of rectangles.";
        return false;
    }

    uint32_t length = 0;
    napi_get_array_length(env, value, &length);
    output.reserve(length);

    for (uint32_t index = 0; index < length; index++) {
        napi_value rectValue = nullptr;
        napi_get_element(env, value, index, &rectValue);
        bool isRectArray = false;
        napi_is_array(env, rectValue, &isRectArray);
        if (!isRectArray) {
          error = "Each rectangle must be a four-element array.";
          return false;
        }

        uint32_t rectLength = 0;
        napi_get_array_length(env, rectValue, &rectLength);
        if (rectLength != 4) {
            error = "Each rectangle must contain [left, top, right, bottom].";
            return false;
        }

        // ArkTS 侧把每个矩形传成 [left, top, right, bottom]，与 FAST_Rect 字段一一对应。
        FAST_Rect rect {};
        int32_t coords[4] = {0, 0, 0, 0};
        for (uint32_t coordIndex = 0; coordIndex < 4; coordIndex++) {
            napi_value coordValue = nullptr;
            napi_get_element(env, rectValue, coordIndex, &coordValue);
            if (napi_get_value_int32(env, coordValue, &coords[coordIndex]) != napi_ok) {
                error = "Rectangle coordinates must be integers.";
                return false;
            }
        }
        rect.left = coords[0];
        rect.top = coords[1];
        rect.right = coords[2];
        rect.bottom = coords[3];
        output.push_back(rect);
    }
    return true;
}

napi_value CreateSegmentResult(napi_env env, bool success, bool available, FAST_ErrorCode code,
    const std::string& message, int32_t beforeQuery, int32_t afterQuery)
{
    napi_value result = nullptr;
    napi_create_object(env, &result);
    SetNamedValue(env, result, "success", CreateBool(env, success));
    SetNamedValue(env, result, "available", CreateBool(env, available));
    SetNamedValue(env, result, "code", CreateInt(env, static_cast<int32_t>(code)));
    SetNamedValue(env, result, "message", CreateString(env, message));
    SetNamedValue(env, result, "beforeQuery", CreateInt(env, beforeQuery));
    SetNamedValue(env, result, "afterQuery", CreateInt(env, afterQuery));
    return result;
}

napi_value CreateRectResult(napi_env env, bool success, bool available, FAST_ErrorCode code,
    const std::string& message, size_t inputCount, size_t outputCount, const std::vector<FAST_Rect>& outputRects)
{
    napi_value result = nullptr;
    napi_create_object(env, &result);
    SetNamedValue(env, result, "success", CreateBool(env, success));
    SetNamedValue(env, result, "available", CreateBool(env, available));
    SetNamedValue(env, result, "code", CreateInt(env, static_cast<int32_t>(code)));
    SetNamedValue(env, result, "message", CreateString(env, message));
    SetNamedValue(env, result, "inputCount", CreateInt(env, static_cast<int32_t>(inputCount)));
    SetNamedValue(env, result, "outputCount", CreateInt(env, static_cast<int32_t>(outputCount)));

    napi_value rectArray = nullptr;
    napi_create_array_with_length(env, outputRects.size(), &rectArray);
    for (size_t index = 0; index < outputRects.size(); index++) {
        napi_value rectValue = nullptr;
        napi_create_array_with_length(env, 4, &rectValue);
        napi_set_element(env, rectValue, 0, CreateInt(env, outputRects[index].left));
        napi_set_element(env, rectValue, 1, CreateInt(env, outputRects[index].top));
        napi_set_element(env, rectValue, 2, CreateInt(env, outputRects[index].right));
        napi_set_element(env, rectValue, 3, CreateInt(env, outputRects[index].bottom));
        napi_set_element(env, rectArray, index, rectValue);
    }
    SetNamedValue(env, result, "optimizedRects", rectArray);
    return result;
}

napi_value GetEnvironmentStatus(napi_env env, napi_callback_info info)
{
    (void)info;
    return CreateEnvironmentStatus(env);
}

napi_value RunSegmentMapDemo(napi_env env, napi_callback_info info)
{
    size_t argc = 8;
    napi_value args[8] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    std::vector<int32_t> input;
    std::string error;
    if (argc < 8 || !GetIntArray(env, args[0], input, error)) {
        return CreateSegmentResult(env, false, false, FAST_ERROR_CODE_ILLEGAL_INPUT, error, 0, 0);
    }

    int32_t queryType = 0;
    int32_t updateType = 0;
    int32_t updateLeft = 0;
    int32_t updateRight = 0;
    int32_t updateValue = 0;
    int32_t queryLeft = 0;
    int32_t queryRight = 0;

    napi_get_value_int32(env, args[1], &queryType);
    napi_get_value_int32(env, args[2], &updateType);
    napi_get_value_int32(env, args[3], &updateLeft);
    napi_get_value_int32(env, args[4], &updateRight);
    napi_get_value_int32(env, args[5], &updateValue);
    napi_get_value_int32(env, args[6], &queryLeft);
    napi_get_value_int32(env, args[7], &queryRight);

    SegmentApi api = LoadSegmentApi();
    if (api.lib == nullptr) {
        return CreateSegmentResult(env, false, false, FAST_ERROR_CODE_FAIL, api.error, 0, 0);
    }

    FAST_SegmentMapConfig* config = nullptr;
    FAST_SegmentMapHandle handle = nullptr;
    int32_t beforeQuery = 0;
    int32_t afterQuery = 0;
    FAST_ErrorCode code = api.createConfig(&config);
    if (code == FAST_ERROR_CODE_SUCCESS) {
        code = api.setQueryType(config, static_cast<FAST_SegmentMapQueryType>(queryType));
    }
    if (code == FAST_ERROR_CODE_SUCCESS) {
        code = api.setUpdateType(config, static_cast<FAST_SegmentMapUpdateType>(updateType));
    }
    if (code == FAST_ERROR_CODE_SUCCESS) {
        code = api.create(&handle, input.size(), input.data(), config);
    }
    if (code == FAST_ERROR_CODE_SUCCESS) {
        code = api.query(handle, static_cast<size_t>(queryLeft), static_cast<size_t>(queryRight), &beforeQuery);
    }
    if (code == FAST_ERROR_CODE_SUCCESS) {
        code = api.update(handle, static_cast<size_t>(updateLeft), static_cast<size_t>(updateRight), updateValue);
    }
    if (code == FAST_ERROR_CODE_SUCCESS) {
        code = api.query(handle, static_cast<size_t>(queryLeft), static_cast<size_t>(queryRight), &afterQuery);
    }

    std::string message = code == FAST_ERROR_CODE_SUCCESS ?
        "FAST SegmentMap executed successfully." : "FAST SegmentMap execution failed.";

    if (handle != nullptr) {
        api.destroy(handle);
    }
    if (config != nullptr) {
        api.destroyConfig(config);
    }
    dlclose(api.lib);

    return CreateSegmentResult(env, code == FAST_ERROR_CODE_SUCCESS, true, code, message, beforeQuery, afterQuery);
}

napi_value RunRectPartition(napi_env env, napi_callback_info info)
{
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    std::vector<FAST_Rect> input;
    std::string error;
    if (argc < 1 || !GetRectArray(env, args[0], input, error)) {
        return CreateRectResult(env, false, false, FAST_ERROR_CODE_ILLEGAL_INPUT, error, 0, 0, {});
    }

    RectApi api = LoadRectApi();
    if (api.lib == nullptr) {
        return CreateRectResult(env, false, false, FAST_ERROR_CODE_FAIL, api.error, input.size(), 0, {});
    }

    FAST_RectPartitionConfig* config = nullptr;
    FAST_ErrorCode code = api.createConfig(&config);
    if (code == FAST_ERROR_CODE_SUCCESS) {
        // 当前 SDK 文档中可用的算法就是 SweepLineAlgo，头文件也说明它是默认算法。
        code = api.setAlgo(config, "SweepLineAlgo");
    }

    // Solve 会把结果写入调用方提供的缓冲区，所以这里先预留一个相对充足的输出空间。
    std::vector<FAST_Rect> output(std::max<size_t>(input.size() * 8, 32));
    size_t resultSize = output.size();
    if (code == FAST_ERROR_CODE_SUCCESS) {
        code = api.solve(config, input.size(), input.data(), output.data(), &resultSize);
    }

    if (config != nullptr) {
        api.destroyConfig(config);
    }
    dlclose(api.lib);

    std::vector<FAST_Rect> finalOutput;
    if (code == FAST_ERROR_CODE_SUCCESS && resultSize <= output.size()) {
        finalOutput.assign(output.begin(), output.begin() + static_cast<long>(resultSize));
    }

    std::string message = code == FAST_ERROR_CODE_SUCCESS ?
        "FAST RectPartition executed successfully." : "FAST RectPartition execution failed.";
    return CreateRectResult(env, code == FAST_ERROR_CODE_SUCCESS, true, code, message,
        input.size(), finalOutput.size(), finalOutput);
}

static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor descriptors[] = {
        { "getEnvironmentStatus", nullptr, GetEnvironmentStatus, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "runSegmentMapDemo", nullptr, RunSegmentMapDemo, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "runRectPartition", nullptr, RunRectPartition, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    return exports;
}

static napi_module fastKitModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "fastkit",
    .nm_priv = nullptr,
    .reserved = { 0 }
};

} // 命名空间结束

extern "C" __attribute__((constructor)) void RegisterFastKitModule(void)
{
    napi_module_register(&fastKitModule);
}
