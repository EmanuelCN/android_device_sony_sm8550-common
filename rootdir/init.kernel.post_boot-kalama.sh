#=============================================================================
# Copyright (c) 2020-2022 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================


rev=`cat /sys/devices/soc0/revision`
ddr_type=`od -An -tx /proc/device-tree/memory/ddr_device_type`
ddr_type4="07"
ddr_type5="08"

# Configure RT parameters
echo "1000000" > /proc/sys/kernel/sched_rt_period_us
echo "950000" > /proc/sys/kernel/sched_rt_runtime_us

# Set cpu governor
echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy3/scaling_governor
echo "schedutil" > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor

# Cpuset parameters
echo 0-1 > /dev/cpuset/background/cpus
echo 0-6 > /dev/cpuset/foreground/cpus
echo 0-2 > /dev/cpuset/system-background/cpus

# Reset the RT boost, which is 1024 (max) by default.
echo 0 > /proc/sys/kernel/sched_util_clamp_min_rt_default

### I/O & FS tuning ###

# Reduce urgent gc sleep time.
echo "5" > /dev/sys/fs/by-name/userdata/gc_urgent_sleep_time
echo "5" > /sys/fs/f2fs/dm-54/gc_urgent_sleep_time
echo "5" > /sys/fs/f2fs/sda52/gc_urgent_sleep_time

# Tune F2FS.
echo "20" > /sys/fs/f2fs/dm-54/min_fsync_blocks
echo "20" > /sys/fs/f2fs/sda52/min_fsync_blocks
echo "10000" > /sys/fs/f2fs/dm-54/max_discard_issue_time
echo "10000" > /sys/fs/f2fs/sda52/max_discard_issue_time

# Tune Userdata.
echo "8" > /dev/sys/fs/by-name/userdata/data_io_flag
echo "8" > /dev/sys/fs/by-name/userdata/node_io_flag
echo "128" > /dev/sys/fs/by-name/userdata/seq_file_ra_mul

# Fully disable I/O stats.
for i in /sys/block/*/queue; do
  echo "0" > $i/iostats;
done;

# Set read_ahead to 128kb.
for i in /sys/block/*/queue; do
  echo "128" > $i/read_ahead_kb;
done;

# Set default I/O scheduler to ssg
echo "ssg" > /sys/block/sda/queue/scheduler
echo "ssg" > /sys/block/sdb/queue/scheduler
echo "ssg" > /sys/block/sdc/queue/scheduler

### Memory management tuning ###

# Set vm swapiness to 60.
echo "60" > /proc/sys/vm/swappiness

# Reduce vm stat interval to reduce jitter.
echo "20" > /proc/sys/vm/stat_interval

# Tune dirty data writebacks.
echo "52428800" > /proc/sys/vm/dirty_background_bytes
echo "209715200" > /proc/sys/vm/dirty_bytes

# Disable page cluster.
echo "0" > /proc/sys/vm/page-cluster

# Disable transparent hugepage.
echo "0" > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
echo "never" > /sys/kernel/mm/transparent_hugepage/defrag
echo "never" > /sys/kernel/mm/transparent_hugepage/enabled
echo "never" > /sys/kernel/mm/transparent_hugepage/shmem_enabled
echo "0" > /sys/kernel/mm/transparent_hugepage/use_zero_page

# Set compact_unevictable_allowed to 0 in order to avoid potential stalls that can occur during compactions of unevictable pages, preempt_rt sets it to 0.
echo "0" > /proc/sys/vm/compact_unevictable_allowed

# Set compaction_proactiveness to 0 in order to reduce cpu latency spikes.
echo "0" > /proc/sys/vm/compaction_proactiveness

# Disable oom dump tasks its not desirable for android where we have numerious tasks.
echo "0" > /proc/sys/vm/oom_dump_tasks

### Scheduler tuning ###

# Decrease pelt multiplier to 2 (16ms halflife), to improve power consumption.
echo "2" > /proc/sys/kernel/sched_pelt_multiplier

# Configure uclamp.
echo "1" > /dev/cpuctl/top-app/cpu.uclamp.latency_sensitive
echo "80" > /dev/cpuctl/foreground/cpu.uclamp.max
echo "10" > /dev/cpuctl/background/cpu.uclamp.max
echo "50" > /dev/cpuctl/system-background/cpu.uclamp.max
echo "10" > /dev/cpuctl/dex2oat/cpu.uclamp.max

# Setup cpu.shares to throttle background groups (dex2oat - 2.5% bg ~ 5% sysbg ~ 50% foreground ~ 60%).
echo "1024" > /dev/cpuctl/background/cpu.shares
echo "10240" > /dev/cpuctl/system-background/cpu.shares
echo "512" > /dev/cpuctl/dex2oat/cpu.shares
echo "16384" > /dev/cpuctl/foreground/cpu.shares
echo "20480" > /dev/cpuctl/system/cpu.shares

# We only have /dev/cpuctl/system/cpu.shares system and background groups holding tasks and the groups below are empty.
echo "20480" > /dev/cpuctl/camera-daemon/cpu.shares
echo "20480" > /dev/cpuctl/nnapi-hal/cpu.shares
echo "20480" > /dev/cpuctl/rt/cpu.shares
echo "20480" > /dev/cpuctl/top-app/cpu.shares

### Disable debugging & logging ##

# Disable sched stats.
echo "0" > /proc/sys/kernel/sched_schedstats

# Disable sync on suspend.
echo "0" > /sys/power/sync_on_suspend

# Disable tracing.
echo "0" > /sys/kernel/tracing/options/trace_printk
echo "0" > /sys/kernel/tracing/tracing_on

# Disable scsi logging.
echo "0" > /proc/sys/dev/scsi/logging_level

# Disable devcoredump.
echo "1" > /sys/class/devcoredump/disabled

# Reduce ufs auto hibernate time to 1ms.
echo "1000" > /sys/bus/platform/devices/1d84000.ufshc/auto_hibern8

# configure bus-dcvs
bus_dcvs="/sys/devices/system/cpu/bus_dcvs"

for device in $bus_dcvs/*
do
	cat $device/hw_min_freq > $device/boost_freq
done

for llccbw in $bus_dcvs/LLCC/*bwmon-llcc
do
	echo "4577 7110 9155 12298 14236 15258" > $llccbw/mbps_zones
	echo 4 > $llccbw/sample_ms
	echo 80 > $llccbw/io_percent
	echo 20 > $llccbw/hist_memory
	echo 5 > $llccbw/hyst_length
	echo 1 > $llccbw/idle_length
	echo 30 > $llccbw/down_thres
	echo 0 > $llccbw/guard_band_mbps
	echo 250 > $llccbw/up_scale
	echo 1600 > $llccbw/idle_mbps
	echo 806000 > $llccbw/max_freq
	echo 40 > $llccbw/window_ms
done

for ddrbw in $bus_dcvs/DDR/*bwmon-ddr
do
	echo "2086 5931 6515 7980 12191 16259" > $ddrbw/mbps_zones
	echo 4 > $ddrbw/sample_ms
	echo 80 > $ddrbw/io_percent
	echo 20 > $ddrbw/hist_memory
	echo 5 > $ddrbw/hyst_length
	echo 1 > $ddrbw/idle_length
	echo 30 > $ddrbw/down_thres
	echo 0 > $ddrbw/guard_band_mbps
	echo 250 > $ddrbw/up_scale
	echo 1600 > $ddrbw/idle_mbps
	echo 2736000 > $ddrbw/max_freq
	echo 40 > $ddrbw/window_ms
done

for latfloor in $bus_dcvs/*/*latfloor
do
	echo 25000 > $latfloor/ipm_ceil
done

for l3gold in $bus_dcvs/L3/*gold
do
	echo 4000 > $l3gold/ipm_ceil
done

for l3prime in $bus_dcvs/L3/*prime
do
	echo 20000 > $l3prime/ipm_ceil
done

for qosgold in $bus_dcvs/DDRQOS/*gold
do
	echo 50 > $qosgold/ipm_ceil
done

for qosprime in $bus_dcvs/DDRQOS/*prime
do
	echo 100 > $qosprime/ipm_ceil
done

for ddrprime in $bus_dcvs/DDR/*prime
do
	echo 25 > $ddrprime/freq_scale_pct
	echo 1500 > $ddrprime/freq_scale_floor_mhz
	echo 2726 > $ddrprime/freq_scale_ceil_mhz
done

echo s2idle > /sys/power/mem_sleep
echo N > /sys/devices/system/cpu/qcom_lpm/parameters/sleep_disabled

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
	image_version="10:"
	image_version+=`getprop ro.build.id`
	image_version+=":"
	image_version+=`getprop ro.build.version.incremental`
	image_variant=`getprop ro.product.name`
	image_variant+="-"
	image_variant+=`getprop ro.build.type`
	oem_version=`getprop ro.build.version.codename`
	echo 10 > /sys/devices/soc0/select_image
	echo $image_version > /sys/devices/soc0/image_version
	echo $image_variant > /sys/devices/soc0/image_variant
	echo $oem_version > /sys/devices/soc0/image_crm_version
fi

echo 4 > /proc/sys/kernel/printk

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
	"1")
		echo "Enable console config to $console_config"
		echo 0 > /proc/sys/kernel/printk
	;;
	*)
		echo "Enable console config to $console_config"
	;;
esac

setprop vendor.post_boot.parsed 1
