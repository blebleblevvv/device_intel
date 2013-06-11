import common
import fnmatch
import os

verbatim_targets = []
patch_list = []
delete_files = None
target_data = None
source_data = None
OPTIONS = common.OPTIONS

def LoadBootloaderFiles(z):
    out = {}
    for info in z.infolist():
        if info.filename.startswith("EFI/"):
            basefilename = info.filename[4:]
            fn = "bootloader/" + basefilename
            data = z.read(info.filename)
            out[fn] = common.File(fn, data)
    return out

def EspUpdateInit(info, incremental):
    global target_data
    global source_data
    global delete_files

    if incremental:
        target_data = LoadBootloaderFiles(info.target_zip)
        source_data = LoadBootloaderFiles(info.source_zip)
    else:
        target_data = LoadBootloaderFiles(info.input_zip)
        source_data = None

    diffs = []

    for fn in sorted(target_data.keys()):
        tf = target_data[fn]
        if incremental:
            sf = source_data.get(fn, None)
        else:
            sf = None

        if sf is None:
            tf.AddToZip(info.output_zip)
            verbatim_targets.append(fn)
        elif tf.sha1 != sf.sha1:
            diffs.append(common.Difference(tf, sf))

    if not incremental:
        return

    common.ComputeDifferences(diffs)

    for diff in diffs:
        tf, sf, d = diff.GetPatch()
        if d is None or len(d) > tf.size * 0.95:
            tf.AddToZip(info.output_zip)
            verbatim_targets.append(tf.name)
        else:
            common.ZipWriteStr(info.output_zip, "patch/" + tf.name + ".p", d)
            patch_list.append((tf.name, tf, sf, tf.size, common.sha1(d).hexdigest()))

    delete_files = (["/"+i[0] for i in verbatim_targets] +
                     ["/"+i for i in sorted(source_data) if i not in target_data])




def MountEsp(info):
    # AOSP edify generator in build/ does not support vfat.
    # So we need to generate the full command to mount here.
    # TODO bit-for-bit copy bootloader to bootloader2 and mount that
    fstab = info.script.info.get("fstab", None)
    info.script.script.append('copy_partition("%s", "%s");' %
            (fstab['/bootloader'].device, fstab['/bootloader2'].device))
    info.script.script.append('mount("vfat", "EMMC", "%s", "/bootloader");' % (fstab['/bootloader2'].device))


fastboot = {}

def IncrementalOTA_Assertions(info):
    fastboot["source"] = common.GetBootableImage("/tmp/fastboot.img", "fastboot.img",
            OPTIONS.source_tmp, "FASTBOOT", OPTIONS.source_info_dict)
    fastboot["target"] = common.GetBootableImage("/tmp/fastboot.img", "fastboot.img",
            OPTIONS.target_tmp, "FASTBOOT")
    # Policy: if both exist, try to do a patch update
    # if target but not source, write out the target verbatim
    # if source but not target, or neither, do nothing
    if fastboot["target"]:
        if fastboot["source"]:
            fastboot["updating"] = fastboot["source"].data != fastboot["target"].data
            fastboot["verbatim"] = False
        else:
            fastboot["updating"] = False
            fastboot["verbatim"] = True
    else:
        fastboot["updating"] = False
        fastboot["verbatim"] = False

    EspUpdateInit(info, True)
    if delete_files or patch_list or verbatim_targets:
        MountEsp(info)


def IncrementalOTA_VerifyEnd(info):
    # Check fastboot patch
    if fastboot["updating"]:
        target_boot = fastboot["target"]
        source_boot = fastboot["source"]
        d = common.Difference(target_boot, source_boot)
        _, _, d = d.ComputePatch()
        print "fastboot  target: %d  source: %d  diff: %d" % (
            target_boot.size, source_boot.size, len(d))

        common.ZipWriteStr(info.output_zip, "patch/fastboot.img.p", d)

        boot_type, boot_device = common.GetTypeAndDevice("/fastboot", OPTIONS.info_dict)
        info.script.PatchCheck("%s:%s:%d:%s:%d:%s" %
                          (boot_type, boot_device,
                           source_boot.size, source_boot.sha1,
                           target_boot.size, target_boot.sha1))
        fastboot["boot_type"] = boot_type
        fastboot["boot_device"] = boot_device

    # Check ESP component patches
    for fn, tf, sf, size, patch_sha in patch_list:
        info.script.PatchCheck("/"+fn, tf.sha1, sf.sha1)


def swap_entries(info):
    fstab = info.script.info.get("fstab", None)
    info.script.script.append('swap_entries("%s", "bootloader", "bootloader2");' %
            (fstab['/bootloader'].device,))

def IncrementalOTA_InstallEnd(info):
    if fastboot["updating"]:
        target_boot = fastboot["target"]
        source_boot = fastboot["source"]
        boot_type = fastboot["boot_type"]
        boot_device = fastboot["boot_device"]
        info.script.Print("Patching fastboot image...")
        info.script.ApplyPatch("%s:%s:%d:%s:%d:%s"
                          % (boot_type, boot_device,
                             source_boot.size, source_boot.sha1,
                             target_boot.size, target_boot.sha1),
                          "-",
                          target_boot.size, target_boot.sha1,
                          source_boot.sha1, "patch/boot.img.p")
        print "fastboot image changed; including."
    elif fastboot["verbatim"]:
        common.ZipWriteStr(info.output_zip, "fastboot.img", fastboot["target"].data)
        info.script.WriteRawImage("/fastboot", "fastboot.img")
        print "fastboot not present in source archive; including verbatim"
    else:
        print "skipping fastboot update"

    if not delete_files and not patch_list and not verbatim_targets:
        return

    if delete_files:
        info.script.Print("Removing unnecessary bootloader files...")
        info.script.DeleteFiles(delete_files)

    if patch_list:
        info.script.Print("Patching bootloader files...")
        for item in patch_list:
            fn, tf, sf, size, _ = item
            info.script.ApplyPatch("/"+fn, "-", tf.size, tf.sha1, sf.sha1, "patch/"+fn+".p")

    if verbatim_targets:
        info.script.Print("Adding new bootloader files...")
        info.script.UnpackPackageDir("bootloader", "/bootloader")

    info.script.script.append('unmount("/bootloader");')
    swap_entries(info)

    info.script.script.append('update_capsules("/system/etc/firmware/capsules");')

def FullOTA_Assertions(info):
    EspUpdateInit(info, False)
    MountEsp(info)


def FullOTA_InstallEnd(info):
    fastboot_img = common.GetBootableImage("fastboot.img", "fastboot.img",
                                     OPTIONS.input_tmp, "FASTBOOT")
    if fastboot_img:
        common.ZipWriteStr(info.output_zip, "fastboot.img", fastboot_img.data)
        info.script.WriteRawImage("/fastboot", "fastboot.img")
    else:
        print "No fastboot data found, skipping"

    info.script.Print("Copying updated bootloader files...")
    info.script.UnpackPackageDir("bootloader", "/bootloader")
    info.script.script.append('unmount("/bootloader");')
    swap_entries(info)

    info.script.script.append('update_capsules("/system/etc/firmware/capsules");')


