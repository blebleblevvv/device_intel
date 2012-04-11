import common

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
        d = common.Difference(src, tgt)
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


def FullOTA_InstallEnd(info):
    for in_img, out_img, node in [
            ("RADIO/droidboot.img", "droidboot.img", "/droidboot"),
            ("RADIO/bootloader", "bootloader", "/bootloader")]:
        update_raw_image_verify(info, in_img, out_img, node, False)
        update_raw_image_install(info, node)


def IncrementalOTA_VerifyEnd(info):
    for in_img, out_img, node in [
            ("RADIO/droidboot.img", "droidboot.img", "/droidboot"),
            ("RADIO/bootloader", "bootloader", "/bootloader")]:
        update_raw_image_verify(info, in_img, out_img, node, True)


def IncrementalOTA_InstallEnd(info):
    for node in ["/bootloader", "/droidboot"]:
        update_raw_image_install(info, node)

