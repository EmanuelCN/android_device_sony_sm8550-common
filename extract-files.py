#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixup_remove,
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None

namespace_imports = [
    'hardware/qcom-caf/sm8550',
    'hardware/qcom-caf/wlan',
    'hardware/sony',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
    'vendor/sony/sm8550-common',
]

lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'vendor.qti.hardware.fm@1.0',
        'vendor.qti.hardware.data.cne.internal.api@1.0',
        'vendor.qti.hardware.data.cne.internal.constants@1.0',
        'vendor.qti.hardware.data.cne.internal.server@1.0',
        'vendor.qti.hardware.data.connection@1.0',
        'vendor.qti.hardware.data.connection@1.1',
        'vendor.qti.hardware.data.dynamicdds@1.0',
        'vendor.qti.hardware.data.iwlan@1.0',
        'vendor.qti.hardware.data.qmi@1.0',
        'com.qualcomm.qti.dpm.api@1.0',
        'vendor.qti.hardware.dpmservice@1.0',
        'vendor.qti.diaghal@1.0',
        'vendor.qti.imsrtpservice@3.0',
        'vendor.qti.imsrtpservice@3.1',
        'vendor.qti.hardware.qccsyshal@1.0',
        'vendor.qti.hardware.qccsyshal@1.1',
        'vendor.qti.hardware.qccsyshal@1.2',
        'vendor.qti.hardware.qccvndhal@1.0',
        'vendor.qti.hardware.wifidisplaysession@1.0',
    ): lib_fixup_vendor_suffix,
    (
        'libwpa_client',
        'libwfdaac_vendor',
        'libagmclient',
        'libpalclient',
    ): lib_fixup_remove,
}

blob_fixups: blob_fixups_user_type = {
    (
        'vendor/bin/hw/android.hardware.security.keymint-service-qti',
        'vendor/bin/hw/vendor.semc.hardware.secd@1.1-service',
        'vendor/bin/keyprovd',
        'vendor/lib64/libqtikeymint.so',
        'vendor/lib64/librkp.so',
    ): blob_fixup().add_needed(
        'android.hardware.security.rkp-V3-ndk.so'
    ),
    'vendor/bin/slim_daemon': blob_fixup().add_needed(
        'libc++_shared.so'
    ),
    'vendor/etc/msm_irqbalance.conf': blob_fixup().regex_replace(
        'IGNORED_IRQ=27,23,38', 'IGNORED_IRQ=27,23,38,115,332'
    ),
    (
    'vendor/etc/seccomp_policy/atfwd@2.0.policy',
    'vendor/etc/seccomp_policy/wfdhdcphalservice.policy'
    ): blob_fixup()
        .add_line_if_missing('gettid: 1'),
    'vendor/etc/seccomp_policy/qwesd@2.0.policy': blob_fixup()
        .add_line_if_missing('gettid: 1')
	.add_line_if_missing('pipe2: 1'),
    'vendor/lib64/vendor.semc.hardware.extlight-V1-ndk_platform.so': blob_fixup().replace_needed(
        'android.hardware.light-V1-ndk_platform.so',
        'android.hardware.light-V1-ndk.so'
    ),
    'system_ext/lib64/libwfdservice.so': blob_fixup().replace_needed(
        'android.media.audio.common.types-V2-cpp.so',
        'android.media.audio.common.types-V4-cpp.so'
    ),
    'system_ext/lib64/libwfdmmsrc_system.so': blob_fixup().add_needed(
        'libgui_shim.so'
    ),
    'system_ext/lib64/libwfdnative.so': blob_fixup().add_needed(
        'libinput_shim.so'
    ),
    'vendor/lib64/libqcodec2_core.so': blob_fixup().add_needed(
        'libcodec2_shim.so'
    ),
    'vendor/lib64/vendor.libdpmframework.so': blob_fixup().add_needed(
	'libhidlbase_shim.so'
    ),
}


module = ExtractUtilsModule(
    'sm8550-common',
    'sony',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
