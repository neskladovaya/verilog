#include <linux/completion.h>
#include <linux/dma-mapping.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>
#include <linux/uaccess.h>

#define SA_START   0x0
#define SA_IS_B    0x4
#define SA_AB_ADDR 0x8
#define SA_C_ADDR  0xC

static void __iomem *sa_regs;
static struct device *sa_dev;

static uint16_t *buf_ab;
static uint16_t *buf_c;

static dma_addr_t phys_ab;
static dma_addr_t phys_c;

static DECLARE_COMPLETION(sa_done);

static ssize_t sa_write(struct file *filp,
                        const char __user *buf,
                        size_t count,
                        loff_t *ppos)
{
    uint32_t addrs[2];

    if (count < sizeof(addrs))
        return -EINVAL;

    if (copy_from_user(addrs, buf, sizeof(addrs)))
        return -EFAULT;

    if (copy_from_user(buf_ab, (void __user *)addrs[0], PAGE_SIZE))
        return -EFAULT;

    reinit_completion(&sa_done);

    iowrite32(phys_ab, sa_regs + SA_AB_ADDR);
    iowrite32(phys_c,  sa_regs + SA_C_ADDR);
    iowrite32(1,       sa_regs + SA_IS_B);
    iowrite32(1,       sa_regs + SA_START);

    if (!wait_for_completion_timeout(&sa_done, msecs_to_jiffies(1000)))
        return -ETIMEDOUT;

    if (copy_from_user(buf_ab, (void __user *)addrs[0], PAGE_SIZE))
        return -EFAULT;

    reinit_completion(&sa_done);

    iowrite32(phys_ab, sa_regs + SA_AB_ADDR);
    iowrite32(phys_c,  sa_regs + SA_C_ADDR);
    iowrite32(0,       sa_regs + SA_IS_B);
    iowrite32(1,       sa_regs + SA_START);

    if (!wait_for_completion_timeout(&sa_done, msecs_to_jiffies(1000)))
        return -ETIMEDOUT;

    if (copy_to_user((void __user *)addrs[1], buf_c, PAGE_SIZE))
        return -EFAULT;

    return sizeof(addrs);
}

static const struct file_operations sa_fops = {
    .owner = THIS_MODULE,
    .write = sa_write,
};

static struct miscdevice sa_misc = {
    .minor = MISC_DYNAMIC_MINOR,
    .name  = "sa-dev",
    .fops  = &sa_fops,
};

static irqreturn_t sa_irq_handler(int irq, void *data)
{
    return IRQ_WAKE_THREAD;
}

static irqreturn_t sa_irq_thread(int irq, void *data)
{
    complete(&sa_done);
    return IRQ_HANDLED;
}

static int sa_probe(struct platform_device *pdev)
{
    struct device *dev = &pdev->dev;
    int ret, irq;

    sa_dev = dev;

    sa_regs = devm_platform_ioremap_resource(pdev, 0);
    if (IS_ERR(sa_regs))
        return PTR_ERR(sa_regs);

    ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(32));
    if (ret)
        return ret;

    buf_ab = dmam_alloc_coherent(dev, PAGE_SIZE, &phys_ab, GFP_KERNEL);
    buf_c  = dmam_alloc_coherent(dev, PAGE_SIZE, &phys_c,  GFP_KERNEL);

    if (!buf_ab || !buf_c)
        return -ENOMEM;

    irq = platform_get_irq(pdev, 0);
    if (irq < 0)
        return irq;

    ret = request_threaded_irq(irq,
                               sa_irq_handler,
                               sa_irq_thread,
                               IRQF_ONESHOT,
                               "sa-irq",
                               dev);
    if (ret)
        return ret;

    ret = misc_register(&sa_misc);
    if (ret)
        return ret;

    return 0;
}

static const struct of_device_id sa_match[] = {
    { .compatible = "drec-fpga-intro,sa-dev" },
    {}
};
MODULE_DEVICE_TABLE(of, sa_match);

static struct platform_driver sa_driver = {
    .probe = sa_probe,
    .driver = {
        .name = KBUILD_MODNAME,
        .of_match_table = sa_match,
    },
};

module_platform_driver(sa_driver);

MODULE_LICENSE("GPL");