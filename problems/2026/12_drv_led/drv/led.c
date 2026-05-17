#include <linux/fs.h> 
#include <linux/miscdevice.h> 
#include <linux/module.h> 
#include <linux/slab.h> 
#include <linux/uaccess.h> 
#include <linux/vmalloc.h> 
#include <asm/pgtable.h> 
#include <linux/io.h> 
#include <linux/mm.h> 
#include <linux/module.h> 
#include <linux/of.h> 
#include <linux/platform_device.h>

static void __iomem *regs;

/* write one byte to LED register */
static ssize_t led_write(struct file *f, const char __user *buf,
                         size_t len, loff_t *off)
{
    char v;

    if (!len)
        return -EINVAL;

    if (copy_from_user(&v, buf, 1))
        return -EFAULT;

    iowrite32(v, regs);

    pr_info("led: write 0x%x -> %p\n", v, regs);

    return 1;
}

static const struct file_operations ops = {
    .owner = THIS_MODULE,
    .write = led_write,
};

static struct miscdevice dev = {
    .minor = MISC_DYNAMIC_MINOR,
    .name  = "led",
    .fops  = &ops,
    .mode  = 0666,
};

static int led_probe(struct platform_device *pdev)
{
    int ret;

    regs = devm_platform_ioremap_resource(pdev, 0);
    if (IS_ERR(regs))
        return PTR_ERR(regs);

    pr_info("led: probe, base=%p\n", regs);

    dev.parent = &pdev->dev;

    ret = misc_register(&dev);
    if (ret)
        pr_err("led: misc_register failed (%d)\n", ret);
    else
        pr_info("led: device registered\n");

    return ret;
}

static const struct of_device_id led_ids[] = {
    { .compatible = "drec-fpga-intro,led-dev" },
    { }
};
MODULE_DEVICE_TABLE(of, led_ids);

static struct platform_driver led_driver = {
    .probe = led_probe,
    .driver = {
        .name = "led",
        .of_match_table = led_ids,
    },
};

module_platform_driver(led_driver);

MODULE_LICENSE("GPL");
