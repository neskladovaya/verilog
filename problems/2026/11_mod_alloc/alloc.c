#include <linux/module.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/slab.h>
#include <linux/vmalloc.h>

static void *kptr;
static void *vptr;

static long dev_ioctl(struct file *f, unsigned int cmd, unsigned long arg)
{
    unsigned long size = arg;

    switch (cmd) {

        // kmalloc alloc
        case _IOW('M', 1, unsigned):
            if (kptr) {
                kfree(kptr);
                kptr = NULL;
            }

            kptr = kmalloc(size, GFP_KERNEL);
            if (!kptr) {
                pr_err("kmalloc fail (%lu)\n", size);
                return -ENOMEM;
            }

            pr_info("kmalloc ok (%lu)\n", size);
            break;

        // vmalloc alloc
        case _IOW('M', 2, unsigned):
            if (vptr) {
                vfree(vptr);
                vptr = NULL;
            }

            vptr = vmalloc(size);
            if (!vptr) {
                pr_err("vmalloc fail (%lu)\n", size);
                return -ENOMEM;
            }

            pr_info("vmalloc ok (%lu)\n", size);
            break;

        // kmalloc free
        case _IO('M', 3):
            if (kptr) {
                kfree(kptr);
                kptr = NULL;
                pr_info("kmalloc freed\n");
            }
            break;

        // vmalloc free
        case _IO('M', 4):
            if (vptr) {
                vfree(vptr);
                vptr = NULL;
                pr_info("vmalloc freed\n");
            }
            break;

        default:
            return -ENOTTY;
    }

    return 0;
}

static const struct file_operations fops = {
    .owner          = THIS_MODULE,
    .unlocked_ioctl = dev_ioctl,
};

static struct miscdevice dev = {
    .minor = MISC_DYNAMIC_MINOR,
    .name  = "alloc",
    .fops  = &fops,
    .mode  = 0666,
};

static int __init mod_init(void)
{
    int ret = misc_register(&dev);

    if (ret) {
        pr_err("register failed\n");
        return ret;
    }

    pr_info("device ready\n");
    return 0;
}

static void __exit mod_exit(void)
{
    if (kptr)
        kfree(kptr);

    if (vptr)
        vfree(vptr);

    misc_deregister(&dev);
    pr_info("device removed\n");
}

module_init(mod_init);
module_exit(mod_exit);

MODULE_LICENSE("GPL");
