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


def copy_one_file(info, in_img, out_img, node):
    # Get rid of leading slashing. Zip does not like it.
    write_to = node
    while (write_to.find('/') == 0):
        write_to = node[1:]

    tgt = get_image(info.input_zip, in_img)

    if tgt:
        print \
            "NOTE: Copying %s to %s/%s that needs special processing on device. Make sure this is the way you want." \
                % (in_img, write_to, out_img)

        common.ZipWriteStr(info.output_zip, "%s/%s" % (write_to, out_img), tgt.data);

        return True;
    else:
        # should never reach this unless something is very wrong
        print "WARNING: Cannot copying %s to %s/%s." % (in_img, write_to, out_img)
        return False;


def copy_files_to_archive_safe(info, in_img, out_img, node, dest_dir):
    for zipfile in info.input_zip.namelist():
        if fnmatch.fnmatchcase(zipfile, in_img):
            # if out_img == '*', extract filename from zipfile
            # else use what is passed in.
            if out_img == "*":
                out_fn = os.path.basename(zipfile);
            else:
                out_fn = out_img

            if copy_one_file(info, zipfile, out_fn, node):
                info.script.Print("Writing %s to %s..." % (out_fn, dest_dir))
                info.script.script.append('package_extract_file_safe("%s/%s", "%s/%s");' \
                                              % (node, out_fn, dest_dir, out_fn));


def copy_bootloader_files(info):
    # note: cannot have leading slash when writing to zip
    #       so we skip it in the list
    # note: make sure syslinux is executed first before
    #       mounting the partition to copy files over

    # Extract the android_syslinux binary to /tmp,
    # and execute it to update the bootloader
    in_img = "RADIO/android_syslinux"
    out_img = "android_syslinux"
    node = "others/bin"

    # intentionally do not check if fstab is valid.
    # the build will fail to signal issue.
    fstab = info.script.info.get("fstab", None)

    # copy and execute android_linux to update bootloader
    if copy_one_file(info, in_img, out_img, node):
        info.script.Print("Updating bootloader using %s..." % (out_img))
        info.script.script.append('package_extract_file("%s/%s", "/tmp/%s");' \
                                      % (node, out_img, out_img));
        info.script.SetPermissions('/tmp', 0, 0, 1023); # 1023 => 1777
        info.script.SetPermissions('/tmp/%s' % (out_img), 0, 0, 493); # 493 => 0755

        info.script.script.append('run_program("/tmp/%s", "--update", "%s");' % \
                           (out_img, fstab['/bootloader'].device))

    # AOSP edify generator in build/ does not support vfat.
    # So we need to generate the full command to mount here.
    info.script.script.append('mkdir("/bootloader");')
    info.script.script.append('mount("vfat", "EMMC", "%s", "/bootloader");' % (fstab['/bootloader'].device))

    # Copy the bootloader files
    for in_img, out_img, node, dest_dir in [
            ("RADIO/*.c32", "*", "others/syslinux", "/bootloader"),
            ("RADIO/intellogo.png", "intellogo.png", "others/syslinux", "/bootloader"),
            ]:
        copy_files_to_archive_safe(info, in_img, out_img, node, dest_dir)

    info.script.script.append('unmount("/bootloader");')


def FullOTA_InstallEnd(info):
    update_raw_image_verify(info, "RADIO/droidboot.img", "droidboot.img", "/droidboot", False)
    update_raw_image_install(info, "/droidboot")

    copy_bootloader_files(info);


def IncrementalOTA_VerifyEnd(info):
    update_raw_image_verify(info, "RADIO/droidboot.img", "droidboot.img", "/droidboot", True)


def IncrementalOTA_InstallEnd(info):
    update_raw_image_install(info, "/droidboot")

    copy_bootloader_files(info);
