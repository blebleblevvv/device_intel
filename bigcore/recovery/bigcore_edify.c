/*
 * Copyright 2012 Intel Corporation
 *
 * Author: Andrew Boie <andrew.p.boie@intel.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <regex.h>
#include <dirent.h>

#include <edify/expr.h>
#include <gpt/gpt.h>
#include <cutils/properties.h>

#define CHUNK 1024*1024

#define CAP_LOADING     "/sys/firmware/efi/capsule/loading"
#define CAP_DATA        "/sys/firmware/efi/capsule/data"

struct Capsule {
    char *path;
    struct stat f_stat;
    int existence;
};

static ssize_t robust_read(int fd, void *buf, size_t count)
{
    unsigned char *pos = buf;
    ssize_t ret;
    ssize_t total = 0;
    do {
        ret = read(fd, pos, count);
        if (ret < 0) {
            if (errno != EINTR)
                return -1;
            else
                continue;
        }
        count -= ret;
        pos += ret;
        total += ret;
    } while (count && ret);

    return total;
}


static ssize_t robust_write(int fd, const void *buf, size_t count)
{
    const char *pos = buf;
    ssize_t total_written = 0;
    ssize_t written;

    /* Short write due to insufficient space OK;
     * partitions may not be exactly the same size
     * but underlying fs should be min of both sizes */
    do {
        written = write(fd, pos, count);
        if (written < 0) {
            if (errno != EINTR)
                return -1;
            else
                continue;
        }
        count -= written;
        pos += written;
        total_written += written;
    } while (count && written);

    return total_written;
}

/* Caller needs to provide valid fd(s) and close them after call this function */
static int read_write(int srcfd, int destfd) {
    char *buf = NULL;
    ssize_t to_write;
    ssize_t written;
    int ret = -1;

    buf = malloc(CHUNK);
    if (!buf) {
        printf("%s: memory allocation error", __FUNCTION__);
        return -1;
    }

    while (1) {
        to_write = robust_read(srcfd, buf, CHUNK);
        if (to_write < 0) {
            printf("%s: failed to read source data: %s",
                    __FUNCTION__, strerror(errno));
            goto out;
        }
        if (!to_write)
            break;

        written = robust_write(destfd, buf, to_write);
        if (written != to_write) {
            printf("%s: failed to write data: %s", __FUNCTION__,
                    strerror(errno));
            goto out;
        }
    }

    ret = 0;
out:
    free(buf);
    return ret;
}

static int sysfs_read_int(int *ret, char *fmt, ...)
{
    char path[PATH_MAX];
    va_list ap;
    char buf[4096];
    int fd;
    ssize_t bytes_read;
    int rv = -1;

    va_start(ap, fmt);
    vsnprintf(path, sizeof(path), fmt, ap);
    va_end(ap);

    fd = open(path, O_RDONLY);
    if (fd < 0)
        return -1;

    bytes_read = robust_read(fd, buf, sizeof(buf) - 1);
    if (bytes_read < 0)
        goto out;

    buf[bytes_read] = '\0';
    *ret = atoi(buf);
    rv = 0;
out:
    close(fd);
    return rv;
}


static Value *CopyPartFn(const char *name, State *state, int argc __attribute__((unused)),
        Expr *argv[])
{
    char *src = NULL;
    char *dest = NULL;
    int srcfd = -1;
    int destfd = -1;
    int result = -1;

    if (ReadArgs(state, argv, 2, &src, &dest))
        return NULL;

    if (strlen(src) == 0 || strlen(dest) == 0) {
        ErrorAbort(state, "%s: Missing required argument", name);
        goto done;
    }

    srcfd = open(src, O_RDONLY);
    if (srcfd < 0) {
        ErrorAbort(state, "%s: Unable to open %s for reading: %s",
                name, src, strerror(errno));
        goto done;
    }
    destfd = open(dest, O_WRONLY);
    if (destfd < 0) {
        ErrorAbort(state, "%s: Unable to open %s for writing: %s",
                name, dest, strerror(errno));
        goto done;
    }

    if (read_write(srcfd, destfd)) {
        ErrorAbort(state, "%s: failed to write to: %s",
                name, dest);
        goto done;
    }

    result = 0;

done:
    if (srcfd >= 0)
        close(srcfd);
    if (destfd >= 0 && close(destfd) < 0) {
        ErrorAbort(state, "%s: failed to close destination device: %s",
                name, strerror(errno));
        result = -1;
    }
    free(src);
    free(dest);
    return (result ? NULL : StringValue(strdup("")));
}


static struct gpt_entry *find_android_partition(struct gpt *gpt, const char *name)
{
    uint32_t i;
    struct gpt_entry *e;
    int ret;

    partition_for_each(gpt, i, e) {
        char *pname = gpt_entry_get_name(e);
        if (!pname)
            return NULL;

        /* Skip over the 'install id' */
        ret = strcmp(pname + 16, name);
        free(pname);
        if (!ret)
            return e;
    }
    return NULL;
}

#define TMP_NODE "/dev/block/__esp_disk__"

static int make_disk_node(char *ptn)
{
    int mj, mn;
    struct stat sb;
    dev_t dev;
    int ret, val;

    if (stat(ptn, &sb))
        return -1;

    mj = major(sb.st_rdev);
    mn = minor(sb.st_rdev);

    /* Get the partition index; subtract this from minor */
    ret = sysfs_read_int(&val, "/sys/dev/block/%d:%d/partition", mj, mn);
    if (ret)
        return -1;
    mn -= val;

    /* Corresponds to the entire block device */
    printf("Referencing GPT in block device %d:%d\n", mj, mn);
    dev = makedev(mj, mn);
    if (mknod(TMP_NODE, S_IFBLK | S_IRUSR | S_IWUSR, dev))
        return -1;
    return 0;
}


static char *follow_links(char *dev)
{
    char *dest;
    ssize_t ret;
    char buf[PATH_MAX];

    ret = readlink(dev, buf, sizeof(buf) - 1);
    if (ret < 0)
        return dev;
    buf[ret] = '\0';

    dest = strdup(buf);
    printf("%s --> %s\n", dev, dest);
    free(dev);
    return dest;
}


static void swap64bit(uint64_t *a, uint64_t *b)
{
    uint64_t tmp;

    tmp = *a;
    *a = *b;
    *b = tmp;
}


static Value *SwapEntriesFn(const char *name, State *state,
        int argc __attribute__((unused)), Expr *argv[])
{
    char *dev = NULL;
    char *part1 = NULL;
    char *part2 = NULL;

    struct gpt_entry *e1, *e2;
    struct gpt *gpt = NULL;
    Value *ret = NULL;

    if (ReadArgs(state, argv, 3, &dev, &part1, &part2))
        return NULL;

    if (strlen(dev) == 0 || strlen(part1) == 0 || strlen(part2) == 0) {
        ErrorAbort(state, "%s: Missing required argument", name);
        goto done;
    }

    /* If the device node is a symlink, follow it to the 'real'
     * device node and then get the node for the entire disk */
    dev = follow_links(dev);

    if (make_disk_node(dev)) {
        ErrorAbort(state, "%s: Unable to get disk node for partition %s",
                name, dev);
        goto done;
    }

    gpt = gpt_init(TMP_NODE);
    if (!gpt) {
        ErrorAbort(state, "%s: Couldn't init GPT structure", name);
        goto done;
    }

    if (gpt_read(gpt)) {
        ErrorAbort(state, "%s: Failed to read GPT", name);
        goto done;
    }

    e1 = find_android_partition(gpt, part1);
    if (!e1) {
        ErrorAbort(state, "%s: unable to find partition '%s'", name, part1);
        goto done;
    }

    e2 = find_android_partition(gpt, part2);
    if (!e2) {
        ErrorAbort(state, "%s: unable to find partition '%s'", name, part1);
        goto done;
    }

    swap64bit(&e1->first_lba, &e2->first_lba);
    swap64bit(&e1->last_lba, &e2->last_lba);

    if (gpt_write(gpt))
        ErrorAbort(state, "%s: failed to write GPT", name);

    ret = StringValue(strdup(""));
done:
    if (gpt)
        gpt_close(gpt);
    unlink(TMP_NODE);
    free(dev);
    free(part1);
    free(part2);

    return ret;
}


/* Similar functionality in init, but /system isn't available and up-to-date
 * until now. */
static char *dmi_detect_machine(void)
{
    char dmi[256], buf[256], *hash, *tag, *name, *toksav, allmatched;
    char dmi_detect[PROPERTY_VALUE_MAX];
    FILE *dmif, *cfg;
    char *ret = NULL;

    /* Skip if disabled */
    property_get("ro.boot.dmi_detect", dmi_detect, "1");
    if (!strcmp(dmi_detect, "0")) {
        printf("DMI machine detection disabled\n");
        return NULL;
    }

    /* Fail silently (no error) on devices without DMI */
    dmif = fopen("/sys/devices/virtual/dmi/id/modalias", "r");
    if (!dmif || !fgets(dmi, sizeof(dmi), dmif)) {
        printf("Couldn't open DMI modalias\n");
        return NULL;
    }
    fclose(dmif);

    /* ...or if the system filesystem lacks configuration */
    if (!(cfg = fopen("/system/etc/dmi-machine.conf", "r"))) {
        printf("DMI machine configuration not present\n");
        return NULL;
    }

    while (fgets(buf, sizeof(buf), cfg)) {
        /* snip comments */
        if ((hash = strchr(buf, '#')))
            *hash = 0;

        /* parse line: cfg name, then a list of tags to test.  If they
         * all match then load the config file and return (note that
         * "no tags" means "everything matched" and can be used to
         * load a default if needed, though that is probably best done
         * with build.props) */
        allmatched = 1;
        if ((name = strtok_r(buf, " \t\v\r\n", &toksav))) {
            while ((tag = strtok_r(NULL, " \t\v\r\n", &toksav)))
                if (!strstr(dmi, tag))
                    allmatched = 0;

            if (allmatched) {
                ret = strdup(name);
                break;
            }
        }
    }

    fclose(cfg);
    return ret;
}


static int LoadCapsuleFn(const char* cmd)
{
    static const char *capsule_load_node = CAP_LOADING;
    int fd = -1;
    int ret = -1;
    ssize_t len;

    if (!cmd || !strlen(cmd))
        goto load_done;

    len = strlen(cmd);

    fd = open(capsule_load_node, O_WRONLY);

    if (fd < 0) {
        printf("%s: Unable to open %s for writing: %s\n", __FUNCTION__,
                capsule_load_node, strerror(errno));
        goto load_done;
    }

    if (robust_write(fd, cmd, len) != len) {
        printf("%s: unable to write '%s' to '%s'\n", __FUNCTION__,
                cmd, capsule_load_node);
    } else
        ret = 0;

load_done:

    if (fd >= 0) {
        if (close(fd)) {
            printf("%s: couldn't close %s: %s\n", __FUNCTION__,
                    capsule_load_node, strerror(errno));
            ret = -1;
        }
    }

    return ret;
}


static int push_capsule(const char *filename)
{
    static const char *capsule_node = CAP_DATA;
    int srcfd = -1;
    int destfd = -1;
    int ret;

    /* Enable capsule write interface */
    if (LoadCapsuleFn("1")) {
        printf("%s: couldn't enable cpasule loading\n", __FUNCTION__);
        return -1;
    }

    /* Open write interface */
    destfd = open(capsule_node, O_WRONLY);
    if (destfd < 0) {
        printf("%s: Unable to open %s for writing: %s\n",
                __FUNCTION__, capsule_node, strerror(errno));
        goto abort;
    }

    srcfd = open(filename, O_RDONLY);
    if (srcfd < 0) {
        printf("%s: Unable to open %s for reading: %s\n",
                __FUNCTION__, filename, strerror(errno));
        goto abort;
    }

    if (read_write(srcfd, destfd)) {
        printf("%s: couldn't push %s capsule data\n", __FUNCTION__,
                filename);
        goto abort;
    }

    /* Close all fds; blow up if there is a problem closing the write end */
    close(srcfd);
    srcfd = -1;
    ret = close(destfd);
    destfd = -1;
    if (ret) {
        printf("%s: close %s: %s\n", __FUNCTION__, capsule_node,
                strerror(errno));
        goto abort;
    }

    /* All done, close the write interface */
    if (LoadCapsuleFn("0")) {
        printf("%s: Failed to turn off loading\n", __FUNCTION__);
        goto abort;
    }

    return 0;
abort:
    if (LoadCapsuleFn("-1")) {
        printf("Unable to abort capsule loading\n");
    }

    /* At this point we don't care if it fails */
    if (srcfd >= 0)
        close(srcfd);
    if (destfd >= 0)
        close(destfd);
    return -1;
}


static Value *UpdateCapsulesFn(const char* name, State* state, int argc, Expr* argv[])
{
    char *basedir;
    char *detected_machine;
    char cap_base_path[PATH_MAX];
    struct stat sb;
    DIR *dir = NULL;
    struct dirent *dp;
    regex_t capreg;

    /* 1 argument: base directory for capsule files.
     * policy: apply *.cap under <base>/<detected_machine>/
     * If machine isn't detected, just look for .cap files in
     * the base dir. We do not dive into any subdirectories */
    if (argc != 1) {
        ErrorAbort(state, "%s: expected 1 argument", name);
        goto done;
    }

    if (ReadArgs(state, argv, 1, &basedir))
        return NULL;

    if (strlen(basedir) == 0) {
        ErrorAbort(state, "%s: Missing required argument", name);
        goto done;
    }

    detected_machine = dmi_detect_machine();
    if (detected_machine) {
        printf("Detected %s machine type\n", detected_machine);
        snprintf(cap_base_path, sizeof(cap_base_path), "%s/%s/", basedir, detected_machine);
        free(detected_machine);
    } else {
        printf("Machine type not specified\n");
        snprintf(cap_base_path, sizeof(cap_base_path), "%s/", basedir);
    }
    if (stat(cap_base_path, &sb) || !S_ISDIR(sb.st_mode)) {
        printf("Capsule update directory %s doesn't exist.", cap_base_path);
        goto done; /* Not fatal, just nothing to do */
    }

    dir = opendir(cap_base_path);
    if (!dir) {
        ErrorAbort(state, "%s: couldn't examine capsule directory %s: %s",
                name, cap_base_path, strerror(errno));
        goto done;
    }

    if (regcomp(&capreg, ".*[.]cap$", REG_EXTENDED | REG_NOSUB)) {
        ErrorAbort(state, "%s: regcomp: %s", name, strerror(errno));
        goto done;
    }

    while ( (dp = readdir(dir)) ) {
        name = dp->d_name;
        char capfile[PATH_MAX];

        if (regexec(&capreg, name, 0, NULL, 0))
            continue;

        snprintf(capfile, sizeof(capfile), "%s/%s", cap_base_path, name);
        printf("Sending %s to the kernel\n", capfile);
        if (push_capsule(capfile)) {
            ErrorAbort(state, "%s: Failed to push capsule file %s", name, capfile);
            goto done;
        }
    }

done:
    if (dir)
        closedir(dir);
    return StringValue(strdup(""));
}

void Register_libbigcore_updater(void)
{
    RegisterFunction("swap_entries", SwapEntriesFn);
    RegisterFunction("copy_partition", CopyPartFn);
    RegisterFunction("update_capsules", UpdateCapsulesFn);

}

