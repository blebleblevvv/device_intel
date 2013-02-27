import common
import fnmatch
import os

img = {}

def get_image(archive, name):
    try:
        ret = common.File(name, archive.read(name))
    except KeyError:
        ret = None
    return ret

def update_raw_image_verify(info, in_img, out_img, node, inc):
    if inc:
        src = get_image(info.source_zip, in_img)
        tgt = get_image(info.target_zip, in_img)
    else:
        src = None
        tgt = get_image(info.input_zip, in_img)

    if not tgt:
        return

    imgtype, imgdev = common.GetTypeAndDevice(node, info.info_dict)

    if src:
        if src.data == tgt.data:
            print "%s images identical, not patching" % (in_img,)
            return
        else:
            print "%s images differ, will patch" % (in_img,)
        d = common.Difference(tgt, src)
        _, _, d = d.ComputePatch()
        print "%s      target: %d  source: %d  diff: %d" % (
            out_img, tgt.size, src.size, len(d))
        out_img = "patch/%s.p" % (out_img,)
        common.ZipWriteStr(info.output_zip, out_img, d)
        info.script.PatchCheck("%s:%s:%d:%s:%d:%s" %
                      (imgtype, imgdev,
                       src.size, src.sha1,
                       tgt.size, tgt.sha1))
        info.script.CacheFreeSpaceCheck(src.size)

    img[node] = {}
    img[node]["out_img"] = out_img
    img[node]["src"] = src
    img[node]["tgt"] = tgt
    img[node]["type"] = imgtype
    img[node]["dev"] = imgdev

def update_raw_image_install(info, node):
    if node not in img:
        return

    src = img[node]["src"]
    tgt = img[node]["tgt"]
    out_img = img[node]["out_img"]

    if src:
        imgtype = img[node]["type"]
        imgdev = img[node]["dev"]

        info.script.Print("Patching %s" % (node,))
        info.script.ApplyPatch("%s:%s:%d:%s:%d:%s"
                % (imgtype, imgdev,
                   src.size, src.sha1,
                   tgt.size, tgt.sha1),
                "-",
                tgt.size, tgt.sha1,
                src.sha1, out_img)
    else:
        common.ZipWriteStr(info.output_zip, out_img, tgt.data)
        info.script.Print("Writing %s to %s..." % (out_img, node))
        info.script.WriteRawImage(node, out_img)


verbatim_targets = []
patch_list = []
delete_files = None
target_data = None
source_data = None

def LoadBootloaderFiles(z):
    out = {}
    for info in z.infolist():
        # XXX assumes only stuff that ends in .efi belongs in ESP
        # reasonable in current design
        if info.filename.startswith("RADIO/") and info.filename.endswith(".efi"):
            basefilename = info.filename[6:]
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
            tf.AddToZip(output_zip)
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


def IncrementalOTA_Assertions(info):
    EspUpdateInit(info, True)
    if delete_files or patch_list or verbatim_files:
        MountEsp(info)


def IncrementalOTA_VerifyEnd(info):
    update_raw_image_verify(info, "RADIO/droidboot.img", "droidboot.img", "/fastboot", True)
    for fn, tf, sf, size, patch_sha in patch_list:
        info.script.PatchCheck("/"+fn, tf.sha1, sf.sha1)


def swap_entries(info):
    fstab = info.script.info.get("fstab", None)
    info.script.script.append('swap_entries("%s", "bootloader", "bootloader2");' %
            (fstab['/bootloader'].device,))

def IncrementalOTA_InstallEnd(info):
    update_raw_image_install(info, "/droidboot")

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

def FullOTA_Assertions(info):
    EspUpdateInit(info, False)
    MountEsp(info)


def FullOTA_InstallEnd(info):
    update_raw_image_verify(info, "RADIO/droidboot.img", "droidboot.img", "/fastboot", False)
    update_raw_image_install(info, "/droidboot")

    info.script.Print("Copying updated bootloader files...")
    info.script.UnpackPackageDir("bootloader", "/bootloader")
    info.script.script.append('unmount("/bootloader");')
    swap_entries(info)


