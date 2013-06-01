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

#include <edify/expr.h>
#include <gpt/gpt.h>


#define CHUNK 1024*1024


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
static ssize_t read_write(State *state, int srcfd, int destfd) {
    char *buf = NULL;
    ssize_t to_write;
    ssize_t written;
    ssize_t ret = -1;

    /* We need state to print messages... */
    if (!state)
        goto rw_done;

    if (srcfd < 0 || destfd < 0) {
        ErrorAbort(state, "%s: Invalid fd(s)", __FUNCTION__);
        goto rw_done;
    }

    buf = malloc(CHUNK);
    if (!buf) {
        ErrorAbort(state, "%s: memory allocation error", __FUNCTION__);
        goto rw_done;
    }

    ret = 0;

    while (1) {

        to_write = robust_read(srcfd, buf, CHUNK);
        if (to_write < 0) {
            ErrorAbort(state, "%s: failed to read source data: %s",
                    __FUNCTION__, strerror(errno));
            ret = -1;
            goto rw_done;
        }
        if (!to_write)
            break;

        written = robust_write(destfd, buf, to_write);
        if (written < 0) {
            ErrorAbort(state, "%s: failed to write data: %s", __FUNCTION__,
                    strerror(errno));
            ret = -1;
            goto rw_done;
        }

        if (!written)
            break;

        ret += written;
    }

rw_done:
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

    if (read_write(state, srcfd, destfd) < 0) {
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

static int LoadCapsuleFn(State* state, const char* cmd)
{
    const char *capsule_load_node = "/sys/firmware/efi/capsule/loading";
    int fd = -1;
    int ret = -1;
    ssize_t len;

    if (!cmd || !strlen(cmd))
        goto load_done;

    len = strlen(cmd) + 1;

    fd = open(capsule_load_node, O_WRONLY);

    if (fd < 0) {
        ErrorAbort(state, "%s: Unable to open %s for writing: %s", __FUNCTION__,
                capsule_load_node, strerror(errno));
        goto load_done;
    }

    if (robust_write(fd, cmd, len) != len) {
        ErrorAbort(state, "%s: unable to write '%s' to '%s'", __FUNCTION__,
                cmd, capsule_load_node);
        ret = -1;
    } else
        ret = 0;

load_done:

    if (fd >= 0)
        close(fd);

    return ret;
}

static Value *UpdateCapsulesFn(const char* name, State* state, int argc, Expr* argv[])
{
    int result = -1;
    char **capsule_paths = NULL;
    const char *capsule_node = "/sys/firmware/efi/capsule/data";
    int count;
    int destfd = -1;
    int valid_capsule_num = 0;
    struct Capsule *capsule_list = NULL;

    if (argc <= 0) {
        ErrorAbort(state, "%s: No enough arguments", name);
        goto capsule_done;
    }

    capsule_paths = ReadVarArgs(state, argc, argv);
    if (!capsule_paths) {
        ErrorAbort(state, "%s: Failed to parse arguments", name);
        goto capsule_done;
    }

    capsule_list = calloc(argc, sizeof(*capsule_list));

    if (!capsule_list) {
        ErrorAbort(state, "%s: No enough mem for capsule list", name);
        goto capsule_done;
    }

    /* initialize the list of required capsule files */
    for (count = 0; count < argc; count++) {
        struct Capsule *cap = &capsule_list[count];

        cap->path = capsule_paths[count];
        if (stat(cap->path, &cap->f_stat)) {
            if (errno == ENOENT) {
                cap->existence = 0;
                continue;
            }
            else {
                ErrorAbort(state, "%s: Unable to get status of %s: %s", name, cap->path,
                        strerror(errno));
                goto capsule_done;
            }
        }

        cap->existence = 1;

        valid_capsule_num++;
    }

    if (!valid_capsule_num) {
        /* if none of required capsule exists, report success */
        result = 0;
        goto capsule_done;
    }

    /* Open write interface */
    destfd = open(capsule_node, O_WRONLY);
    if (destfd < 0) {
        ErrorAbort(state, "%s: Unable to open %s for writing: %s",
                __FUNCTION__, capsule_node, strerror(errno));
        goto capsule_done;
    }

    /* Enable capsule write interface */
    if (LoadCapsuleFn(state, "1")) {
        ErrorAbort(state, "%s: Failed to parse arguments", name);
        goto capsule_done;
    }

    /* start writing capsule files to kernel one by one */
    for (count = 0; count < argc; count++) {
        struct Capsule *cap = &capsule_list[count];
        int srcfd = -1;
        ssize_t written;

        if (!cap->existence)
            continue;

        srcfd = open(cap->path, O_RDONLY);

        if (srcfd < 0) {
            ErrorAbort(state, "%s: Unable to open %s for reading: %s",
                    __FUNCTION__, cap->path, strerror(errno));
            goto capsule_done;
        }

        written = read_write(state, srcfd, destfd);

        if (close(srcfd) < 0) {
            ErrorAbort(state,
                    "%s: Failed to close '%s': after writing",
                    name, cap->path);

            goto capsule_done;
        }

        if (written != cap->f_stat.st_size) {
            ErrorAbort(state,
                    "%s: Failed to write '%s': written %ld, expected %lld",
                    name, cap->path, written, cap->f_stat.st_size);

            goto capsule_done;
        }
    }

    if (LoadCapsuleFn(state, "0")) {
        ErrorAbort(state, "%s: Failed to turn off loading", name);
        goto capsule_done;
    }

    result = 0;

capsule_done:

    if (capsule_paths) {
        int i;
        for (i = 0; i < argc; i++)
            free(capsule_paths[i]);
        free(capsule_paths);
    }

    if (destfd >= 0 && close(destfd) < 0) {
        ErrorAbort(state, "%s: Unable to open %s for writing: %s",
                __FUNCTION__, capsule_node, strerror(errno));
        result = -1;
    }

    free(capsule_list);

    return (result ? NULL : StringValue(strdup("")));
}

void Register_libbigcore_updater(void)
{
    RegisterFunction("swap_entries", SwapEntriesFn);
    RegisterFunction("copy_partition", CopyPartFn);
    RegisterFunction("update_capsules", UpdateCapsulesFn);

}

